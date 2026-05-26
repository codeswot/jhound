import {
  Injectable,
  Logger,
  OnApplicationShutdown,
  OnModuleInit,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Client } from 'pg';
import { SyncGateway } from './sync.gateway';
import {
  FollowupEventPayload,
  JobEventPayload,
  OssEventPayload,
  WsEvent,
} from './sync.events';

const CHANNELS = ['jhound_job_event', 'jhound_followup_event', 'jhound_oss_event'] as const;

@Injectable()
export class PgListener implements OnModuleInit, OnApplicationShutdown {
  private readonly logger = new Logger(PgListener.name);
  private client: Client | null = null;
  private reconnectTimer: NodeJS.Timeout | null = null;
  private shuttingDown = false;

  constructor(
    private readonly cfg: ConfigService,
    private readonly gateway: SyncGateway,
  ) {}

  async onModuleInit() {
    await this.connect();
  }

  async onApplicationShutdown() {
    this.shuttingDown = true;
    if (this.reconnectTimer) clearTimeout(this.reconnectTimer);
    if (this.client) await this.client.end().catch(() => undefined);
  }

  private async connect(): Promise<void> {
    if (this.shuttingDown) return;

    const client = new Client({
      host: this.cfg.get<string>('POSTGRES_HOST', 'postgres'),
      port: Number(this.cfg.get('POSTGRES_PORT', 5432)),
      user: this.cfg.get<string>('POSTGRES_USER', 'jhound'),
      password: this.cfg.get<string>('POSTGRES_PASSWORD'),
      database: this.cfg.get<string>('POSTGRES_DB', 'jhound'),
    });

    client.on('notification', (msg) => this.onNotification(msg.channel, msg.payload));
    client.on('error', (err) => this.onClientError(err));
    client.on('end', () => this.scheduleReconnect('connection ended'));

    try {
      await client.connect();
      for (const ch of CHANNELS) await client.query(`LISTEN ${ch}`);
      this.client = client;
      this.logger.log(`Listening on ${CHANNELS.join(', ')}`);
    } catch (err) {
      this.logger.error(`pg connect failed: ${(err as Error).message}`);
      this.scheduleReconnect('connect failed');
    }
  }

  private onClientError(err: Error) {
    this.logger.error(`pg listener error: ${err.message}`);
  }

  private scheduleReconnect(reason: string) {
    if (this.shuttingDown || this.reconnectTimer) return;
    this.logger.warn(`pg listener reconnecting in 3s — ${reason}`);
    this.client = null;
    this.reconnectTimer = setTimeout(() => {
      this.reconnectTimer = null;
      void this.connect();
    }, 3000);
  }

  private onNotification(channel: string, payload?: string) {
    if (!payload) return;
    let parsed: unknown;
    try {
      parsed = JSON.parse(payload);
    } catch (err) {
      this.logger.warn(`bad payload on ${channel}: ${(err as Error).message}`);
      return;
    }

    const event = this.translate(channel, parsed);
    if (event) this.gateway.broadcast(event);
  }

  private translate(channel: string, raw: unknown): WsEvent | null {
    switch (channel) {
      case 'jhound_job_event': {
        const data = raw as JobEventPayload;
        return {
          type: data.op === 'INSERT' ? 'job.created' : 'job.updated',
          data,
        };
      }
      case 'jhound_followup_event':
        return { type: 'followup.sent', data: raw as FollowupEventPayload };
      case 'jhound_oss_event':
        return { type: 'oss.discovered', data: raw as OssEventPayload };
      default:
        return null;
    }
  }
}
