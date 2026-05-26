import {
  Body,
  Controller,
  Get,
  Header,
  Param,
  Post,
  Query,
  Res,
} from '@nestjs/common';
import { Response } from 'express';
import { EmailsService } from './emails.service';
import { ListEmailsDto, ReplyEmailDto, SendEmailDto } from './emails.dto';

@Controller('emails')
export class EmailsController {
  constructor(private readonly svc: EmailsService) {}

  @Get('inbox')
  listInbox(@Query() q: ListEmailsDto) {
    return this.svc.listInbox(q.limit, q.after, q.before);
  }

  @Get('inbox/:id')
  getInbox(@Param('id') id: string) {
    return this.svc.getInbox(id);
  }

  @Get('inbox/:id/attachments/:attId')
  @Header('Cache-Control', 'private, max-age=300')
  async getAttachment(
    @Param('id') id: string,
    @Param('attId') attId: string,
    @Res() res: Response,
  ) {
    const buf = await this.svc.getAttachment(id, attId);
    res.setHeader('Content-Type', 'application/octet-stream');
    res.send(Buffer.from(buf));
  }

  @Get('sent')
  listSent(@Query() q: ListEmailsDto) {
    return this.svc.listSent(q.limit, q.after, q.before);
  }

  @Get('sent/:id')
  getSent(@Param('id') id: string) {
    return this.svc.getSent(id);
  }

  @Post('send')
  send(@Body() dto: SendEmailDto) {
    return this.svc.send(dto);
  }

  @Post('inbox/:id/reply')
  reply(@Param('id') id: string, @Body() dto: ReplyEmailDto) {
    return this.svc.reply(id, dto);
  }
}
