import { Column, Entity, PrimaryGeneratedColumn } from 'typeorm';

@Entity({ name: 'opensource_opportunities' })
export class OpensourceOpportunity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'text' })
  title!: string;

  @Column({ type: 'text' })
  repository!: string;

  @Column({ type: 'text', unique: true })
  url!: string;

  @Column({ type: 'text', nullable: true })
  description!: string | null;

  @Column({ name: 'bounty_amount', type: 'numeric', nullable: true })
  bountyAmount!: string | null;

  @Column({ name: 'matched_skills', type: 'text', array: true, nullable: true })
  matchedSkills!: string[] | null;

  @Column({ type: 'text', nullable: true })
  language!: string | null;

  @Column({ type: 'int', nullable: true })
  stars!: number | null;

  @Column({ name: 'relevance_score', type: 'int', nullable: true })
  relevanceScore!: number | null;

  @Column({ type: 'text', nullable: true })
  source!: string | null;

  @Column({ type: 'jsonb', nullable: true })
  metadata!: Record<string, unknown> | null;

  @Column({ name: 'discovered_at', type: 'timestamptz' })
  discoveredAt!: Date;

  @Column({ name: 'is_pursued', type: 'boolean', default: false })
  isPursued!: boolean;

  @Column({ type: 'text', nullable: true })
  notes!: string | null;
}
