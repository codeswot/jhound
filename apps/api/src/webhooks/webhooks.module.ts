import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ResendWebhookController } from './resend-webhook.controller';
import { SyncModule } from '../sync/sync.module';
import { WebhookEvent } from '../database/entities/webhook-event.entity';

@Module({
  imports: [SyncModule, TypeOrmModule.forFeature([WebhookEvent])],
  controllers: [ResendWebhookController],
})
export class WebhooksModule {}
