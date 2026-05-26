-- jhound-api: idempotency log for inbound webhooks (Resend / future providers).
-- Svix retries on non-2xx. We dedupe by `svix-id` so retries become no-ops.
--
--   docker exec -i jHound-postgres psql -U jhound -d jhound < apps/api/migrations/003_webhook_events.sql

CREATE TABLE IF NOT EXISTS webhook_events (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  provider TEXT NOT NULL,
  external_id TEXT NOT NULL,
  event_type TEXT,
  payload JSONB,
  received_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_webhook_events_provider_external
  ON webhook_events(provider, external_id);

CREATE INDEX IF NOT EXISTS idx_webhook_events_received
  ON webhook_events(received_at DESC);
