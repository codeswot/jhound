import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { JobApplication } from '../database/entities/job-application.entity';
import { StatsController } from './stats.controller';
import { StatsService } from './stats.service';

@Module({
  imports: [TypeOrmModule.forFeature([JobApplication])],
  controllers: [StatsController],
  providers: [StatsService],
})
export class StatsModule {}
