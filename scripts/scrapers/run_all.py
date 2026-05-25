#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor, as_completed

HERE = os.path.dirname(os.path.abspath(__file__))


def run(cmd: list[str], timeout: int) -> list[dict]:
    try:
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
        if r.returncode != 0:
            print(f"[run_all] {cmd[1]} exit {r.returncode}: {r.stderr.strip()[:300]}", file=sys.stderr)
            return []
        out = (r.stdout or "").strip()
        if not out:
            return []
        data = json.loads(out)
        return data if isinstance(data, list) else []
    except subprocess.TimeoutExpired:
        print(f"[run_all] {cmd[1]} timed out after {timeout}s", file=sys.stderr)
        return []
    except json.JSONDecodeError as e:
        print(f"[run_all] {cmd[1]} JSON error: {e}", file=sys.stderr)
        return []
    except Exception as e:
        print(f"[run_all] {cmd[1]} failed: {e}", file=sys.stderr)
        return []


def dedupe_against_db(jobs: list[dict]) -> list[dict]:
    """Remove jobs already in the DB (URL or fuzzy title+company match). Single call per batch."""
    try:
        import psycopg2
        conn = psycopg2.connect(
            host=os.getenv("POSTGRES_HOST", "postgres"),
            port=int(os.getenv("POSTGRES_PORT", "5432")),
            dbname=os.getenv("POSTGRES_DB", "jhound"),
            user=os.getenv("POSTGRES_USER", "jhound"),
            password=os.getenv("POSTGRES_PASSWORD", ""),
        )
        cur = conn.cursor()
        new_jobs = []
        for job in jobs:
            url = job.get("job_url", "")
            if not url:
                new_jobs.append(job)
                continue
            cur.execute("SELECT job_exists(%s) AS e", (url,))
            row = cur.fetchone()
            if row and row[0]:
                continue
            new_jobs.append(job)
        conn.close()
        return new_jobs
    except Exception as exc:
        print(f"[run_all] dedupe failed (passing all through): {exc}", file=sys.stderr)
        return jobs


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--keywords", nargs="+", required=True)
    ap.add_argument("--jobspy-per-keyword", type=int, default=25)
    ap.add_argument("--jobspy-hours-old", type=int, default=168)
    ap.add_argument("--timeout", type=int, default=300)
    ap.add_argument("--skip", nargs="*", default=[], help="board groups to skip: jobspy, generic")
    ap.add_argument("--no-dedupe", action="store_true", help="Skip DB deduplication")
    args = ap.parse_args()

    jobs: dict[str, list[str]] = {
        "jobspy": ["python3", f"{HERE}/jobspy_scraper.py",
                   "--keywords", *args.keywords,
                   "--results-per-keyword", str(args.jobspy_per_keyword),
                   "--hours-old", str(args.jobspy_hours_old)],
        "generic": ["python3", f"{HERE}/generic_scraper.py", "--source", "all", "--keywords", *args.keywords],
    }
    for name in args.skip:
        jobs.pop(name, None)

    merged: list[dict] = []
    with ThreadPoolExecutor(max_workers=len(jobs)) as ex:
        futures = {ex.submit(run, cmd, args.timeout): name for name, cmd in jobs.items()}
        for fut in as_completed(futures):
            name = futures[fut]
            results = fut.result()
            print(f"[run_all] {name}: {len(results)} jobs", file=sys.stderr)
            merged.extend(results)

    if not args.no_dedupe:
        before = len(merged)
        merged = dedupe_against_db(merged)
        print(f"[run_all] dedupe: {before} → {len(merged)} jobs", file=sys.stderr)

    print(json.dumps(merged))


if __name__ == "__main__":
    main()
