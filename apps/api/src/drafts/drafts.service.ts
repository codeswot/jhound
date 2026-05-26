import { BadRequestException, ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { IsNull, Repository } from 'typeorm';
import { Draft } from '../database/entities/draft.entity';
import { EmailsService } from '../emails/emails.service';
import { ListDraftsDto, PatchDraftDto, UpsertDraftDto } from './drafts.dto';

@Injectable()
export class DraftsService {
  constructor(
    @InjectRepository(Draft) private readonly repo: Repository<Draft>,
    private readonly emails: EmailsService,
  ) {}

  async list(dto: ListDraftsDto) {
    const qb = this.repo
      .createQueryBuilder('d')
      .orderBy('d.updated_at', 'DESC')
      .limit(dto.limit)
      .offset(dto.offset);
    if (dto.unsent_only) qb.andWhere('d.sent_at IS NULL');
    const [items, total] = await qb.getManyAndCount();
    return { items, total, limit: dto.limit, offset: dto.offset };
  }

  async findOne(id: string) {
    const d = await this.repo.findOne({ where: { id } });
    if (!d) throw new NotFoundException(`draft ${id} not found`);
    return d;
  }

  create(dto: UpsertDraftDto) {
    const draft = this.repo.create({
      jobId: dto.job_id ?? null,
      replyToResendId: dto.reply_to_resend_id ?? null,
      toAddresses: dto.to_addresses,
      ccAddresses: dto.cc_addresses ?? null,
      bccAddresses: dto.bcc_addresses ?? null,
      replyTo: dto.reply_to ?? null,
      subject: dto.subject ?? null,
      bodyHtml: dto.body_html ?? null,
      bodyText: dto.body_text ?? null,
      tags: dto.tags ?? null,
      headers: dto.headers ?? null,
    });
    return this.repo.save(draft);
  }

  async patch(id: string, dto: PatchDraftDto) {
    const draft = await this.findOne(id);
    if (draft.sentAt) throw new ConflictException(`draft ${id} already sent`);

    if (dto.job_id !== undefined) draft.jobId = dto.job_id ?? null;
    if (dto.to_addresses !== undefined) draft.toAddresses = dto.to_addresses;
    if (dto.cc_addresses !== undefined) draft.ccAddresses = dto.cc_addresses ?? null;
    if (dto.bcc_addresses !== undefined) draft.bccAddresses = dto.bcc_addresses ?? null;
    if (dto.reply_to !== undefined) draft.replyTo = dto.reply_to ?? null;
    if (dto.subject !== undefined) draft.subject = dto.subject ?? null;
    if (dto.body_html !== undefined) draft.bodyHtml = dto.body_html ?? null;
    if (dto.body_text !== undefined) draft.bodyText = dto.body_text ?? null;
    if (dto.tags !== undefined) draft.tags = dto.tags ?? null;
    if (dto.headers !== undefined) draft.headers = dto.headers ?? null;

    return this.repo.save(draft);
  }

  async remove(id: string) {
    const draft = await this.findOne(id);
    if (draft.sentAt) throw new ConflictException(`draft ${id} already sent — cannot delete`);
    await this.repo.delete({ id, sentAt: IsNull() });
    return { deleted: true };
  }

  async send(id: string, idempotencyKey?: string) {
    const draft = await this.findOne(id);
    if (draft.sentAt) throw new ConflictException(`draft ${id} already sent`);
    if (!draft.toAddresses?.length) throw new BadRequestException('draft has no recipients');
    if (!draft.subject) throw new BadRequestException('draft has no subject');
    if (!draft.bodyHtml && !draft.bodyText) {
      throw new BadRequestException('draft has no body (html or text)');
    }

    const result = draft.replyToResendId
      ? await this.emails.reply(draft.replyToResendId, {
          html: draft.bodyHtml ?? undefined,
          text: draft.bodyText ?? undefined,
          subject: draft.subject ?? undefined,
          cc: draft.ccAddresses ?? undefined,
          bcc: draft.bccAddresses ?? undefined,
          job_id: draft.jobId ?? undefined,
          idempotency_key: idempotencyKey,
        })
      : await this.emails.send({
          to: draft.toAddresses,
          subject: draft.subject,
          html: draft.bodyHtml ?? undefined,
          text: draft.bodyText ?? undefined,
          cc: draft.ccAddresses ?? undefined,
          bcc: draft.bccAddresses ?? undefined,
          reply_to: draft.replyTo ? [draft.replyTo] : undefined,
          job_id: draft.jobId ?? undefined,
          kind: 'manual',
          extra_tags: draft.tags ?? undefined,
          headers: draft.headers ?? undefined,
          idempotency_key: idempotencyKey,
        });

    draft.sentResendId = result.id;
    draft.sentAt = new Date();
    await this.repo.save(draft);

    return { id: draft.id, resend_id: result.id, sent_at: draft.sentAt };
  }
}
