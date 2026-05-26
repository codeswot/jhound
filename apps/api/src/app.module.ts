import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { APP_GUARD } from '@nestjs/core';
import { DatabaseModule } from './database/database.module';
import { AuthModule } from './auth/auth.module';
import { BearerGuard } from './auth/bearer.guard';
import { HealthModule } from './health/health.module';
import { JobsModule } from './jobs/jobs.module';
import { StatsModule } from './stats/stats.module';
import { ResendModule } from './resend/resend.module';
import { EmailsModule } from './emails/emails.module';
import { DraftsModule } from './drafts/drafts.module';
import { WebhooksModule } from './webhooks/webhooks.module';
import { SyncModule } from './sync/sync.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true, cache: true }),
    DatabaseModule,
    AuthModule,
    HealthModule,
    JobsModule,
    StatsModule,
    ResendModule,
    EmailsModule,
    DraftsModule,
    SyncModule,
    WebhooksModule,
  ],
  providers: [{ provide: APP_GUARD, useClass: BearerGuard }],
})
export class AppModule {}
