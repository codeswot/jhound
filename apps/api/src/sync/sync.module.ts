import { Module } from '@nestjs/common';
import { SyncGateway } from './sync.gateway';
import { PgListener } from './pg-listener.service';

@Module({
  providers: [SyncGateway, PgListener],
  exports: [SyncGateway],
})
export class SyncModule {}
