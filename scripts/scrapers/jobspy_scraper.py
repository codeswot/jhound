#!/usr/bin/env python3
from __future__ import annotations

import argparse
import math
import os
import sys

from _common import clean, emit_jobs, now_iso

SITE_BOARD = {
    "linkedin": "LinkedIn",
    "indeed": "Indeed",
    "glassdoor": "Glassdoor",
    "zip_recruiter": "ZipRecruiter",
    "google": "GoogleJobs",
    "bayt": "Bayt",
    "naukri": "Naukri",
}


def _sanitise(val):
    if val is None:
        return None
    try:
        f = float(val)
        if math.isnan(f) or math.isinf(f):
            return None
        return val
    except (ValueError, TypeError):
        return str(val) if val is not None else None


def _safe_str(val, default=""):
    if val is None:
        return default
    try:
        s = str(val)
        return default if s.lower() in ("nat", "nan", "none", "null") else s
    except Exception:
        return default


def scrape(sites: list[str], keywords: list[str], results_per_keyword: int, hours_old: int | None, proxies: list[str] | None) -> list[dict]:
    try:
        from jobspy import scrape_jobs
    except ImportError:
        print("python-jobspy not installed", file=sys.stderr)
        return []

    rows: list[dict] = []
    seen: set[str] = set()

    for kw in keywords:
        try:
            df = scrape_jobs(
                site_name=sites,
                search_term=kw,
                google_search_term=f"{kw} remote jobs",
                location="Remote",
                is_remote=True,
                results_wanted=results_per_keyword,
                hours_old=hours_old,
                country_indeed="USA",
                linkedin_fetch_description=True,
                proxies=proxies or None,
                verbose=0,
            )
        except Exception as exc:
            print(f"jobspy {kw} failed: {exc}", file=sys.stderr)
            continue

        if df is None or df.empty:
            continue

        for _, r in df.iterrows():
            job_url = _safe_str(r.get("job_url") or r.get("job_url_direct")).strip()
            if not job_url or job_url in seen:
                continue
            seen.add(job_url)

            site = str(r.get("site") or "").lower()
            is_remote = bool(r.get("is_remote")) if r.get("is_remote") is not None else True
            location = _safe_str(r.get("location"), "Remote").strip() or "Remote"

            rows.append({
                "job_title": clean(r.get("title"), 200),
                "company": clean(r.get("company"), 200),
                "location": clean(location, 200),
                "job_description": clean(r.get("description") or "", 5000),
                "job_url": job_url,
                "source_board": SITE_BOARD.get(site, site or "JobSpy"),
                "has_easy_apply": bool(r.get("listing_type") == "easy_apply") if site == "linkedin" else False,
                "is_remote": is_remote,
                "search_keyword": kw,
                "scraped_at": now_iso(),
                "company_url": _sanitise(r.get("company_url")),
                "salary_min": _sanitise(r.get("min_amount")),
                "salary_max": _sanitise(r.get("max_amount")),
                "salary_currency": _sanitise(r.get("currency")),
                "date_posted": _safe_str(r.get("date_posted")) or None,
            })

    return rows


def main() -> None:
    parser = argparse.ArgumentParser(description="Multi-board remote-job scraper via JobSpy")
    parser.add_argument("--sites", nargs="+",
                        default=["linkedin", "indeed", "glassdoor", "zip_recruiter", "google"],
                        choices=list(SITE_BOARD.keys()))
    parser.add_argument("--keywords", nargs="+", required=True)
    parser.add_argument("--results-per-keyword", type=int, default=25)
    parser.add_argument("--hours-old", type=int, default=168, help="Only jobs posted in last N hours (default 7 days)")
    parser.add_argument("--proxies", nargs="*", default=None,
                        help="Optional proxy list (user:pass@host:port). Defaults to JOBSPY_PROXIES env.")
    args = parser.parse_args()

    proxies = args.proxies
    if proxies is None:
        env_proxies = os.getenv("JOBSPY_PROXIES", "").strip()
        proxies = [p.strip() for p in env_proxies.split(",") if p.strip()] or None

    emit_jobs(scrape(args.sites, args.keywords, args.results_per_keyword, args.hours_old, proxies))


if __name__ == "__main__":
    main()
