import {
  BadRequestException,
  Controller,
  HttpCode,
  Logger,
  Post,
  RawBodyRequest,
  Req,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectRepository } from '@nestjs/typeorm';
import { Webhook } from 'svix';
import { QueryFailedError, Repository } from 'typeorm';
import { Request } from 'express';
import { Public } from '../auth/public.decorator';
import { WebhookEvent } from '../database/entities/webhook-event.entity';
import { SyncGateway } from '../sync/sync.gateway';
import { WsEvent } from '../sync/sync.events';

const FORWARDED_EVENTS: ReadonlySet<WsEvent['type']> = new Set([
  'email.sent',
  'email.delivered',
  'email.delivery_delayed',
  'email.bounced',
  'email.opened',
  'email.clicked',
  'email.complained',
  'email.failed',
  'email.received',
  'email.scheduled',
  'email.suppressed',
]);

@Controller('webhooks/resend')
export class ResendWebhookController {
  private readonly logger = new Logger(ResendWebhookController.name);
  private readonly verifier: Webhook | null;
  private readonly insecure: boolean;

  constructor(
    cfg: ConfigService,
    private readonly gateway: SyncGateway,
    @InjectRepository(WebhookEvent)
    private readonly events: Repository<WebhookEvent>,
  ) {
    const secret = cfg.get<string>('RESEND_WEBHOOK_SECRET');
    this.verifier = secret ? new Webhook(secret) : null;
    this.insecure = cfg.get<string>('RESEND_WEBHOOK_INSECURE') === 'true';
    if (!this.verifier) {
      this.logger.warn(
        'RESEND_WEBHOOK_SECRET unset. Set RESEND_WEBHOOK_INSECURE=true only for local testing.',
      );
    }
  }

  @Public()
  @Post()
  @HttpCode(200)
  async handle(@Req() req: RawBodyRequest<Request>) {
    const raw = req.rawBody;
    if (!raw) throw new BadRequestException('missing raw body');

    let event: { type?: string; data?: { email_id?: string } & Record<string, unknown> };
    const svixId = req.headers['svix-id'] as string | undefined;

    if (this.verifier) {
      if (!svixId) throw new BadRequestException('missing svix-id');
      const headers = {
        'svix-id': svixId,
        'svix-timestamp': req.headers['svix-timestamp'] as string,
        'svix-signature': req.headers['svix-signature'] as string,
      };
      try {
        event = this.verifier.verify(raw.toString('utf8'), headers) as typeof event;
      } catch (err) {
        this.logger.warn(`Svix verify failed: ${(err as Error).message}`);
        throw new UnauthorizedException('invalid signature');
      }
    } else if (this.insecure) {
      try {
        event = JSON.parse(raw.toString('utf8'));
      } catch {
        throw new BadRequestException('invalid JSON');
      }
    } else {
      throw new UnauthorizedException('webhook secret not configured');
    }

    const externalId = svixId ?? `nosvix:${Buffer.from(raw).subarray(0, 32).toString('hex')}`;
    const type = (event.type ?? 'unknown') as WsEvent['type'];

    try {
      await this.events.insert({
        provider: 'resend',
        externalId,
        eventType: type,
        payload: event.data,
      });
    } catch (err) {
      if (err instanceof QueryFailedError && (err.driverError as { code?: string }).code === '23505') {
        this.logger.log(`Duplicate webhook ${externalId} ignored`);
        return { ok: true, duplicate: true };
      }
      throw err;
    }

    if (!FORWARDED_EVENTS.has(type)) {
      this.logger.log(`Ignoring unsupported event: ${type}`);
      return { ok: true, ignored: true };
    }

    const emailId = event.data?.email_id as string | undefined;
    this.gateway.broadcast({
      type,
      data: { type, email_id: emailId, raw: event.data ?? null },
    } as WsEvent);

    this.logger.log(`Forwarded ${type} email_id=${emailId ?? '?'}`);
    return { ok: true, type };
  }
}
