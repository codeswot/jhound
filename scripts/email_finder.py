#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import sys
from datetime import datetime, timezone

import redis
import requests

REDIS_HOST = os.getenv("REDIS_HOST", "redis")
REDIS_PORT = int(os.getenv("REDIS_PORT", "6379"))

HUNTER_API_KEY = os.getenv("HUNTER_API_KEY", "")
HUNTER_MONTHLY_LIMIT = int(os.getenv("HUNTER_MONTHLY_LIMIT", "80"))
HUNTER_WEEKLY_LIMIT = int(os.getenv("HUNTER_WEEKLY_LIMIT", "20"))
HUNTER_DAILY_LIMIT = int(os.getenv("HUNTER_DAILY_LIMIT", "10"))
HUNTER_TIER1_ONLY = os.getenv("HUNTER_TIER1_ONLY", "true").lower() in {"1", "true", "yes"}
HUNTER_CACHE_DAYS = int(os.getenv("HUNTER_CACHE_DAYS", "30"))

APOLLO_API_KEY = os.getenv("APOLLO_API_KEY", "")
APOLLO_TIER1_ONLY = os.getenv("APOLLO_TIER1_ONLY", "false").lower() in {"1", "true", "yes"}
APOLLO_CACHE_DAYS = int(os.getenv("APOLLO_CACHE_DAYS", "30"))
APOLLO_MONTHLY_LIMIT = int(os.getenv("APOLLO_MONTHLY_LIMIT", "500"))

HIRING_TITLES = {
    "recruiter", "talent", "people", "hr", "hiring", "founder",
    "ceo", "cto", "head of engineering", "engineering manager",
    "vp engineering", "vp of engineering",
}

APOLLO_TITLES = [
    "recruiter", "talent acquisition", "head of talent", "people ops",
    "hiring manager", "engineering manager", "head of engineering",
    "vp engineering", "vp of engineering", "cto", "founder", "ceo",
]


def redis_client() -> redis.Redis:
    return redis.Redis(host=REDIS_HOST, port=REDIS_PORT, decode_responses=True)


def _quota_keys(prefix: str) -> tuple[str, str, str]:
    now = datetime.now(timezone.utc)
    iso_year, iso_week, _ = now.isocalendar()
    return (
        f"{prefix}:day:{now.strftime('%Y-%m-%d')}",
        f"{prefix}:week:{iso_year}-W{iso_week:02d}",
        f"{prefix}:month:{now.strftime('%Y-%m')}",
    )


def quota_status(rc: redis.Redis) -> dict:
    day_key, week_key, month_key = _quota_keys("hunter_usage")
    day_used = int(rc.get(day_key) or 0)
    week_used = int(rc.get(week_key) or 0)
    month_used = int(rc.get(month_key) or 0)
    return {
        "day_used": day_used,
        "day_limit": HUNTER_DAILY_LIMIT,
        "day_remaining": max(0, HUNTER_DAILY_LIMIT - day_used),
        "week_used": week_used,
        "week_limit": HUNTER_WEEKLY_LIMIT,
        "week_remaining": max(0, HUNTER_WEEKLY_LIMIT - week_used),
        "month_used": month_used,
        "month_limit": HUNTER_MONTHLY_LIMIT,
        "month_remaining": max(0, HUNTER_MONTHLY_LIMIT - month_used),
        "month_credits_used": round(month_used * 0.5, 1),
        "month_credits_remaining": round(max(0, HUNTER_MONTHLY_LIMIT - month_used) * 0.5, 1),
    }


def apollo_quota_status(rc: redis.Redis) -> dict:
    _, _, month_key = _quota_keys("apollo_usage")
    month_used = int(rc.get(month_key) or 0)
    return {
        "month_used": month_used,
        "month_limit": APOLLO_MONTHLY_LIMIT,
        "month_remaining": max(0, APOLLO_MONTHLY_LIMIT - month_used),
    }


def can_use_hunter(rc: redis.Redis, tier: int | None = None) -> bool:
    if not HUNTER_API_KEY:
        return False
    if HUNTER_TIER1_ONLY and tier is not None and tier != 1:
        return False
    s = quota_status(rc)
    return (
        s["day_used"] < HUNTER_DAILY_LIMIT
        and s["week_used"] < HUNTER_WEEKLY_LIMIT
        and s["month_used"] < HUNTER_MONTHLY_LIMIT
    )


def can_use_apollo(rc: redis.Redis, tier: int | None = None) -> bool:
    if not APOLLO_API_KEY:
        return False
    if APOLLO_TIER1_ONLY and tier is not None and tier != 1:
        return False
    s = apollo_quota_status(rc)
    return s["month_used"] < APOLLO_MONTHLY_LIMIT


def use_hunter_quota(rc: redis.Redis, n: int = 1) -> None:
    day_key, week_key, month_key = _quota_keys("hunter_usage")
    for _ in range(n):
        rc.incr(day_key)
        rc.incr(week_key)
        rc.incr(month_key)
    rc.expire(day_key, 86400)
    rc.expire(week_key, 86400 * 8)
    rc.expire(month_key, 86400 * 32)


def use_apollo_quota(rc: redis.Redis, n: int = 1) -> None:
    _, _, month_key = _quota_keys("apollo_usage")
    for _ in range(n):
        rc.incr(month_key)
    rc.expire(month_key, 86400 * 32)


def cached_get(rc: redis.Redis, key: str) -> dict | None:
    raw = rc.get(key)
    return json.loads(raw) if raw else None


def cached_set(rc: redis.Redis, key: str, value: dict, days: int = HUNTER_CACHE_DAYS) -> None:
    rc.setex(key, 86400 * days, json.dumps(value))


def hunter_domain_search(domain: str, seniority: str = "senior,executive", department: str = "hr,engineering,management,executive") -> dict:
    try:
        resp = requests.get(
            "https://api.hunter.io/v2/domain-search",
            params={
                "domain": domain,
                "api_key": HUNTER_API_KEY,
                "seniority": seniority,
                "department": department,
                "limit": 25,
            },
            timeout=20,
        )
        if resp.status_code != 200:
            return {"ok": False, "status_code": resp.status_code, "error": resp.text[:300]}
        return {"ok": True, "data": resp.json().get("data", {})}
    except Exception as exc:
        return {"ok": False, "error": str(exc)}


def hunter_email_finder(domain: str, first: str, last: str) -> dict:
    try:
        resp = requests.get(
            "https://api.hunter.io/v2/email-finder",
            params={
                "domain": domain,
                "first_name": first,
                "last_name": last,
                "api_key": HUNTER_API_KEY,
            },
            timeout=20,
        )
        if resp.status_code != 200:
            return {"ok": False, "status_code": resp.status_code}
        return {"ok": True, "data": resp.json().get("data", {})}
    except Exception as exc:
        return {"ok": False, "error": str(exc)}


def apollo_people_search(domain: str, limit: int = 10) -> dict:
    try:
        resp = requests.post(
            "https://api.apollo.io/v1/contacts/search",
            json={
                "q_organization_domains": [domain],
                "person_titles": APOLLO_TITLES,
                "page": 1,
                "per_page": limit,
            },
            headers={
                "Content-Type": "application/json",
                "Cache-Control": "no-cache",
                "X-Api-Key": APOLLO_API_KEY,
            },
            timeout=20,
        )
        if resp.status_code != 200:
            return {"ok": False, "status_code": resp.status_code, "error": resp.text[:300]}
        data = resp.json()
        contacts = data.get("contacts") or []
        return {"ok": True, "data": {"people": contacts}}
    except Exception as exc:
        return {"ok": False, "error": str(exc)}


def _rank_hunter_emails(emails: list[dict]) -> list[dict]:
    ranked: list[dict] = []
    for e in emails or []:
        position = (e.get("position") or "").lower()
        is_hiring = any(t in position for t in HIRING_TITLES)
        confidence = int(e.get("confidence") or 0)
        score = confidence + (40 if is_hiring else 0)
        ranked.append({
            "email": e.get("value"),
            "first_name": e.get("first_name"),
            "last_name": e.get("last_name"),
            "position": e.get("position"),
            "linkedin": e.get("linkedin"),
            "confidence": confidence,
            "is_hiring_role": is_hiring,
            "_score": score,
        })
    ranked.sort(key=lambda x: x["_score"], reverse=True)
    return ranked


def _rank_apollo_people(people: list[dict]) -> list[dict]:
    ranked: list[dict] = []
    for p in people or []:
        title = (p.get("title") or "").lower()
        is_hiring = any(t in title for t in HIRING_TITLES)
        ranked.append({
            "first_name": p.get("first_name"),
            "last_name": p.get("last_name"),
            "title": p.get("title"),
            "email": p.get("email"),
            "email_status": p.get("email_status"),
            "linkedin_url": p.get("linkedin_url"),
            "is_hiring_role": is_hiring,
            "_score": 100 if is_hiring else 50,
        })
    ranked.sort(key=lambda x: x["_score"], reverse=True)
    return ranked


def find_by_domain(domain: str, tier: int | None = None) -> dict:
    rc = redis_client()
    result = {
        "email": None,
        "confidence": 0,
        "method": None,
        "first_name": None,
        "last_name": None,
        "position": None,
        "alternatives": [],
        "hunter_used": False,
        "quota": quota_status(rc),
        "tier": tier,
    }

    cache_key = f"hunter_domain:{domain.lower()}"
    cached = cached_get(rc, cache_key)
    if cached:
        result["hunter_cache_hit"] = True
        ranked = cached.get("ranked") or []
    else:
        if not can_use_hunter(rc, tier=tier):
            result["hunter_skipped_reason"] = _hunter_skip_reason(rc, tier)
            return result

        api_result = hunter_domain_search(domain)
        use_hunter_quota(rc, n=1)
        result["hunter_used"] = True
        result["quota"] = quota_status(rc)
        if not api_result.get("ok"):
            result["error"] = api_result.get("error") or f"hunter status {api_result.get('status_code')}"
            return result

        data = api_result.get("data") or {}
        ranked = _rank_hunter_emails(data.get("emails", []))
        cached_set(rc, cache_key, {"ranked": ranked, "domain": domain})

    if not ranked:
        return result

    top = ranked[0]
    result.update(
        email=top["email"],
        confidence=top["confidence"],
        method="hunter_domain_search",
        first_name=top.get("first_name"),
        last_name=top.get("last_name"),
        position=top.get("position"),
        alternatives=[r["email"] for r in ranked[1:5] if r.get("email")],
    )
    return result


def find_by_name(first: str, last: str, domain: str, tier: int | None = None) -> dict:
    rc = redis_client()
    result = {
        "email": None,
        "confidence": 0,
        "method": None,
        "alternatives": [],
        "hunter_used": False,
        "pattern_guesses": [],
        "quota": quota_status(rc),
        "tier": tier,
    }

    cache_key = f"hunter_finder:{first.lower()}:{last.lower()}:{domain.lower()}"
    cached = cached_get(rc, cache_key)
    if cached:
        result.update(cached)
        result["hunter_cache_hit"] = True
        result["quota"] = quota_status(rc)
        return result

    if not can_use_hunter(rc, tier=tier):
        result["hunter_skipped_reason"] = _hunter_skip_reason(rc, tier)
    else:
        api_result = hunter_email_finder(domain, first, last)
        use_hunter_quota(rc, n=1)
        result["hunter_used"] = True
        result["quota"] = quota_status(rc)
        if api_result.get("ok"):
            data = api_result["data"] or {}
            email = data.get("email")
            if email:
                payload = {
                    "email": email,
                    "confidence": int(data.get("score") or 0),
                    "method": "hunter_email_finder",
                }
                result.update(payload)
                cached_set(rc, cache_key, payload)
                return result

    result["pattern_guesses"] = [
        {"email": f"{first.lower()}.{last.lower()}@{domain}", "confidence": 30},
        {"email": f"{first.lower()[0]}{last.lower()}@{domain}", "confidence": 25},
        {"email": f"{first.lower()}{last.lower()}@{domain}", "confidence": 20},
    ]
    return result


def find_smart(domain: str, tier: int | None = None) -> dict:
    """Apollo → Hunter email-finder → Hunter domain-search."""
    rc = redis_client()

    apollo_cache_key = f"apollo_people:{domain.lower()}"
    cached = cached_get(rc, apollo_cache_key)

    if cached:
        ranked = cached.get("ranked") or []
        apollo_meta = {"hit": "apollo_cache"}
    elif can_use_apollo(rc, tier=tier):
        api_result = apollo_people_search(domain)
        use_apollo_quota(rc, n=1)
        if api_result.get("ok"):
            ranked = _rank_apollo_people(api_result["data"].get("people", []))
            cached_set(rc, apollo_cache_key, {"ranked": ranked, "domain": domain}, days=APOLLO_CACHE_DAYS)
            apollo_meta = {"hit": "apollo_live"}
        else:
            ranked = []
            apollo_meta = {"hit": "apollo_error", "error": api_result.get("error")}
    else:
        ranked = []
        apollo_meta = {"hit": "apollo_skipped", "reason": _apollo_skip_reason(rc, tier)}

    if ranked:
        top = ranked[0]
        first = top.get("first_name")
        last = top.get("last_name")

        if top.get("email") and top.get("email_status") == "verified":
            return {
                "email": top["email"],
                "confidence": 90,
                "method": "apollo_verified",
                "hm_name": f"{first or ''} {last or ''}".strip() or None,
                "hm_position": top.get("title"),
                "hm_linkedin": top.get("linkedin_url"),
                "resolver": "apollo",
                "apollo": apollo_meta,
                "quota": quota_status(rc),
                "apollo_quota": apollo_quota_status(rc),
                "tier": tier,
            }

        if first and last:
            sub = find_by_name(first, last, domain, tier=tier)
            sub["hm_name"] = f"{first} {last}"
            sub["hm_position"] = top.get("title")
            sub["hm_linkedin"] = top.get("linkedin_url")
            sub["resolver"] = "apollo_then_hunter_finder"
            sub["apollo"] = apollo_meta
            sub["apollo_quota"] = apollo_quota_status(rc)
            if sub.get("email"):
                return sub

    sub = find_by_domain(domain, tier=tier)
    sub["resolver"] = "hunter_domain_search"
    sub["apollo"] = apollo_meta
    sub["apollo_quota"] = apollo_quota_status(rc)
    return sub


def _hunter_skip_reason(rc: redis.Redis, tier: int | None) -> str:
    if not HUNTER_API_KEY:
        return "no_api_key"
    if HUNTER_TIER1_ONLY and tier is not None and tier != 1:
        return "tier_gate"
    s = quota_status(rc)
    if s["day_used"] >= HUNTER_DAILY_LIMIT:
        return "daily_quota_exhausted"
    if s["week_used"] >= HUNTER_WEEKLY_LIMIT:
        return "weekly_quota_exhausted"
    return "monthly_quota_exhausted"


def _apollo_skip_reason(rc: redis.Redis, tier: int | None) -> str:
    if not APOLLO_API_KEY:
        return "no_api_key"
    if APOLLO_TIER1_ONLY and tier is not None and tier != 1:
        return "tier_gate"
    return "monthly_quota_exhausted"


def main() -> None:
    parser = argparse.ArgumentParser(description="Find hiring-manager email (Apollo → Hunter, no browser)")
    parser.add_argument("--first-name")
    parser.add_argument("--last-name")
    parser.add_argument("--company")
    parser.add_argument("--domain")
    parser.add_argument("--tier", type=int, help="AI priority tier (1 or 2). Gates Hunter when HUNTER_TIER1_ONLY=true.")
    parser.add_argument("--mode", choices=["smart", "by-name", "by-domain"], default="smart",
                        help="smart (default): Apollo → Hunter chain. by-name/by-domain: skip Apollo.")
    parser.add_argument("--quota", action="store_true", help="Print current Hunter + Apollo quota status and exit.")
    parser.add_argument("--jd-email", help="Email extracted from job description. If set, short-circuit and emit it without API calls.")
    args = parser.parse_args()

    if args.quota:
        rc = redis_client()
        json.dump({"hunter": quota_status(rc), "apollo": apollo_quota_status(rc)}, sys.stdout, ensure_ascii=False)
        sys.stdout.write("\n")
        return

    if args.jd_email:
        json.dump({
            "email": args.jd_email,
            "confidence": 100,
            "method": "jd_extract",
            "hm_name": None,
            "hm_position": None,
            "hm_linkedin": None,
            "resolver": "jd_extract",
        }, sys.stdout, ensure_ascii=False)
        sys.stdout.write("\n")
        return

    if not args.domain:
        parser.error("--domain is required")

    if args.mode == "by-name" or (args.first_name and args.last_name and args.mode != "smart"):
        if not (args.first_name and args.last_name):
            parser.error("--first-name and --last-name required for by-name")
        out = find_by_name(args.first_name, args.last_name, args.domain, tier=args.tier)
    elif args.mode == "by-domain":
        out = find_by_domain(args.domain, tier=args.tier)
    else:
        out = find_smart(args.domain, tier=args.tier)

    json.dump(out, sys.stdout, ensure_ascii=False)
    sys.stdout.write("\n")


if __name__ == "__main__":
    main()
