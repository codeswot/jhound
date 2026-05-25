#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import sys

try:
    import psycopg2
    from psycopg2.extras import Json, RealDictCursor
except ImportError:
    psycopg2 = None
    Json = None
    RealDictCursor = None


def pg_conn():
    if psycopg2 is None:
        raise RuntimeError("psycopg2 is not installed; run inside the n8n container or pip install psycopg2-binary")
    return psycopg2.connect(
        host=os.getenv("POSTGRES_HOST", "postgres"),
        port=int(os.getenv("POSTGRES_PORT", "5432")),
        dbname=os.getenv("POSTGRES_DB", "jhound"),
        user=os.getenv("POSTGRES_USER", "jhound"),
        password=os.getenv("POSTGRES_PASSWORD", ""),
    )


def _read_input() -> dict:
    return json.load(sys.stdin)


def _emit(payload: dict) -> None:
    json.dump(payload, sys.stdout, ensure_ascii=False, default=str)
    sys.stdout.write("\n")


def cmd_record_application(payload: dict) -> dict:
    if not payload.get("job_url"):
        return {"ok": False, "error": "missing job_url"}
    method = payload.get("application_method", "manual")
    status = payload.get("status") or ("applied" if method != "manual" else "needs_email")

    conn = pg_conn()
    try:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute(
                """
                INSERT INTO job_applications (
                  job_title, company, company_domain, job_url, job_description,
                  source_board, location, is_remote, application_method, status,
                  hiring_manager_name, hiring_manager_email, hiring_manager_linkedin,
                  ai_generated_email,
                  ai_job_match_score, ai_priority_tier, ai_tags, ai_reasoning,
                  metadata
                ) VALUES (
                  %(job_title)s, %(company)s, %(company_domain)s, %(job_url)s, %(job_description)s,
                  %(source_board)s, %(location)s, %(is_remote)s, %(application_method)s, %(status)s,
                  %(hiring_manager_name)s, %(hiring_manager_email)s, %(hiring_manager_linkedin)s,
                  %(ai_generated_email)s,
                  %(ai_job_match_score)s, %(ai_priority_tier)s, %(ai_tags)s, %(ai_reasoning)s,
                  %(metadata)s
                )
                ON CONFLICT (job_url) DO UPDATE SET
                  status = EXCLUDED.status,
                  application_method = EXCLUDED.application_method,
                  hiring_manager_name = COALESCE(EXCLUDED.hiring_manager_name, job_applications.hiring_manager_name),
                  hiring_manager_email = COALESCE(EXCLUDED.hiring_manager_email, job_applications.hiring_manager_email),
                  hiring_manager_linkedin = COALESCE(EXCLUDED.hiring_manager_linkedin, job_applications.hiring_manager_linkedin),
                  ai_generated_email = COALESCE(EXCLUDED.ai_generated_email, job_applications.ai_generated_email),
                  updated_at = NOW()
                RETURNING id
                """,
                {
                    "job_title": payload.get("job_title"),
                    "company": payload.get("company"),
                    "company_domain": payload.get("company_domain"),
                    "job_url": payload.get("job_url"),
                    "job_description": payload.get("job_description"),
                    "source_board": payload.get("source_board"),
                    "location": payload.get("location"),
                    "is_remote": payload.get("is_remote", True),
                    "application_method": method,
                    "status": status,
                    "hiring_manager_name": payload.get("hiring_manager_name") or payload.get("hm_name"),
                    "hiring_manager_email": (payload.get("hiring_manager_email") or "").lower() or None,
                    "hiring_manager_linkedin": payload.get("hiring_manager_linkedin") or payload.get("hm_linkedin"),
                    "ai_generated_email": Json(payload["ai_generated_email"]) if payload.get("ai_generated_email") else None,
                    "ai_job_match_score": payload.get("ai_job_match_score"),
                    "ai_priority_tier": payload.get("ai_priority_tier"),
                    "ai_tags": payload.get("ai_tags") or [],
                    "ai_reasoning": payload.get("ai_reasoning"),
                    "metadata": Json(payload.get("metadata") or {}),
                },
            )
            job_id = cur.fetchone()["id"]

            message_id = payload.get("message_id")
            if message_id and method == "email":
                cur.execute(
                    """
                    INSERT INTO sent_messages (job_id, message_id, subject, to_email, kind)
                    VALUES (%s, %s, %s, %s, 'application')
                    ON CONFLICT (message_id) DO NOTHING
                    """,
                    (
                        job_id,
                        message_id.strip("<>"),
                        (payload.get("ai_generated_email") or {}).get("subject"),
                        payload.get("hiring_manager_email"),
                    ),
                )
        conn.commit()
    finally:
        conn.close()

    return {"ok": True, "id": str(job_id), "method": method, "status": status}


def cmd_record_followup(payload: dict) -> dict:
    job_id = payload["job_id"]
    conn = pg_conn()
    try:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute(
                """
                INSERT INTO follow_ups (job_id, email_subject, email_body)
                VALUES (%s, %s, %s)
                RETURNING id
                """,
                (job_id, payload.get("subject"), payload.get("body")),
            )
            fu_id = cur.fetchone()["id"]

            message_id = payload.get("message_id")
            if message_id:
                cur.execute(
                    """
                    INSERT INTO sent_messages (job_id, message_id, subject, to_email, kind)
                    VALUES (%s, %s, %s, %s, 'follow_up')
                    ON CONFLICT (message_id) DO NOTHING
                    """,
                    (
                        job_id,
                        message_id.strip("<>"),
                        payload.get("subject"),
                        payload.get("to_email"),
                    ),
                )

            cur.execute(
                """
                UPDATE job_applications
                SET follow_up_count = follow_up_count + 1,
                    last_follow_up_at = NOW()
                WHERE id = %s
                """,
                (job_id,),
            )
        conn.commit()
    finally:
        conn.close()
    return {"ok": True, "follow_up_id": str(fu_id), "job_id": job_id}


def cmd_save_research(payload: dict) -> dict:
    job_url = payload["job_url"]
    research = payload.get("research") or payload
    conn = pg_conn()
    try:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute("SELECT id FROM job_applications WHERE job_url = %s", (job_url,))
            row = cur.fetchone()
            if not row:
                return {"ok": False, "error": "job_application not found for job_url"}
            job_id = row["id"]

            cur.execute(
                """
                INSERT INTO company_research (
                  job_id, company, website, linkedin, twitter, github,
                  hq_location, company_size, funding_stage, industry,
                  one_liner, summary, tech_stack, raw_html_excerpt
                ) VALUES (
                  %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s
                )
                ON CONFLICT (job_id) DO UPDATE SET
                  website = EXCLUDED.website,
                  linkedin = EXCLUDED.linkedin,
                  twitter = EXCLUDED.twitter,
                  github = EXCLUDED.github,
                  hq_location = EXCLUDED.hq_location,
                  company_size = EXCLUDED.company_size,
                  funding_stage = EXCLUDED.funding_stage,
                  industry = EXCLUDED.industry,
                  one_liner = EXCLUDED.one_liner,
                  summary = EXCLUDED.summary,
                  tech_stack = EXCLUDED.tech_stack,
                  raw_html_excerpt = EXCLUDED.raw_html_excerpt,
                  researched_at = NOW()
                RETURNING id
                """,
                (
                    job_id,
                    research.get("company"),
                    research.get("website"),
                    research.get("linkedin"),
                    research.get("twitter"),
                    research.get("github"),
                    research.get("hq_location"),
                    research.get("size_hint"),
                    research.get("funding_hint"),
                    research.get("industry"),
                    research.get("one_liner"),
                    research.get("summary"),
                    research.get("tech_stack") or [],
                    research.get("raw_html_excerpt"),
                ),
            )
            research_id = cur.fetchone()["id"]
        conn.commit()
    finally:
        conn.close()
    return {"ok": True, "id": str(research_id), "job_id": str(job_id)}


def cmd_log_execution(payload: dict) -> dict:
    conn = pg_conn()
    try:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute(
                """
                INSERT INTO execution_logs (workflow_name, execution_id, status, message, metadata)
                VALUES (%s, %s, %s, %s, %s)
                RETURNING id
                """,
                (
                    payload.get("workflow_name") or "unknown",
                    payload.get("execution_id"),
                    payload.get("status") or "info",
                    payload.get("message"),
                    Json(payload.get("metadata") or {}),
                ),
            )
            row = cur.fetchone()
        conn.commit()
    finally:
        conn.close()
    return {"ok": True, "id": str(row["id"]) if row else None}


def cmd_log_rejected(payload: dict) -> dict:
    job_url = payload.get("job_url")
    if not job_url:
        return {"ok": False, "error": "missing job_url"}
    conn = pg_conn()
    try:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute(
                """
                INSERT INTO rejected_jobs (job_url, job_title, company, source_board, reject_reason, reject_details)
                VALUES (%s, %s, %s, %s, %s, %s)
                ON CONFLICT (job_url) DO NOTHING
                RETURNING id
                """,
                (
                    job_url,
                    payload.get("job_title"),
                    payload.get("company"),
                    payload.get("source_board"),
                    payload.get("reject_reason"),
                    Json(payload.get("reject_details") or {}),
                ),
            )
            row = cur.fetchone()
        conn.commit()
    finally:
        conn.close()
    return {"ok": True, "id": str(row["id"]) if row else None}


NAMED_QUERIES: dict[str, str] = {
    "job_exists": """
        SELECT (
          job_exists(%(job_url)s)
          OR job_fuzzy_exists(%(company)s, %(job_title)s)
        ) AS exists
    """,

    "today_stats": """
        WITH today AS (
          SELECT * FROM job_applications WHERE DATE(applied_at) = CURRENT_DATE
        ),
        week AS (
          SELECT * FROM job_applications WHERE applied_at >= NOW() - INTERVAL '7 days'
        ),
        all_apps AS (
          SELECT * FROM job_applications
        )
        SELECT
          (SELECT COUNT(*) FROM today)                                                        AS total_today,
          (SELECT COUNT(*) FILTER (WHERE application_method IN ('easy_apply','manual_easy_apply')) FROM today) AS easy_apply_count,
          (SELECT COUNT(*) FILTER (WHERE application_method='email') FROM today)              AS email_count,
          (SELECT COUNT(*) FILTER (WHERE application_method='manual') FROM today)             AS manual_count,
          (SELECT COUNT(*) FILTER (WHERE ai_priority_tier=1) FROM today)                      AS tier1_count,
          (SELECT COUNT(*) FILTER (WHERE ai_priority_tier=2) FROM today)                      AS tier2_count,
          (SELECT ARRAY_AGG(DISTINCT company) FROM today)                                     AS companies,
          (SELECT COUNT(*) FROM week)                                                         AS week_total,
          (SELECT COUNT(*) FILTER (WHERE application_method IN ('easy_apply','manual_easy_apply')) FROM week) AS week_easy_apply,
          (SELECT COUNT(*) FILTER (WHERE application_method='email') FROM week)               AS week_email,
          (SELECT COUNT(*) FILTER (WHERE application_method='manual') FROM week)              AS week_manual,
          (SELECT COUNT(*) FILTER (WHERE ai_priority_tier=1) FROM week)                       AS week_tier1,
          (SELECT COUNT(*) FILTER (WHERE ai_priority_tier=2) FROM week)                       AS week_tier2,
          (SELECT COUNT(*) FILTER (WHERE response_received_at IS NOT NULL) FROM week)         AS week_responses,
          COALESCE((SELECT ROUND(
            100.0 * COUNT(*) FILTER (WHERE response_received_at IS NOT NULL)
                  / NULLIF(COUNT(*), 0), 1
          ) FROM all_apps), 0)                                                                AS response_rate
    """,

    "source_performance": """
        SELECT source_board, total_jobs, tier1_jobs, response_rate
          FROM source_performance
         ORDER BY total_jobs DESC
         LIMIT 10
    """,

    "jobs_by_keyword": """
        SELECT
          ja.job_title,
          ja.company,
          ja.company_domain,
          ja.job_url,
          ja.source_board,
          ja.location,
          ja.application_method,
          ja.status,
          ja.applied_at,
          ja.hiring_manager_email,
          ja.hiring_manager_name,
          ja.ai_priority_tier,
          ja.ai_job_match_score,
          ja.ai_tags,
          cr.one_liner,
          cr.industry,
          cr.website,
          cr.linkedin       AS company_linkedin,
          cr.tech_stack
        FROM job_applications ja
        LEFT JOIN company_research cr ON cr.job_id = ja.id
        WHERE LOWER(ja.job_title) LIKE %(pat)s
           OR LOWER(ja.company) LIKE %(pat)s
           OR LOWER(COALESCE(ja.job_description, '')) LIKE %(pat)s
           OR EXISTS (SELECT 1 FROM unnest(COALESCE(ja.ai_tags, ARRAY[]::TEXT[])) t WHERE LOWER(t) LIKE %(pat)s)
           OR EXISTS (SELECT 1 FROM unnest(COALESCE(cr.tech_stack, ARRAY[]::TEXT[])) t WHERE LOWER(t) LIKE %(pat)s)
           OR LOWER(COALESCE(cr.industry, '')) LIKE %(pat)s
        ORDER BY ja.ai_priority_tier ASC NULLS LAST, ja.applied_at DESC
        LIMIT 30
    """,

    "weekly_jobs": """
        SELECT
          ja.job_title,
          ja.company,
          ja.company_domain,
          ja.job_url,
          ja.source_board,
          ja.location,
          ja.application_method,
          ja.status,
          ja.applied_at,
          ja.hiring_manager_email,
          ja.hiring_manager_name,
          ja.hiring_manager_linkedin,
          ja.ai_priority_tier,
          ja.ai_job_match_score,
          ja.ai_tags,
          ja.response_received_at,
          ja.response_type,
          cr.one_liner,
          cr.industry,
          cr.summary,
          cr.website,
          cr.linkedin       AS company_linkedin,
          cr.twitter,
          cr.github,
          cr.hq_location,
          cr.tech_stack
        FROM job_applications ja
        LEFT JOIN company_research cr ON cr.job_id = ja.id
        WHERE ja.applied_at >= NOW() - INTERVAL '7 days'
        ORDER BY ja.ai_priority_tier ASC NULLS LAST, ja.applied_at DESC
    """,

    "weekly_digest": """
        WITH week_apps AS (
          SELECT * FROM job_applications
           WHERE applied_at >= NOW() - INTERVAL '7 days'
        ),
        sources AS (
          SELECT
            source_board,
            COUNT(*)                                                                   AS total_jobs,
            COUNT(*) FILTER (WHERE ai_priority_tier = 1)                               AS tier1_jobs,
            COUNT(*) FILTER (WHERE application_method = 'email')                       AS email_sent,
            COUNT(*) FILTER (WHERE application_method IN ('easy_apply','manual_easy_apply')) AS easy_apply,
            COUNT(*) FILTER (WHERE application_method = 'manual')                      AS manual,
            COUNT(*) FILTER (WHERE response_received_at IS NOT NULL)                   AS responses,
            COALESCE(ROUND(
              100.0 * COUNT(*) FILTER (WHERE response_received_at IS NOT NULL)
                    / NULLIF(COUNT(*), 0), 1
            ), 0)                                                                       AS response_rate
          FROM week_apps
          GROUP BY source_board
          ORDER BY total_jobs DESC
        ),
        totals AS (
          SELECT
            COUNT(*)                                                                    AS total,
            COUNT(*) FILTER (WHERE ai_priority_tier = 1)                                AS tier1,
            COUNT(*) FILTER (WHERE ai_priority_tier = 2)                                AS tier2,
            COUNT(*) FILTER (WHERE application_method = 'email')                        AS email_sent,
            COUNT(*) FILTER (WHERE application_method IN ('easy_apply','manual_easy_apply')) AS easy_apply,
            COUNT(*) FILTER (WHERE application_method = 'manual')                       AS manual,
            COUNT(*) FILTER (WHERE response_received_at IS NOT NULL)                    AS responses
          FROM week_apps
        ),
        top_companies AS (
          SELECT company, COUNT(*) AS n
          FROM week_apps
          GROUP BY company
          ORDER BY n DESC
          LIMIT 10
        )
        SELECT
          (SELECT row_to_json(t) FROM totals t)                                          AS totals,
          (SELECT COALESCE(json_agg(s), '[]'::json) FROM sources s)                      AS sources,
          (SELECT COALESCE(json_agg(c), '[]'::json) FROM top_companies c)                AS top_companies
    """,

    "awaiting_followup": """
        SELECT id, job_title, company, hiring_manager_email, applied_at,
               follow_up_count, last_follow_up_at,
               EXTRACT(DAY FROM NOW() - COALESCE(last_follow_up_at, applied_at))::INT
                 AS days_since_contact
          FROM job_applications
         WHERE application_method = 'email'
           AND hiring_manager_email IS NOT NULL
           AND response_received_at IS NULL
           AND status NOT IN ('rejected', 'ghosted')
           AND follow_up_count < %(max_follow_ups)s
           AND COALESCE(last_follow_up_at, applied_at)
                 < NOW() - (%(follow_up_after_days)s || ' days')::INTERVAL
         ORDER BY ai_priority_tier ASC NULLS LAST, applied_at ASC
         LIMIT 5
    """,

    "needs_manual_review": """
        SELECT * FROM needs_manual_review LIMIT 15
    """,

    "workflow_health": """
        SELECT * FROM workflow_health ORDER BY workflow_name
    """,

    "recent_errors": """
        SELECT workflow_name, status, message, metadata, created_at
          FROM execution_logs
         WHERE status = 'error'
           AND created_at > NOW() - INTERVAL '7 days'
         ORDER BY created_at DESC
         LIMIT 20
    """,
}


def cmd_query(payload: dict) -> dict:
    name = payload.get("name")
    if name not in NAMED_QUERIES:
        return {"ok": False, "error": f"unknown query: {name}", "available": list(NAMED_QUERIES)}

    args = payload.get("args", {}) or {}
    args.setdefault("max_follow_ups", int(os.getenv("MAX_FOLLOW_UPS", "2")))
    args.setdefault("follow_up_after_days", int(os.getenv("FOLLOW_UP_AFTER_DAYS", "7")))

    conn = pg_conn()
    try:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute(NAMED_QUERIES[name], args)
            rows = [dict(r) for r in cur.fetchall()]
    finally:
        conn.close()
    return {"ok": True, "rows": rows, "count": len(rows)}


def cmd_save_opportunity(payload: dict) -> dict:
    conn = pg_conn()
    try:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute(
                """
                INSERT INTO opensource_opportunities
                  (title, repository, url, description, bounty_amount, matched_skills,
                   language, stars, relevance_score, source, metadata)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                ON CONFLICT (url) DO UPDATE SET
                  relevance_score = EXCLUDED.relevance_score,
                  bounty_amount   = EXCLUDED.bounty_amount,
                  matched_skills  = EXCLUDED.matched_skills,
                  metadata        = EXCLUDED.metadata
                RETURNING id
                """,
                (
                    payload.get("title"),
                    payload.get("repository"),
                    payload.get("url"),
                    payload.get("description"),
                    payload.get("bounty_amount"),
                    payload.get("matched_skills") or [],
                    payload.get("language"),
                    payload.get("stars"),
                    payload.get("relevance_score"),
                    payload.get("source"),
                    Json(payload.get("metadata") or {}),
                ),
            )
            row = cur.fetchone()
        conn.commit()
    finally:
        conn.close()
    return {"ok": True, "id": str(row["id"]) if row else None}


COMMANDS = {
    "record-application": cmd_record_application,
    "record-followup": cmd_record_followup,
    "save-research": cmd_save_research,
    "save-opportunity": cmd_save_opportunity,
    "log-rejected": cmd_log_rejected,
    "log-execution": cmd_log_execution,
    "query": cmd_query,
}


def main() -> None:
    parser = argparse.ArgumentParser(description="jHound DB helper")
    parser.add_argument("command", choices=list(COMMANDS.keys()))
    args = parser.parse_args()

    payload = _read_input()
    try:
        result = COMMANDS[args.command](payload)
    except Exception as exc:
        _emit({"ok": False, "error": str(exc)})
        sys.exit(1)
    _emit(result)


if __name__ == "__main__":
    main()
