import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { JwtModule } from '@nestjs/jwt';
import { BearerGuard } from './bearer.guard';
import { NostrAuthService } from './nostr/nostr-auth.service';
import { NostrAuthController } from './nostr/nostr-auth.controller';

@Module({
  imports: [
    JwtModule.registerAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (cfg: ConfigService) => ({
        secret: cfg.get<string>('JWT_SECRET') ?? cfg.get<string>('API_TOKEN') ?? 'change-me',
        signOptions: { algorithm: 'HS256' },
      }),
    }),
  ],
  providers: [BearerGuard, NostrAuthService],
  controllers: [NostrAuthController],
  exports: [BearerGuard, JwtModule],
})
export class AuthModule {}
