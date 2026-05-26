import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { JobApplication } from '../database/entities/job-application.entity';
import { ListJobsDto } from './jobs.dto';

@Injectable()
export class JobsService {
  constructor(
    @InjectRepository(JobApplication)
    private readonly repo: Repository<JobApplication>,
  ) {}

  async list(dto: ListJobsDto) {
    const qb = this.repo.createQueryBuilder('j');

    if (dto.status) qb.andWhere('j.status = :status', { status: dto.status });
    if (dto.source) qb.andWhere('j.source_board = :source', { source: dto.source });
    if (dto.tier) qb.andWhere('j.ai_priority_tier = :tier', { tier: dto.tier });
    if (dto.q) {
      qb.andWhere('(LOWER(j.company) LIKE :q OR LOWER(j.job_title) LIKE :q)', {
        q: `%${dto.q.toLowerCase()}%`,
      });
    }

    qb.orderBy(`j.${dto.sort ?? 'applied_at'}`, 'DESC', 'NULLS LAST')
      .limit(dto.limit)
      .offset(dto.offset);

    const [items, total] = await qb.getManyAndCount();
    return { items, total, limit: dto.limit, offset: dto.offset };
  }

  async findOne(id: string) {
    const job = await this.repo.findOne({
      where: { id },
      relations: { followUps: true },
    });
    if (!job) throw new NotFoundException(`job ${id} not found`);
    return job;
  }
}
