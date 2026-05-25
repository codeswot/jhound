#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "scrapers"))
from _common import load_user_profile  # noqa: E402

from _ollama import generate_json  # noqa: E402

REJECT_REASONS = {
    "not_remote": "Listing is onsite, hybrid, or geographically restricted",
    "no_skill_match": "Required skills do not overlap with user's stack",
    "low_score": "AI match score below threshold",
}


def hard_reject(job: dict, profile: dict) -> str | None:
    if job.get("is_remote") is False:
        return "not_remote"

    rejected_kw = [k.lower() for k in profile.get("job_priority", {}).get("rejected", [])]
    haystack = " ".join([
        job.get("location", ""),
        job.get("job_description", ""),
        job.get("job_title", ""),
    ]).lower()

    for kw in rejected_kw:
        if kw in haystack:
            if "remote" in haystack and kw in {"us only", "eu only", "uk only"}:
                continue
            return "not_remote"

    return None


def build_prompt(job: dict, profile: dict) -> str:
    return f"""You are a job-matching engine. Score this job for the user. Return STRICT JSON only.

USER PROFILE:
- Skills: {', '.join(profile.get('skills', []))}
- Core skills (heavily weighted): {', '.join(profile.get('core_skills', []))}
- Location: Remote ONLY (no exceptions)
- Tier 1 preferred industries: {', '.join(profile.get('job_priority', {}).get('tier1_preferred', []))}

JOB:
- Title: {job.get('job_title', '')}
- Company: {job.get('company', '')}
- Location: {job.get('location', '')}
- Description: {(job.get('job_description', '') or '')[:2000]}

SCORING RULES:
1. If the job is NOT remote, return {{"reject": true, "reason": "not_remote"}}
2. If no meaningful skill overlap, return {{"reject": true, "reason": "no_skill_match"}}
3. Otherwise:
   - tier 1 (score 80-100): role involves Bitcoin, Nostr, Lightning, Open Source, or Decentralized tech
   - tier 2 (score 50-79):  remote tech role matching user's general skills
   - score 0-49: weak match — also return reject:true with reason "low_score"

Return JSON with this exact shape (no markdown, no preamble):
{{
  "reject": false,
  "score": 0-100,
  "tier": 1|2,
  "tags": ["bitcoin", "backend", ...],
  "reasoning": "one sentence why"
}}
"""


def score_job(job: dict, profile: dict, scoring: dict) -> dict:
    reject = hard_reject(job, profile)
    if reject:
        return {**job, "ai_rejected": True, "reject_reason": reject, "ai_job_match_score": 0}

    try:
        result = generate_json(build_prompt(job, profile))
    except Exception as exc:
        print(f"ollama error for {job.get('job_url')}: {exc}", file=sys.stderr)
        return {**job, "ai_rejected": True, "reject_reason": "ollama_error", "ai_job_match_score": 0}

    if result.get("reject"):
        return {
            **job,
            "ai_rejected": True,
            "reject_reason": result.get("reason", "low_score"),
            "ai_job_match_score": result.get("score", 0),
            "ai_reasoning": result.get("reasoning", ""),
        }

    try:
        score = int(result.get("score", 0))
    except (ValueError, TypeError):
        score = 0
    tier1_threshold = scoring.get("tier1_threshold", 80)
    tier2_threshold = scoring.get("tier2_threshold", 50)

    if score < tier2_threshold:
        return {
            **job,
            "ai_rejected": True,
            "reject_reason": "low_score",
            "ai_job_match_score": score,
            "ai_reasoning": result.get("reasoning", ""),
        }

    tier = 1 if score >= tier1_threshold else 2

    return {
        **job,
        "ai_rejected": False,
        "ai_job_match_score": score,
        "ai_priority_tier": tier,
        "ai_tags": result.get("tags", []),
        "ai_reasoning": result.get("reasoning", ""),
    }


def main() -> None:
    parser = argparse.ArgumentParser(description="AI job filter (Ollama)")
    parser.add_argument("--input", help="Path to JSON file. Reads stdin if omitted.")
    parser.add_argument("--limit", type=int, default=0, help="Max jobs to score (0 = no limit)")
    args = parser.parse_args()

    if args.input:
        with open(args.input, "r", encoding="utf-8") as f:
            jobs = json.load(f)
    else:
        jobs = json.load(sys.stdin)

    if args.limit:
        jobs = jobs[: args.limit]

    profile = load_user_profile()
    scoring = profile.get("scoring", {"tier1_threshold": 80, "tier2_threshold": 50})

    accepted: list[dict] = []
    rejected: list[dict] = []
    for job in jobs:
        scored = score_job(job, profile, scoring)
        if scored.get("ai_rejected"):
            rejected.append(scored)
        else:
            accepted.append(scored)

    accepted.sort(key=lambda j: (j.get("ai_priority_tier", 2), -j.get("ai_job_match_score", 0)))

    output = {
        "accepted": accepted,
        "rejected": rejected,
        "summary": {
            "total_input": len(jobs),
            "accepted": len(accepted),
            "tier1": sum(1 for j in accepted if j.get("ai_priority_tier") == 1),
            "tier2": sum(1 for j in accepted if j.get("ai_priority_tier") == 2),
            "rejected": len(rejected),
        },
    }
    json.dump(output, sys.stdout, ensure_ascii=False)
    sys.stdout.write("\n")


if __name__ == "__main__":
    main()
