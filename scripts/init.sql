CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE TABLE job_applications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

  job_title TEXT NOT NULL,
  company TEXT NOT NULL,
  company_domain TEXT,
  job_url TEXT UNIQUE NOT NULL,
  job_description TEXT,
  source_board TEXT NOT NULL,
  location TEXT,
  is_remote BOOLEAN DEFAULT true,

  application_method TEXT NOT NULL,
  status TEXT DEFAULT 'applied',
  applied_at TIMESTAMPTZ DEFAULT NOW(),

  hiring_manager_name TEXT,
  hiring_manager_email TEXT,
  hiring_manager_linkedin TEXT,

  ai_generated_email JSONB,
  ai_job_match_score FLOAT,
  ai_priority_tier INTEGER,
  ai_reasoning TEXT,
  ai_tags TEXT[],

  last_follow_up_at TIMESTAMPTZ,
  follow_up_count INTEGER DEFAULT 0,
  response_received_at TIMESTAMPTZ,
  response_type TEXT,

  metadata JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_status ON job_applications(status);
CREATE INDEX idx_applied_at ON job_applications(applied_at DESC);
CREATE INDEX idx_company ON job_applications(company);
CREATE INDEX idx_source ON job_applications(source_board);
CREATE INDEX idx_application_method ON job_applications(application_method);
CREATE INDEX idx_priority_tier ON job_applications(ai_priority_tier);
CREATE INDEX idx_tags ON job_applications USING GIN(ai_tags);
CREATE INDEX idx_company_trgm ON job_applications USING GIN (LOWER(company) gin_trgm_ops);
CREATE INDEX idx_title_trgm ON job_applications USING GIN (LOWER(job_title) gin_trgm_ops);

CREATE TABLE rejected_jobs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  job_url TEXT UNIQUE NOT NULL,
  job_title TEXT,
  company TEXT,
  source_board TEXT,
  reject_reason TEXT NOT NULL,
  reject_details JSONB,
  rejected_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_rejected_reason ON rejected_jobs(reject_reason);
CREATE INDEX idx_rejected_at ON rejected_jobs(rejected_at DESC);

CREATE TABLE job_skills (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  job_id UUID REFERENCES job_applications(id) ON DELETE CASCADE,
  skill TEXT NOT NULL,
  is_required BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_job_skills_job_id ON job_skills(job_id);
CREATE INDEX idx_skill ON job_skills(skill);

CREATE TABLE follow_ups (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  job_id UUID REFERENCES job_applications(id) ON DELETE CASCADE,
  sent_at TIMESTAMPTZ DEFAULT NOW(),
  email_subject TEXT,
  email_body TEXT,
  response_received BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_follow_ups_job_id ON follow_ups(job_id);

CREATE TABLE email_responses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  job_id UUID REFERENCES job_applications(id) ON DELETE CASCADE,
  from_email TEXT NOT NULL,
  subject TEXT,
  body TEXT,
  ai_classification TEXT,
  resend_email_id TEXT UNIQUE,
  received_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_email_responses_job_id ON email_responses(job_id);
CREATE INDEX idx_email_responses_classification ON email_responses(ai_classification);
CREATE INDEX idx_email_responses_received ON email_responses(received_at DESC);
CREATE INDEX idx_email_responses_resend_id ON email_responses(resend_email_id);

CREATE TABLE sent_messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  job_id UUID REFERENCES job_applications(id) ON DELETE CASCADE,
  message_id TEXT UNIQUE NOT NULL,
  subject TEXT,
  to_email TEXT,
  kind TEXT DEFAULT 'application',
  sent_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_sent_messages_job_id ON sent_messages(job_id);
CREATE INDEX idx_sent_messages_to_email ON sent_messages(to_email);

CREATE TABLE company_research (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  job_id UUID REFERENCES job_applications(id) ON DELETE CASCADE,
  company TEXT NOT NULL,
  website TEXT,
  linkedin TEXT,
  twitter TEXT,
  github TEXT,
  hq_location TEXT,
  company_size TEXT,
  funding_stage TEXT,
  industry TEXT,
  one_liner TEXT,
  summary TEXT,
  tech_stack TEXT[],
  recent_news JSONB,
  raw_html_excerpt TEXT,
  researched_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (job_id)
);

CREATE INDEX idx_company_research_company ON company_research(company);

CREATE TABLE opensource_opportunities (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL,
  repository TEXT NOT NULL,
  url TEXT UNIQUE NOT NULL,
  description TEXT,
  bounty_amount NUMERIC,
  matched_skills TEXT[],
  language TEXT,
  stars INTEGER,
  relevance_score INTEGER,
  source TEXT,
  metadata JSONB,
  discovered_at TIMESTAMPTZ DEFAULT NOW(),
  is_pursued BOOLEAN DEFAULT false,
  notes TEXT
);

CREATE INDEX idx_oss_score ON opensource_opportunities(relevance_score DESC);
CREATE INDEX idx_oss_discovered ON opensource_opportunities(discovered_at DESC);

CREATE TABLE execution_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  workflow_name TEXT NOT NULL,
  execution_id TEXT,
  status TEXT,
  message TEXT,
  metadata JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_execution_logs_workflow ON execution_logs(workflow_name);
CREATE INDEX idx_execution_logs_created ON execution_logs(created_at DESC);

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_job_applications_updated_at
  BEFORE UPDATE ON job_applications
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE OR REPLACE FUNCTION job_exists(p_job_url TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS(
      SELECT 1 FROM job_applications WHERE job_url = p_job_url
      UNION ALL
      SELECT 1 FROM rejected_jobs WHERE job_url = p_job_url
    );
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION job_fuzzy_exists(
  p_company TEXT,
  p_job_title TEXT,
  p_threshold REAL DEFAULT 0.7
)
RETURNS BOOLEAN AS $$
BEGIN
    IF p_company IS NULL OR p_job_title IS NULL THEN
      RETURN FALSE;
    END IF;
    RETURN EXISTS(
      SELECT 1 FROM job_applications
       WHERE applied_at > NOW() - INTERVAL '60 days'
         AND similarity(LOWER(company), LOWER(p_company)) >= p_threshold
         AND similarity(LOWER(job_title), LOWER(p_job_title)) >= p_threshold
    );
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE VIEW application_stats AS
SELECT
  DATE(applied_at) as date,
  COUNT(*) as total_applications,
  COUNT(*) FILTER (WHERE application_method = 'easy_apply') as easy_apply_count,
  COUNT(*) FILTER (WHERE application_method = 'email') as email_count,
  COUNT(*) FILTER (WHERE application_method = 'manual') as manual_count,
  COUNT(*) FILTER (WHERE ai_priority_tier = 1) as tier1_count,
  COUNT(*) FILTER (WHERE ai_priority_tier = 2) as tier2_count,
  COUNT(*) FILTER (WHERE response_received_at IS NOT NULL) as responses_received,
  COALESCE(ROUND(100.0 * COUNT(*) FILTER (WHERE response_received_at IS NOT NULL) / NULLIF(COUNT(*), 0), 2), 0) as response_rate
FROM job_applications
GROUP BY DATE(applied_at)
ORDER BY date DESC;

CREATE OR REPLACE VIEW source_performance AS
SELECT
  source_board,
  COUNT(*) as total_jobs,
  AVG(ai_job_match_score) as avg_match_score,
  COUNT(*) FILTER (WHERE application_method = 'easy_apply') as easy_apply_available,
  COUNT(*) FILTER (WHERE ai_priority_tier = 1) as tier1_jobs,
  COUNT(*) FILTER (WHERE response_received_at IS NOT NULL) as responses_received,
  COALESCE(ROUND(100.0 * COUNT(*) FILTER (WHERE response_received_at IS NOT NULL) / NULLIF(COUNT(*), 0), 2), 0) as response_rate
FROM job_applications
GROUP BY source_board
ORDER BY total_jobs DESC;

CREATE OR REPLACE VIEW needs_manual_review AS
SELECT
  id,
  job_title,
  company,
  source_board,
  application_method,
  status,
  ai_priority_tier,
  ai_job_match_score,
  job_url,
  applied_at
FROM job_applications
WHERE status IN ('needs_manual', 'needs_email')
ORDER BY ai_priority_tier ASC NULLS LAST, ai_job_match_score DESC NULLS LAST, applied_at DESC;

CREATE OR REPLACE VIEW awaiting_followup AS
SELECT
  ja.id,
  ja.job_title,
  ja.company,
  ja.hiring_manager_email,
  ja.applied_at,
  ja.follow_up_count,
  ja.last_follow_up_at,
  EXTRACT(DAY FROM NOW() - COALESCE(ja.last_follow_up_at, ja.applied_at))::INT AS days_since_contact
FROM job_applications ja
WHERE ja.application_method = 'email'
  AND ja.hiring_manager_email IS NOT NULL
  AND ja.response_received_at IS NULL
  AND ja.status NOT IN ('rejected', 'ghosted')
  AND ja.follow_up_count < 2
  AND COALESCE(ja.last_follow_up_at, ja.applied_at) < NOW() - INTERVAL '7 days'
ORDER BY ja.ai_priority_tier ASC NULLS LAST, ja.applied_at ASC;

CREATE OR REPLACE VIEW rejection_breakdown AS
SELECT
  reject_reason,
  source_board,
  COUNT(*) as total
FROM rejected_jobs
GROUP BY reject_reason, source_board
ORDER BY total DESC;

CREATE OR REPLACE VIEW workflow_health AS
SELECT
  workflow_name,
  COUNT(*) FILTER (WHERE status = 'success' AND created_at > NOW() - INTERVAL '30 days') AS successes_30d,
  COUNT(*) FILTER (WHERE status = 'error'   AND created_at > NOW() - INTERVAL '30 days') AS errors_30d,
  MAX(created_at) FILTER (WHERE status = 'success')                                       AS last_success_at,
  MAX(created_at) FILTER (WHERE status = 'error')                                         AS last_error_at,
  MAX(created_at)                                                                          AS last_run_at,
  (ARRAY_AGG(status ORDER BY created_at DESC))[1]                                          AS last_status
FROM execution_logs
GROUP BY workflow_name;
