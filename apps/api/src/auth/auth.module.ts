import { Module } from '@nestjs/common';
import { BearerGuard } from './bearer.guard';

@Module({
  providers: [BearerGuard],
  exports: [BearerGuard],
})
export class AuthModule {}
