import { Controller, Get, Param, ParseUUIDPipe, Query } from '@nestjs/common';
import { OssService } from './oss.service';
import { ListOssDto } from './oss.dto';

@Controller('oss')
export class OssController {
  constructor(private readonly svc: OssService) {}

  @Get()
  list(@Query() dto: ListOssDto) {
    return this.svc.list(dto);
  }

  @Get(':id')
  findOne(@Param('id', new ParseUUIDPipe()) id: string) {
    return this.svc.findOne(id);
  }
}
