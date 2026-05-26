import { Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  OnGatewayConnection,
  OnGatewayDisconnect,
  SubscribeMessage,
  WebSocketGateway,
  WebSocketServer,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { timingSafeEqual } from 'crypto';
import { WsEvent } from './sync.events';

@WebSocketGateway({
  path: '/v1/ws',
  cors: { origin: false },
  transports: ['websocket'],
})
export class SyncGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server!: Server;

  private readonly logger = new Logger(SyncGateway.name);
  private readonly expectedToken: string;
  private readonly clients = new Map<string, Socket>();

  constructor(cfg: ConfigService) {
    this.expectedToken = cfg.get<string>('API_TOKEN') ?? '';
  }

  handleConnection(client: Socket) {
    if (!this.expectedToken) {
      this.logger.error('API_TOKEN missing — rejecting WS client');
      client.disconnect(true);
      return;
    }
    const provided =
      (client.handshake.auth?.token as string | undefined) ??
      this.fromBearer(client.handshake.headers['authorization']) ??
      (client.handshake.query.token as string | undefined);

    if (!provided || !safeEqual(provided, this.expectedToken)) {
      this.logger.warn(`WS auth failed for ${client.id}`);
      client.disconnect(true);
      return;
    }

    this.clients.set(client.id, client);
    this.logger.log(`WS connect ${client.id} (total=${this.clients.size})`);
    client.emit('hello', { clientId: client.id, ts: new Date().toISOString() });
  }

  handleDisconnect(client: Socket) {
    this.clients.delete(client.id);
    this.logger.log(`WS disconnect ${client.id} (total=${this.clients.size})`);
  }

  @SubscribeMessage('ping')
  handlePing() {
    return { event: 'pong', data: { ts: Date.now() } };
  }

  broadcast(event: WsEvent) {
    if (!this.server) return;
    this.server.emit(event.type, event.data);
    this.logger.debug(`-> ${event.type} (n=${this.clients.size})`);
  }

  private fromBearer(header: string | string[] | undefined): string | undefined {
    if (!header || Array.isArray(header)) return undefined;
    return header.startsWith('Bearer ') ? header.slice(7) : undefined;
  }
}

function safeEqual(a: string, b: string): boolean {
  const ba = Buffer.from(a);
  const bb = Buffer.from(b);
  if (ba.length !== bb.length) return false;
  return timingSafeEqual(ba, bb);
}
