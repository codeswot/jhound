import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';

@Entity({ name: 'drafts' })
export class Draft {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Index()
  @Column({ name: 'job_id', type: 'uuid', nullable: true })
  jobId!: string | null;

  @Column({ name: 'reply_to_resend_id', type: 'text', nullable: true })
  replyToResendId!: string | null;

  @Column({ name: 'to_addresses', type: 'text', array: true })
  toAddresses!: string[];

  @Column({ name: 'cc_addresses', type: 'text', array: true, nullable: true })
  ccAddresses!: string[] | null;

  @Column({ name: 'bcc_addresses', type: 'text', array: true, nullable: true })
  bccAddresses!: string[] | null;

  @Column({ name: 'reply_to', type: 'text', nullable: true })
  replyTo!: string | null;

  @Column({ type: 'text', nullable: true })
  subject!: string | null;

  @Column({ name: 'body_html', type: 'text', nullable: true })
  bodyHtml!: string | null;

  @Column({ name: 'body_text', type: 'text', nullable: true })
  bodyText!: string | null;

  @Column({ type: 'jsonb', nullable: true })
  tags!: Record<string, string> | null;

  @Column({ type: 'jsonb', nullable: true })
  headers!: Record<string, string> | null;

  @Column({ name: 'sent_resend_id', type: 'text', nullable: true })
  sentResendId!: string | null;

  @Column({ name: 'sent_at', type: 'timestamptz', nullable: true })
  sentAt!: Date | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt!: Date;
}
