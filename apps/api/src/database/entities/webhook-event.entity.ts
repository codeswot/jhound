import { Column, CreateDateColumn, Entity, Index, PrimaryGeneratedColumn } from 'typeorm';

@Entity({ name: 'webhook_events' })
@Index('uq_webhook_events_provider_external', ['provider', 'externalId'], { unique: true })
export class WebhookEvent {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'text' })
  provider!: string;

  @Column({ name: 'external_id', type: 'text' })
  externalId!: string;

  @Column({ name: 'event_type', type: 'text', nullable: true })
  eventType!: string | null;

  @Column({ type: 'jsonb', nullable: true })
  payload!: unknown;

  @CreateDateColumn({ name: 'received_at', type: 'timestamptz' })
  receivedAt!: Date;
}
