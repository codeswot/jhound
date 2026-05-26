import { Transform } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsEmail,
  IsInt,
  IsObject,
  IsOptional,
  IsString,
  IsUUID,
  Max,
  Min,
} from 'class-validator';

export class ListDraftsDto {
  @IsOptional()
  @Transform(({ value }) => Number(value))
  @IsInt()
  @Min(1)
  @Max(200)
  limit: number = 50;

  @IsOptional()
  @Transform(({ value }) => Number(value))
  @IsInt()
  @Min(0)
  offset: number = 0;

  @IsOptional()
  @Transform(({ value }) => value === 'true' || value === true)
  unsent_only?: boolean;
}

export class UpsertDraftDto {
  @IsOptional()
  @IsUUID()
  job_id?: string;

  @IsOptional()
  @IsString()
  reply_to_resend_id?: string;

  @IsArray()
  @ArrayMaxSize(50)
  @IsEmail({}, { each: true })
  to_addresses!: string[];

  @IsOptional()
  @IsArray()
  @IsEmail({}, { each: true })
  cc_addresses?: string[];

  @IsOptional()
  @IsArray()
  @IsEmail({}, { each: true })
  bcc_addresses?: string[];

  @IsOptional()
  @IsString()
  reply_to?: string;

  @IsOptional()
  @IsString()
  subject?: string;

  @IsOptional()
  @IsString()
  body_html?: string;

  @IsOptional()
  @IsString()
  body_text?: string;

  @IsOptional()
  @IsObject()
  tags?: Record<string, string>;

  @IsOptional()
  @IsObject()
  headers?: Record<string, string>;
}

export class PatchDraftDto {
  @IsOptional()
  @IsUUID()
  job_id?: string;

  @IsOptional()
  @IsArray()
  @IsEmail({}, { each: true })
  to_addresses?: string[];

  @IsOptional()
  @IsArray()
  @IsEmail({}, { each: true })
  cc_addresses?: string[];

  @IsOptional()
  @IsArray()
  @IsEmail({}, { each: true })
  bcc_addresses?: string[];

  @IsOptional()
  @IsString()
  reply_to?: string;

  @IsOptional()
  @IsString()
  subject?: string;

  @IsOptional()
  @IsString()
  body_html?: string;

  @IsOptional()
  @IsString()
  body_text?: string;

  @IsOptional()
  @IsObject()
  tags?: Record<string, string>;

  @IsOptional()
  @IsObject()
  headers?: Record<string, string>;
}
