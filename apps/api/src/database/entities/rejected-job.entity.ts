import { Column, Entity, PrimaryGeneratedColumn } from 'typeorm';

@Entity({ name: 'rejected_jobs' })
export class RejectedJob {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ name: 'job_url', type: 'text', unique: true })
  jobUrl!: string;

  @Column({ name: 'job_title', type: 'text', nullable: true })
  jobTitle!: string | null;

  @Column({ type: 'text', nullable: true })
  company!: string | null;

  @Column({ name: 'source_board', type: 'text', nullable: true })
  sourceBoard!: string | null;

  @Column({ name: 'reject_reason', type: 'text' })
  rejectReason!: string;

  @Column({ name: 'reject_details', type: 'jsonb', nullable: true })
  rejectDetails!: Record<string, unknown> | null;

  @Column({ name: 'rejected_at', type: 'timestamptz' })
  rejectedAt!: Date;
}
