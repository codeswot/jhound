import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { JobApplication } from '../database/entities/job-application.entity';

@Injectable()
export class StatsService {
  constructor(
    @InjectRepository(JobApplication) private readonly repo: Repository<JobApplication>,
  ) {}

  async weekly() {
    return this.repo.query(`
      SELECT *
      FROM application_stats
      WHERE date >= CURRENT_DATE - INTERVAL '7 days'
      ORDER BY date DESC
    `);
  }

  async sources() {
    return this.repo.query(`SELECT * FROM source_performance`);
  }

  async overview() {
    const rows = await this.repo.query(`
      SELECT
        COUNT(*)::int AS total,
        COUNT(*) FILTER (WHERE applied_at::date = CURRENT_DATE)::int AS today,
        COUNT(*) FILTER (WHERE applied_at >= CURRENT_DATE - INTERVAL '7 days')::int AS week,
        COUNT(*) FILTER (WHERE response_received_at IS NOT NULL)::int AS responses,
        COUNT(*) FILTER (WHERE ai_priority_tier = 1)::int AS tier1,
        COUNT(*) FILTER (WHERE ai_priority_tier = 2)::int AS tier2,
        COUNT(*) FILTER (WHERE status IN ('needs_manual','needs_email'))::int AS needs_review
      FROM job_applications
    `);
    return rows[0];
  }
}
