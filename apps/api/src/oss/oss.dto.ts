import { IsIn, IsOptional } from 'class-validator';
import { PaginationDto } from '../common/pagination.dto';

export class ListOssDto extends PaginationDto {
  @IsOptional()
  @IsIn(['discovered_at', 'relevance_score', 'bounty_amount'])
  sort: 'discovered_at' | 'relevance_score' | 'bounty_amount' = 'discovered_at';

  @IsOptional()
  pursued?: string; // 'true' | 'false' | 'all'
}
