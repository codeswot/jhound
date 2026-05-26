import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { SyncGateway } from './sync.gateway';
import { PgListener } from './pg-listener.service';

@Module({
  imports: [AuthModule],
  providers: [SyncGateway, PgListener],
  exports: [SyncGateway],
})
export class SyncModule {}
