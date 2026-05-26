import {
  BadGatewayException,
  HttpException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { randomUUID } from 'crypto';
import {
  ListQuery,
  ResendAttachment,
  ResendEmailBody,
  ResendListPage,
  ResendReceivedSummary,
  ResendSendInput,
  ResendSendResult,
  ResendSentSummary,
} from './resend.types';

const RESEND_BASE = 'https://api.resend.com';

@Injectable()
export class ResendClient {
  private readonly logger = new Logger(ResendClient.name);
  private readonly apiKey: string;

  constructor(cfg: ConfigService) {
    const key = cfg.get<string>('RESEND_API_KEY');
    if (!key) {
      this.logger.warn('RESEND_API_KEY not set — email endpoints will fail with 502');
    }
    this.apiKey = key ?? '';
  }

  private headers(extra: Record<string, string> = {}): Record<string, string> {
    return {
      Authorization: `Bearer ${this.apiKey}`,
      'Content-Type': 'application/json',
      ...extra,
    };
  }

  private async request<T>(
    method: 'GET' | 'POST',
    path: string,
    init: { body?: unknown; headers?: Record<string, string>; raw?: boolean } = {},
  ): Promise<T> {
    if (!this.apiKey) {
      throw new BadGatewayException('RESEND_API_KEY not configured');
    }
    const url = `${RESEND_BASE}${path}`;
    const res = await fetch(url, {
      method,
      headers: this.headers(init.headers),
      body: init.body !== undefined ? JSON.stringify(init.body) : undefined,
    });

    if (res.status === 404) throw new NotFoundException(`resend: ${path} not found`);
    if (!res.ok) {
      const text = await res.text().catch(() => '');
      this.logger.error(`Resend ${method} ${path} ${res.status}: ${text}`);
      throw new HttpException(
        { upstream: 'resend', status: res.status, body: safeJson(text) },
        res.status >= 500 ? 502 : res.status,
      );
    }

    if (init.raw) return (await res.arrayBuffer()) as unknown as T;
    return (await res.json()) as T;
  }

  private buildQuery(q: ListQuery): string {
    const params = new URLSearchParams();
    if (q.limit) params.set('limit', String(q.limit));
    if (q.after) params.set('after', q.after);
    if (q.before) params.set('before', q.before);
    const s = params.toString();
    return s ? `?${s}` : '';
  }

  listSent(q: ListQuery = {}) {
    return this.request<ResendListPage<ResendSentSummary>>(
      'GET',
      `/emails${this.buildQuery(q)}`,
    );
  }

  getSent(id: string) {
    return this.request<ResendEmailBody>('GET', `/emails/${encodeURIComponent(id)}`);
  }

  listReceived(q: ListQuery = {}) {
    return this.request<ResendListPage<ResendReceivedSummary>>(
      'GET',
      `/emails/receiving${this.buildQuery(q)}`,
    );
  }

  getReceived(id: string) {
    return this.request<ResendEmailBody>(
      'GET',
      `/emails/receiving/${encodeURIComponent(id)}`,
    );
  }

  listAttachments(emailId: string) {
    return this.request<ResendListPage<ResendAttachment>>(
      'GET',
      `/emails/${encodeURIComponent(emailId)}/attachments`,
    );
  }

  getAttachment(emailId: string, attachmentId: string) {
    return this.request<ArrayBuffer>(
      'GET',
      `/emails/${encodeURIComponent(emailId)}/attachments/${encodeURIComponent(attachmentId)}`,
      { raw: true },
    );
  }

  send(input: ResendSendInput, idempotencyKey?: string) {
    return this.request<ResendSendResult>('POST', '/emails', {
      body: input,
      headers: { 'Idempotency-Key': idempotencyKey ?? randomUUID() },
    });
  }
}

function safeJson(s: string): unknown {
  try {
    return JSON.parse(s);
  } catch {
    return s;
  }
}
