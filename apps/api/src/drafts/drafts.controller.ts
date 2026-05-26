import {
  Body,
  Controller,
  Delete,
  Get,
  Headers,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  Query,
} from '@nestjs/common';
import { DraftsService } from './drafts.service';
import { ListDraftsDto, PatchDraftDto, UpsertDraftDto } from './drafts.dto';

@Controller('drafts')
export class DraftsController {
  constructor(private readonly svc: DraftsService) {}

  @Get()
  list(@Query() dto: ListDraftsDto) {
    return this.svc.list(dto);
  }

  @Get(':id')
  findOne(@Param('id', new ParseUUIDPipe()) id: string) {
    return this.svc.findOne(id);
  }

  @Post()
  create(@Body() dto: UpsertDraftDto) {
    return this.svc.create(dto);
  }

  @Patch(':id')
  patch(@Param('id', new ParseUUIDPipe()) id: string, @Body() dto: PatchDraftDto) {
    return this.svc.patch(id, dto);
  }

  @Delete(':id')
  remove(@Param('id', new ParseUUIDPipe()) id: string) {
    return this.svc.remove(id);
  }

  @Post(':id/send')
  send(
    @Param('id', new ParseUUIDPipe()) id: string,
    @Headers('idempotency-key') idempotencyKey?: string,
  ) {
    return this.svc.send(id, idempotencyKey);
  }
}
