import { Controller, Get, Param, ParseUUIDPipe, Query } from '@nestjs/common';
import { JobsService } from './jobs.service';
import { ListJobsDto } from './jobs.dto';

@Controller('jobs')
export class JobsController {
  constructor(private readonly jobs: JobsService) {}

  @Get()
  list(@Query() dto: ListJobsDto) {
    return this.jobs.list(dto);
  }

  @Get(':id')
  findOne(@Param('id', new ParseUUIDPipe()) id: string) {
    return this.jobs.findOne(id);
  }
}
