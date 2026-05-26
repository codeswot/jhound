import {
  CanActivate,
  ExecutionContext,
  Injectable,
  Logger,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Reflector } from '@nestjs/core';
import { JwtService } from '@nestjs/jwt';
import { timingSafeEqual } from 'crypto';
import { IS_PUBLIC_KEY } from './public.decorator';

@Injectable()
export class BearerGuard implements CanActivate {
  private readonly logger = new Logger(BearerGuard.name);

  constructor(
    private readonly config: ConfigService,
    private readonly reflector: Reflector,
    private readonly jwt: JwtService,
  ) {}

  async canActivate(ctx: ExecutionContext): Promise<boolean> {
    const isPublic = this.reflector.getAllAndOverride<boolean>(IS_PUBLIC_KEY, [
      ctx.getHandler(),
      ctx.getClass(),
    ]);
    if (isPublic) return true;

    const req = ctx.switchToHttp().getRequest<{
      headers: Record<string, string | undefined>;
      user?: { sub: string; kind: string };
    }>();
    const header = req.headers['authorization'];
    if (!header || !header.startsWith('Bearer ')) {
      throw new UnauthorizedException('missing bearer token');
    }
    const provided = header.slice(7);

    if (provided.split('.').length === 3) {
      try {
        const payload = await this.jwt.verifyAsync<{ sub: string; kind: string }>(provided);
        req.user = payload;
        return true;
      } catch (err) {
        throw new UnauthorizedException(`invalid jwt: ${(err as Error).message}`);
      }
    }

    const apiToken = this.config.get<string>('API_TOKEN');
    if (!apiToken) {
      this.logger.error('API_TOKEN missing and token is not a JWT — refusing');
      throw new UnauthorizedException('server misconfigured');
    }
    const a = Buffer.from(provided);
    const b = Buffer.from(apiToken);
    if (a.length !== b.length || !timingSafeEqual(a, b)) {
      throw new UnauthorizedException('invalid token');
    }
    return true;
  }
}
