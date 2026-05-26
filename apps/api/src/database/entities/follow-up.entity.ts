import { Column, Entity, JoinColumn, ManyToOne, PrimaryGeneratedColumn } from 'typeorm';
import { JobApplication } from './job-application.entity';

@Entity({ name: 'follow_ups' })
export class FollowUp {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ name: 'job_id', type: 'uuid', nullable: true })
  jobId!: string | null;

  @ManyToOne(() => JobApplication, (j) => j.followUps, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'job_id' })
  job!: JobApplication | null;

  @Column({ name: 'sent_at', type: 'timestamptz' })
  sentAt!: Date;

  @Column({ name: 'email_subject', type: 'text', nullable: true })
  emailSubject!: string | null;

  @Column({ name: 'email_body', type: 'text', nullable: true })
  emailBody!: string | null;

  @Column({ name: 'response_received', type: 'boolean', default: false })
  responseReceived!: boolean;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;
}
