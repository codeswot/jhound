import { Body, Controller, Get, Post } from '@nestjs/common';
import { IsArray, IsInt, IsString, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';
import { Public } from '../public.decorator';
import { NostrAuthService } from './nostr-auth.service';

class SignedEventTagsItem {}

class SignedEventDto {
  @IsString()
  id!: string;

  @IsString()
  pubkey!: string;

  @IsInt()
  created_at!: number;

  @IsInt()
  kind!: number;

  @IsArray()
  tags!: string[][];

  @IsString()
  content!: string;

  @IsString()
  sig!: string;
}

class VerifyDto {
  @ValidateNested()
  @Type(() => SignedEventDto)
  event!: SignedEventDto;
}

@Controller('auth')
export class NostrAuthController {
  constructor(private readonly svc: NostrAuthService) {}

  @Public()
  @Get('challenge')
  challenge() {
    return this.svc.issueChallenge();
  }

  @Public()
  @Post('verify')
  verify(@Body() body: VerifyDto) {
    return this.svc.verifyAndIssueJwt(body.event as unknown as Parameters<NostrAuthService['verifyAndIssueJwt']>[0]);
  }
}
