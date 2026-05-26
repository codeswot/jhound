-- jhound-api: drafts table.
-- Email source of truth = Resend. DB only persists unsent drafts.
-- Run once against the existing jhound DB:
--   docker exec -i jHound-postgres psql -U jhound -d jhound < apps/api/migrations/001_drafts.sql

CREATE TABLE IF NOT EXISTS drafts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

  job_id UUID REFERENCES job_applications(id) ON DELETE SET NULL,
  reply_to_resend_id TEXT,

  to_addresses TEXT[] NOT NULL,
  cc_addresses TEXT[],
  bcc_addresses TEXT[],
  reply_to TEXT,

  subject TEXT,
  body_html TEXT,
  body_text TEXT,

  tags JSONB,
  headers JSONB,

  sent_resend_id TEXT,
  sent_at TIMESTAMPTZ,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_drafts_job_id ON drafts(job_id);
CREATE INDEX IF NOT EXISTS idx_drafts_unsent ON drafts(created_at DESC) WHERE sent_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_drafts_sent_resend_id ON drafts(sent_resend_id) WHERE sent_resend_id IS NOT NULL;

DROP TRIGGER IF EXISTS update_drafts_updated_at ON drafts;
CREATE TRIGGER update_drafts_updated_at
  BEFORE UPDATE ON drafts
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
