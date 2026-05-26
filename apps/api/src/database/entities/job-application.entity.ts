import { Column, Entity, Index, OneToMany, PrimaryGeneratedColumn } from 'typeorm';
import { FollowUp } from './follow-up.entity';

@Entity({ name: 'job_applications' })
export class JobApplication {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ name: 'job_title', type: 'text' })
  jobTitle!: string;

  @Column({ type: 'text' })
  company!: string;

  @Column({ name: 'company_domain', type: 'text', nullable: true })
  companyDomain!: string | null;

  @Index({ unique: true })
  @Column({ name: 'job_url', type: 'text' })
  jobUrl!: string;

  @Column({ name: 'job_description', type: 'text', nullable: true })
  jobDescription!: string | null;

  @Column({ name: 'source_board', type: 'text' })
  sourceBoard!: string;

  @Column({ type: 'text', nullable: true })
  location!: string | null;

  @Column({ name: 'is_remote', type: 'boolean', default: true })
  isRemote!: boolean;

  @Column({ name: 'application_method', type: 'text' })
  applicationMethod!: string;

  @Column({ type: 'text', default: 'applied' })
  status!: string;

  @Column({ name: 'applied_at', type: 'timestamptz' })
  appliedAt!: Date;

  @Column({ name: 'hiring_manager_name', type: 'text', nullable: true })
  hiringManagerName!: string | null;

  @Column({ name: 'hiring_manager_email', type: 'text', nullable: true })
  hiringManagerEmail!: string | null;

  @Column({ name: 'hiring_manager_linkedin', type: 'text', nullable: true })
  hiringManagerLinkedin!: string | null;

  @Column({ name: 'ai_generated_email', type: 'jsonb', nullable: true })
  aiGeneratedEmail!: Record<string, unknown> | null;

  @Column({ name: 'ai_job_match_score', type: 'float', nullable: true })
  aiJobMatchScore!: number | null;

  @Column({ name: 'ai_priority_tier', type: 'int', nullable: true })
  aiPriorityTier!: number | null;

  @Column({ name: 'ai_reasoning', type: 'text', nullable: true })
  aiReasoning!: string | null;

  @Column({ name: 'ai_tags', type: 'text', array: true, nullable: true })
  aiTags!: string[] | null;

  @Column({ name: 'last_follow_up_at', type: 'timestamptz', nullable: true })
  lastFollowUpAt!: Date | null;

  @Column({ name: 'follow_up_count', type: 'int', default: 0 })
  followUpCount!: number;

  @Column({ name: 'response_received_at', type: 'timestamptz', nullable: true })
  responseReceivedAt!: Date | null;

  @Column({ name: 'response_type', type: 'text', nullable: true })
  responseType!: string | null;

  @Column({ type: 'jsonb', nullable: true })
  metadata!: Record<string, unknown> | null;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;

  @Column({ name: 'updated_at', type: 'timestamptz' })
  updatedAt!: Date;

  @OneToMany(() => FollowUp, (f) => f.job)
  followUps!: FollowUp[];
}
