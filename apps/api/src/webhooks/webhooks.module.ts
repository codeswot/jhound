import { Module } from '@nestjs/common';
import { ResendWebhookController } from './resend-webhook.controller';
import { SyncModule } from '../sync/sync.module';

@Module({
  imports: [SyncModule],
  controllers: [ResendWebhookController],
})
export class WebhooksModule {}
