import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { JobApplication } from '../database/entities/job-application.entity';
import { ResendClient } from '../resend/resend.client';
import { ResendEmailBody, ResendReceivedSummary, ResendSentSummary } from '../resend/resend.types';
import { ListJobsDto } from './jobs.dto';

export interface JobMessage {
  id: string;
  direction: 'inbound' | 'outbound';
  from: string | null;
  to: string[] | null;
  subject: string | null;
  preview: string | null;
  createdAt: string;
  lastEvent: string | null;
}

@Injectable()
export class JobsService {
  private readonly logger = new Logger(JobsService.name);
  private msgCache = new Map<string, { ts: number; data: JobMessage[] }>();

  constructor(
    @InjectRepository(JobApplication)
    private readonly repo: Repository<JobApplication>,
    private readonly resend: ResendClient,
  ) {}

  async list(dto: ListJobsDto) {
    const qb = this.repo.createQueryBuilder('j');

    if (dto.status) qb.andWhere('j.status = :status', { status: dto.status });
    if (dto.source) qb.andWhere('j.source_board = :source', { source: dto.source });
    if (dto.tier) qb.andWhere('j.ai_priority_tier = :tier', { tier: dto.tier });
    if (dto.q) {
      qb.andWhere('(LOWER(j.company) LIKE :q OR LOWER(j.job_title) LIKE :q)', {
        q: `%${dto.q.toLowerCase()}%`,
      });
    }

    qb.orderBy(`j.${dto.sort ?? 'applied_at'}`, 'DESC', 'NULLS LAST')
      .limit(dto.limit)
      .offset(dto.offset);

    const [items, total] = await qb.getManyAndCount();
    return { items, total, limit: dto.limit, offset: dto.offset };
  }

  async findOne(id: string) {
    const job = await this.repo.findOne({
      where: { id },
      relations: { followUps: true },
    });
    if (!job) throw new NotFoundException(`job ${id} not found`);
    return job;
  }

  async messages(jobId: string): Promise<JobMessage[]> {
    const cached = this.msgCache.get(jobId);
    if (cached && Date.now() - cached.ts < 60_000) return cached.data;

    const job = await this.findOne(jobId);

    const [sent, received] = await Promise.all([
      this.fetchSent(100),
      this.fetchReceived(100),
    ]);

    const sentForJobId = new Set<string>();
    const matched: JobMessage[] = [];

    for (const s of sent) {
      let full: ResendEmailBody | null = null;
      try {
        full = await this.resend.getSent(s.id);
      } catch {
        continue;
      }
      if (!full) continue;
      const tags = normalizeTagsPair(full.tags);
      if (tags.job_id !== jobId) {
        const subjectMatch =
          job.company &&
          full.subject &&
          full.subject.toLowerCase().includes(job.company.toLowerCase());
        if (!subjectMatch) continue;
      }
      sentForJobId.add(s.id);
      matched.push({
        id: s.id,
        direction: 'outbound',
        from: null,
        to: s.to,
        subject: s.subject,
        preview: truncate(full.html ?? full.text ?? '', 200),
        createdAt: s.created_at,
        lastEvent: s.last_event,
      });
    }

    const seenMsgIds = new Set<string>();
    for (const r of received) {
      let full: ResendEmailBody | null = null;
      try {
        full = await this.resend.getReceived(r.id);
      } catch {
        continue;
      }
      if (!full) continue;

      const messageId = extractHeader(full.headers, 'message-id');
      const inReplyTo = extractHeader(full.headers, 'in-reply-to');
      const references = extractHeader(full.headers, 'references');

      const linked = inReplyTo != null && (
        sentForJobId.size === 0
          ? false
          : [...sentForJobId].some((sid) => {
              const sentMsgId = this.getSentMessageId(sid);
              return (
                inReplyTo.includes(sid) ||
                (sentMsgId && inReplyTo.includes(sentMsgId)) ||
                (references && (references.includes(sid) || (sentMsgId && references.includes(sentMsgId))))
              );
            })
      );

      const emailMatch =
        job.hiringManagerEmail &&
        full.from?.toLowerCase() === job.hiringManagerEmail.toLowerCase();

      if (!linked && !emailMatch) continue;

      const dedupKey = messageId ?? r.id;
      if (seenMsgIds.has(dedupKey)) continue;
      seenMsgIds.add(dedupKey);

      matched.push({
        id: r.id,
        direction: 'inbound',
        from: full.from,
        to: full.to,
        subject: full.subject,
        preview: truncate(full.text ?? full.html ?? '', 200),
        createdAt: full.created_at,
        lastEvent: null,
      });
    }

    matched.sort((a, b) => a.createdAt.localeCompare(b.createdAt));
    this.msgCache.set(jobId, { ts: Date.now(), data: matched });
    return matched;
  }

  private sentMsgIds = new Map<string, string>();

  private getSentMessageId(sentId: string): string | null {
    return this.sentMsgIds.get(sentId) ?? null;
  }

  private async fetchSent(limit: number): Promise<ResendSentSummary[]> {
    try {
      const page = await this.resend.listSent({ limit });
      for (const s of page.data) {
        try {
          const full = await this.resend.getSent(s.id);
          if (full?.headers) {
            const msgId = extractHeader(full.headers, 'message-id');
            if (msgId) this.sentMsgIds.set(s.id, msgId);
          }
        } catch { /* ignore */}
      }
      return page.data;
    } catch (err) {
      this.logger.error(`Fetch sent failed: ${(err as Error).message}`);
      return [];
    }
  }

  private async fetchReceived(limit: number): Promise<ResendReceivedSummary[]> {
    try {
      const page = await this.resend.listReceived({ limit });
      return page.data;
    } catch (err) {
      this.logger.error(`Fetch received failed: ${(err as Error).message}`);
      return [];
    }
  }
}

function normalizeTagsPair(raw: unknown): Record<string, string> {
  if (!raw) return {};
  if (Array.isArray(raw)) {
    const out: Record<string, string> = {};
    for (const t of raw) {
      if (t && typeof t === 'object' && 'name' in t && 'value' in t) {
        out[String(t.name)] = String(t.value);
      }
    }
    return out;
  }
  if (typeof raw === 'object') return raw as Record<string, string>;
  return {};
}

function extractHeader(
  headers: Record<string, string> | null | undefined,
  key: string,
): string | null {
  if (!headers) return null;
  const lowerKey = key.toLowerCase();
  for (const [k, v] of Object.entries(headers)) {
    if (k.toLowerCase() === lowerKey) return v;
  }
  return null;
}

function truncate(s: string, n: number): string {
  const clean = s.replace(/<[^>]*>/g, '').replace(/\s+/g, ' ').trim();
  return clean.length <= n ? clean : clean.slice(0, n) + '…';
}
