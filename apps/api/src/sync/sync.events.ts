export type WsEvent =
  | { type: 'job.created'; data: JobEventPayload }
  | { type: 'job.updated'; data: JobEventPayload }
  | { type: 'followup.sent'; data: FollowupEventPayload }
  | { type: 'oss.discovered'; data: OssEventPayload }
  | { type: 'email.sent'; data: ResendEventPayload }
  | { type: 'email.delivered'; data: ResendEventPayload }
  | { type: 'email.delivery_delayed'; data: ResendEventPayload }
  | { type: 'email.bounced'; data: ResendEventPayload }
  | { type: 'email.complained'; data: ResendEventPayload }
  | { type: 'email.opened'; data: ResendEventPayload }
  | { type: 'email.clicked'; data: ResendEventPayload }
  | { type: 'email.failed'; data: ResendEventPayload }
  | { type: 'email.received'; data: ResendEventPayload }
  | { type: 'email.scheduled'; data: ResendEventPayload }
  | { type: 'email.suppressed'; data: ResendEventPayload };

export interface JobEventPayload {
  op: 'INSERT' | 'UPDATE' | 'DELETE';
  id: string;
  status?: string | null;
  tier?: number | null;
  company?: string | null;
  job_title?: string | null;
  source_board?: string | null;
  applied_at?: string | null;
  updated_at?: string | null;
}

export interface FollowupEventPayload {
  op: 'INSERT' | 'UPDATE' | 'DELETE';
  id: string;
  job_id: string | null;
  sent_at: string | null;
}

export interface OssEventPayload {
  op: 'INSERT' | 'UPDATE' | 'DELETE';
  id: string;
  title: string;
  repository: string;
  url: string;
  relevance_score: number | null;
  bounty_amount: string | null;
  discovered_at: string | null;
}

export interface ResendEventPayload {
  type: string;
  email_id?: string;
  raw: unknown;
}
