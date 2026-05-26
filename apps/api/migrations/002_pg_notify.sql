-- jhound-api: pg_notify triggers for real-time WS broadcasts.
-- Channels:
--   jhound_job_event       payload: { op, id, status, tier, company, job_title, source_board, applied_at }
--   jhound_followup_event  payload: { op, id, job_id, sent_at }
--   jhound_oss_event       payload: { op, id, title, repository, relevance_score, discovered_at }
--
-- Idempotent — safe to re-run.
--   docker exec -i jHound-postgres psql -U jhound -d jhound < apps/api/migrations/002_pg_notify.sql

CREATE OR REPLACE FUNCTION notify_job_event()
RETURNS TRIGGER AS $$
DECLARE
  payload JSONB;
BEGIN
  payload := jsonb_build_object(
    'op',           TG_OP,
    'id',           NEW.id,
    'status',       NEW.status,
    'tier',         NEW.ai_priority_tier,
    'company',      NEW.company,
    'job_title',    NEW.job_title,
    'source_board', NEW.source_board,
    'applied_at',   NEW.applied_at,
    'updated_at',   NEW.updated_at
  );
  PERFORM pg_notify('jhound_job_event', payload::text);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS job_applications_notify_insert ON job_applications;
CREATE TRIGGER job_applications_notify_insert
  AFTER INSERT ON job_applications
  FOR EACH ROW
  EXECUTE FUNCTION notify_job_event();

DROP TRIGGER IF EXISTS job_applications_notify_update ON job_applications;
CREATE TRIGGER job_applications_notify_update
  AFTER UPDATE OF status, ai_priority_tier, response_received_at, response_type
  ON job_applications
  FOR EACH ROW
  EXECUTE FUNCTION notify_job_event();


CREATE OR REPLACE FUNCTION notify_followup_event()
RETURNS TRIGGER AS $$
BEGIN
  PERFORM pg_notify('jhound_followup_event', jsonb_build_object(
    'op',      TG_OP,
    'id',      NEW.id,
    'job_id',  NEW.job_id,
    'sent_at', NEW.sent_at
  )::text);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS follow_ups_notify_insert ON follow_ups;
CREATE TRIGGER follow_ups_notify_insert
  AFTER INSERT ON follow_ups
  FOR EACH ROW
  EXECUTE FUNCTION notify_followup_event();


CREATE OR REPLACE FUNCTION notify_oss_event()
RETURNS TRIGGER AS $$
BEGIN
  PERFORM pg_notify('jhound_oss_event', jsonb_build_object(
    'op',              TG_OP,
    'id',              NEW.id,
    'title',           NEW.title,
    'repository',      NEW.repository,
    'url',             NEW.url,
    'relevance_score', NEW.relevance_score,
    'bounty_amount',   NEW.bounty_amount,
    'discovered_at',   NEW.discovered_at
  )::text);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS opensource_opportunities_notify_insert ON opensource_opportunities;
CREATE TRIGGER opensource_opportunities_notify_insert
  AFTER INSERT ON opensource_opportunities
  FOR EACH ROW
  EXECUTE FUNCTION notify_oss_event();
