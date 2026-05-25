#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path

import psycopg2
import requests
from psycopg2.extras import RealDictCursor

sys.path.insert(0, str(Path(__file__).resolve().parent / "ai"))
from response_classifier import classify  # noqa: E402

RESEND_API_KEY = os.getenv("RESEND_API_KEY", "")
RESEND_BASE = "https://api.resend.com"


def _env(name: str) -> str:
    v = os.getenv(name)
    if not v:
        raise RuntimeError(f"Missing env: {name}")
    return v


def pg_conn():
    return psycopg2.connect(
        host=os.getenv("POSTGRES_HOST", "postgres"),
        port=int(os.getenv("POSTGRES_PORT", "5432")),
        dbname=os.getenv("POSTGRES_DB", "jhound"),
        user=os.getenv("POSTGRES_USER", "jhound"),
        password=os.getenv("POSTGRES_PASSWORD", ""),
    )


def fetch_email(email_id: str) -> dict:
    if not RESEND_API_KEY:
        raise RuntimeError("RESEND_API_KEY not set")
    r = requests.get(
        f"{RESEND_BASE}/emails/receiving/{email_id}",
        headers={"Authorization": f"Bearer {RESEND_API_KEY}"},
        timeout=20,
    )
    r.raise_for_status()
    return r.json()


def list_received(limit: int = 20) -> list[dict]:
    r = requests.get(
        f"{RESEND_BASE}/emails/receiving?limit={limit}",
        headers={"Authorization": f"Bearer {RESEND_API_KEY}"},
        timeout=20,
    )
    r.raise_for_status()
    data = r.json()
    return data.get("data") if isinstance(data, dict) else data or []


def match_job(cur, from_email: str, in_reply_to: str | None, references: str | None, subject: str) -> dict | None:
    candidates: list[str] = []
    if in_reply_to:
        candidates.append(in_reply_to.strip("<>"))
    if references:
        candidates.extend(ref.strip("<>") for ref in references.split() if ref.strip())

    if candidates:
        cur.execute(
            "SELECT ja.* FROM job_applications ja JOIN sent_messages sm ON sm.job_id = ja.id "
            "WHERE sm.message_id = ANY(%s) LIMIT 1",
            (candidates,),
        )
        row = cur.fetchone()
        if row:
            return dict(row)

    if from_email:
        cur.execute(
            "SELECT * FROM job_applications WHERE LOWER(hiring_manager_email) = LOWER(%s) "
            "ORDER BY applied_at DESC LIMIT 1",
            (from_email,),
        )
        row = cur.fetchone()
        if row:
            return dict(row)

        domain = from_email.split("@")[-1].lower() if "@" in from_email else ""
        if domain:
            cur.execute(
                "SELECT * FROM job_applications WHERE LOWER(company_domain) = %s "
                "AND response_received_at IS NULL "
                "ORDER BY applied_at DESC LIMIT 1",
                (domain,),
            )
            row = cur.fetchone()
            if row:
                return dict(row)

    if subject and subject.lower().startswith(("re:", "fwd:")):
        cur.execute(
            "SELECT * FROM job_applications WHERE response_received_at IS NULL "
            "AND %s ILIKE '%%' || company || '%%' ORDER BY applied_at DESC LIMIT 1",
            (subject,),
        )
        row = cur.fetchone()
        if row:
            return dict(row)

    return None


def already_recorded(cur, email_id: str) -> bool:
    cur.execute(
        "SELECT 1 FROM email_responses WHERE resend_email_id = %s LIMIT 1",
        (email_id,),
    )
    return cur.fetchone() is not None


def process_email(email_obj: dict) -> dict | None:
    email_id = email_obj.get("id") or email_obj.get("email_id")
    from_email = (email_obj.get("from") or "").lower()
    subject = email_obj.get("subject") or ""
    body = email_obj.get("text") or _strip_html(email_obj.get("html") or "")
    headers = email_obj.get("headers") or {}
    in_reply_to = email_obj.get("in_reply_to") or headers.get("In-Reply-To") or headers.get("in-reply-to")
    references = email_obj.get("references") or headers.get("References") or headers.get("references")

    conn = pg_conn()
    try:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            if email_id and already_recorded(cur, email_id):
                return None

            job = match_job(cur, from_email, in_reply_to, references, subject)
            if not job:
                return None

            try:
                cls = classify(from_email, subject, body)
            except Exception as exc:
                print(f"classify failed: {exc}", file=sys.stderr)
                cls = {"classification": "generic", "confidence": 0}

            classification = cls.get("classification", "generic")

            cur.execute(
                "INSERT INTO email_responses (job_id, from_email, subject, body, ai_classification, resend_email_id, received_at) "
                "VALUES (%s, %s, %s, %s, %s, %s, NOW()) "
                "ON CONFLICT (resend_email_id) DO NOTHING "
                "RETURNING id",
                (job["id"], from_email, subject[:500], body[:20000], classification, email_id),
            )
            row = cur.fetchone()
            if not row:
                return None
            response_id = row["id"]

            cur.execute(
                "UPDATE job_applications SET "
                "response_received_at = NOW(), response_type = %s, "
                "status = CASE WHEN %s = 'rejection' THEN 'rejected' "
                "             WHEN %s = 'interview' THEN 'interview' "
                "             WHEN %s = 'offer' THEN 'offer' "
                "             ELSE status END "
                "WHERE id = %s",
                (classification, classification, classification, classification, job["id"]),
            )
        conn.commit()
    finally:
        conn.close()

    return {
        "response_id": str(response_id),
        "job_id": str(job["id"]),
        "company": job["company"],
        "job_title": job["job_title"],
        "from_email": from_email,
        "subject": subject,
        "snippet": body[:500],
        "classification": classification,
        "confidence": cls.get("confidence"),
        "next_action": cls.get("next_action"),
    }


def _strip_html(html: str) -> str:
    import re
    return re.sub(r"<[^>]+>", " ", html)


def handle_webhook(payload: dict) -> dict | None:
    if payload.get("type") != "email.received":
        return None
    data = payload.get("data") or {}
    email_id = data.get("email_id")
    if not email_id:
        return None

    full = fetch_email(email_id)
    full.setdefault("email_id", full.get("id") or email_id)
    return process_email(full)


def main() -> None:
    parser = argparse.ArgumentParser(description="Resend inbound email handler")
    parser.add_argument("--input", help="Webhook payload JSON file (defaults to stdin)")
    parser.add_argument("--list", action="store_true", help="Backfill: list+process recent received emails")
    parser.add_argument("--limit", type=int, default=20)
    args = parser.parse_args()

    if args.list:
        results = []
        for stub in list_received(args.limit):
            email_id = stub.get("id") or stub.get("email_id")
            if not email_id:
                continue
            try:
                full = fetch_email(email_id)
                full.setdefault("email_id", email_id)
                alert = process_email(full)
                if alert:
                    results.append(alert)
            except Exception as exc:
                print(f"backfill error for {email_id}: {exc}", file=sys.stderr)
        json.dump(results, sys.stdout, ensure_ascii=False)
        sys.stdout.write("\n")
        return

    payload = json.load(open(args.input) if args.input else sys.stdin)
    result = handle_webhook(payload)
    if result is None:
        sys.stdout.write("null\n")
    else:
        json.dump(result, sys.stdout, ensure_ascii=False)
        sys.stdout.write("\n")


if __name__ == "__main__":
    main()
