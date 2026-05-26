import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { JobApplication } from '../database/entities/job-application.entity';
import { ResendModule } from '../resend/resend.module';
import { JobsController } from './jobs.controller';
import { JobsService } from './jobs.service';

@Module({
  imports: [TypeOrmModule.forFeature([JobApplication]), ResendModule],
  controllers: [JobsController],
  providers: [JobsService],
})
export class JobsModule {}
