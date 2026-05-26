import { BadRequestException, Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { ResendClient } from '../resend/resend.client';
import { ResendSendInput } from '../resend/resend.types';
import { ReplyEmailDto, SendEmailDto } from './emails.dto';

@Injectable()
export class EmailsService {
  private readonly logger = new Logger(EmailsService.name);
  private readonly defaultFrom: string;

  constructor(
    private readonly resend: ResendClient,
    cfg: ConfigService,
  ) {
    this.defaultFrom =
      cfg.get<string>('RESEND_FROM') ??
      cfg.get<string>('USER_EMAIL') ??
      'mubarak@codeswot.me';
  }

  listInbox(limit?: number, after?: string, before?: string) {
    return this.resend.listReceived({ limit, after, before });
  }

  getInbox(id: string) {
    return this.resend.getReceived(id);
  }

  listAttachments(emailId: string) {
    return this.resend.listAttachments(emailId);
  }

  getAttachment(emailId: string, attachmentId: string) {
    return this.resend.getAttachment(emailId, attachmentId);
  }

  listSent(limit?: number, after?: string, before?: string) {
    return this.resend.listSent({ limit, after, before });
  }

  getSent(id: string) {
    return this.resend.getSent(id);
  }

  async send(dto: SendEmailDto) {
    if (!dto.html && !dto.text) {
      throw new BadRequestException('html or text is required');
    }
    const input = this.buildSendInput(dto);
    const result = await this.resend.send(input, dto.idempotency_key);
    this.logger.log(`Sent ${result.id} kind=${dto.kind ?? 'manual'} to=${dto.to.join(',')}`);
    return { id: result.id };
  }

  async reply(inboundResendId: string, dto: ReplyEmailDto) {
    const original = await this.resend.getReceived(inboundResendId);
    if (!original.from) {
      throw new BadRequestException(`inbound email ${inboundResendId} missing from address`);
    }
    if (!dto.html && !dto.text) {
      throw new BadRequestException('html or text is required');
    }

    const messageId = original.headers?.['message-id'] ?? original.headers?.['Message-ID'] ?? null;
    const refs = original.headers?.['references'] ?? original.headers?.['References'] ?? '';
    const newRefs = [refs, messageId].filter(Boolean).join(' ').trim();

    const subject = dto.subject ?? prefixReply(original.subject);
    const headers: Record<string, string> = {};
    if (messageId) headers['In-Reply-To'] = messageId;
    if (newRefs) headers['References'] = newRefs;

    const input = this.buildSendInput({
      to: [original.from],
      subject,
      html: dto.html,
      text: dto.text,
      cc: dto.cc,
      bcc: dto.bcc,
      attachments: dto.attachments,
      job_id: dto.job_id,
      kind: 'reply',
      headers,
      from: dto.from,
    } as SendEmailDto);

    const result = await this.resend.send(input, dto.idempotency_key);
    this.logger.log(`Replied ${result.id} to=${original.from} inbound=${inboundResendId}`);
    return { id: result.id, in_reply_to: messageId };
  }

  private buildSendInput(dto: SendEmailDto): ResendSendInput {
    const tags: Array<{ name: string; value: string }> = [];
    tags.push({ name: 'source', value: 'jhound-api' });
    if (dto.kind) tags.push({ name: 'kind', value: dto.kind });
    if (dto.job_id) tags.push({ name: 'job_id', value: dto.job_id });
    if (dto.extra_tags) {
      for (const [name, value] of Object.entries(dto.extra_tags)) {
        tags.push({ name, value });
      }
    }

    return {
      from: dto.from ?? this.defaultFrom,
      to: dto.to,
      subject: dto.subject,
      html: dto.html,
      text: dto.text,
      cc: dto.cc,
      bcc: dto.bcc,
      reply_to: dto.reply_to,
      scheduled_at: dto.scheduled_at,
      attachments: dto.attachments,
      headers: dto.headers,
      tags,
    };
  }
}

function prefixReply(subject: string | null): string {
  if (!subject) return 'Re:';
  return /^re:/i.test(subject) ? subject : `Re: ${subject}`;
}
