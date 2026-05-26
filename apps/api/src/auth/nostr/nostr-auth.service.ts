import {
  BadRequestException,
  Injectable,
  Logger,
  OnModuleInit,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { randomBytes } from 'crypto';
import { nip19, verifyEvent, type Event as NostrEvent } from 'nostr-tools';

const CHALLENGE_TTL_MS = 5 * 60 * 1000;
const AUTH_KIND = 22242;
const MAX_EVENT_AGE_S = 600;

interface ChallengeRecord {
  nonce: string;
  expiresAt: number;
}

@Injectable()
export class NostrAuthService implements OnModuleInit {
  private readonly logger = new Logger(NostrAuthService.name);
  private readonly challenges = new Map<string, ChallengeRecord>();
  private cleanupTimer: NodeJS.Timeout | null = null;
  private allowedPubkeysHex: Set<string> = new Set();

  constructor(
    private readonly cfg: ConfigService,
    private readonly jwt: JwtService,
  ) {}

  onModuleInit() {
    const npubs = this.cfg.get<string>('NOSTR_ALLOWED_NPUBS') ?? this.cfg.get<string>('NOSTR_TARGET_NPUB') ?? '';
    for (const raw of npubs.split(',')) {
      const npub = raw.trim();
      if (!npub) continue;
      try {
        const decoded = nip19.decode(npub);
        if (decoded.type !== 'npub') continue;
        this.allowedPubkeysHex.add(decoded.data as string);
      } catch (err) {
        this.logger.warn(`Could not decode npub: ${npub}`);
      }
    }
    if (this.allowedPubkeysHex.size === 0) {
      this.logger.warn(
        'No allowed npubs decoded — Nostr auth will reject every request. Set NOSTR_TARGET_NPUB.',
      );
    } else {
      this.logger.log(`Allowed npubs loaded: ${this.allowedPubkeysHex.size}`);
    }

    this.cleanupTimer = setInterval(() => this.gcChallenges(), 60_000);
    this.cleanupTimer.unref?.();
  }

  issueChallenge(): { nonce: string; expires_at: string } {
    const nonce = randomBytes(24).toString('hex');
    const expiresAt = Date.now() + CHALLENGE_TTL_MS;
    this.challenges.set(nonce, { nonce, expiresAt });
    return { nonce, expires_at: new Date(expiresAt).toISOString() };
  }

  async verifyAndIssueJwt(event: NostrEvent): Promise<{ token: string; pubkey: string; expires_in: number }> {
    if (!event || typeof event !== 'object') {
      throw new BadRequestException('event missing');
    }
    if (event.kind !== AUTH_KIND) {
      throw new BadRequestException(`event.kind must be ${AUTH_KIND}`);
    }

    const ageS = Math.abs(Math.floor(Date.now() / 1000) - event.created_at);
    if (ageS > MAX_EVENT_AGE_S) {
      throw new UnauthorizedException('event too old or skewed');
    }

    if (!this.allowedPubkeysHex.has(event.pubkey)) {
      throw new UnauthorizedException('pubkey not allowed');
    }

    const challengeTag = event.tags?.find((t) => t[0] === 'challenge');
    const nonce = challengeTag?.[1];
    if (!nonce) {
      throw new BadRequestException('event missing challenge tag');
    }
    const record = this.challenges.get(nonce);
    if (!record) throw new UnauthorizedException('unknown or expired challenge');
    if (record.expiresAt < Date.now()) {
      this.challenges.delete(nonce);
      throw new UnauthorizedException('challenge expired');
    }

    let valid = false;
    try {
      valid = verifyEvent(event);
    } catch (err) {
      throw new UnauthorizedException(`signature verify failed: ${(err as Error).message}`);
    }
    if (!valid) throw new UnauthorizedException('invalid signature');

    this.challenges.delete(nonce);

    const expiresIn = Number(this.cfg.get('JWT_TTL_SECONDS') ?? 60 * 60 * 24 * 30);
    const token = await this.jwt.signAsync(
      { sub: event.pubkey, kind: 'nip46' },
      { expiresIn },
    );
    this.logger.log(`Issued JWT for pubkey ${event.pubkey.slice(0, 12)}…`);
    return { token, pubkey: event.pubkey, expires_in: expiresIn };
  }

  private gcChallenges() {
    const now = Date.now();
    for (const [k, v] of this.challenges) {
      if (v.expiresAt < now) this.challenges.delete(k);
    }
  }
}
