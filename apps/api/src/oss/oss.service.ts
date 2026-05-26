import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { OpensourceOpportunity } from '../database/entities/opensource-opportunity.entity';
import { ListOssDto } from './oss.dto';

@Injectable()
export class OssService {
  constructor(
    @InjectRepository(OpensourceOpportunity)
    private readonly repo: Repository<OpensourceOpportunity>,
  ) {}

  async list(dto: ListOssDto) {
    const qb = this.repo.createQueryBuilder('o');

    if (dto.pursued === 'true') qb.andWhere('o.is_pursued = true');
    else if (dto.pursued === 'false') qb.andWhere('o.is_pursued = false');

    const col = dto.sort === 'discovered_at' ? 'o.discoveredAt' :
                dto.sort === 'relevance_score' ? 'o.relevanceScore' :
                'o.bountyAmount';
    qb.orderBy(col, 'DESC', 'NULLS LAST').limit(dto.limit).offset(dto.offset);

    const [items, total] = await qb.getManyAndCount();
    return { items, total, limit: dto.limit, offset: dto.offset };
  }

  async findOne(id: string) {
    const row = await this.repo.findOne({ where: { id } });
    if (!row) throw new NotFoundException(`oss ${id} not found`);
    return row;
  }
}
