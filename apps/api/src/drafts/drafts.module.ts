import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Draft } from '../database/entities/draft.entity';
import { EmailsModule } from '../emails/emails.module';
import { DraftsController } from './drafts.controller';
import { DraftsService } from './drafts.service';

@Module({
  imports: [TypeOrmModule.forFeature([Draft]), EmailsModule],
  controllers: [DraftsController],
  providers: [DraftsService],
})
export class DraftsModule {}
