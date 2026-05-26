export interface ResendListPage<T> {
  object: 'list';
  has_more: boolean;
  data: T[];
}

export interface ResendSentSummary {
  id: string;
  to: string[];
  from: string;
  created_at: string;
  subject: string | null;
  bcc: string | string[] | null;
  cc: string | string[] | null;
  reply_to: string | string[] | null;
  last_event: string | null;
  scheduled_at: string | null;
}

export interface ResendReceivedAttachment {
  id: string;
  filename: string;
  content_type: string;
  size: number;
}

export interface ResendAttachment {
  id: string;
  filename: string;
  content_type: string;
  size: number;
}

export interface ResendReceivedSummary {
  id: string;
  to: string[];
  from: string;
  created_at: string;
  subject: string | null;
  bcc: string | string[] | null;
  cc: string | string[] | null;
  reply_to: string | string[] | null;
  message_id: string | null;
  attachments: ResendReceivedAttachment[];
}

export interface ResendEmailBody {
  id: string;
  from: string;
  to: string[];
  subject: string | null;
  html: string | null;
  text: string | null;
  created_at: string;
  last_event?: string | null;
  headers?: Record<string, string> | null;
  tags?: ResendTag[] | Record<string, string> | null;
  attachments?: ResendReceivedAttachment[] | null;
}

export interface ResendTag {
  name: string;
  value: string;
}

export interface ResendSendInput {
  from: string;
  to: string | string[];
  subject: string;
  html?: string;
  text?: string;
  cc?: string | string[];
  bcc?: string | string[];
  reply_to?: string | string[];
  scheduled_at?: string;
  attachments?: Array<{
    filename: string;
    content?: string;
    path?: string;
    content_id?: string;
    content_type?: string;
  }>;
  tags?: Array<{ name: string; value: string }>;
  headers?: Record<string, string>;
}

export interface ResendSendResult {
  id: string;
}

export interface ListQuery {
  limit?: number;
  after?: string;
  before?: string;
}
