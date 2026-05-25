#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "scrapers"))
from _common import load_user_profile  # noqa: E402

from _ollama import generate_json  # noqa: E402


PROMPT = """You are drafting a follow-up email to a hiring manager.

CONSTRAINTS:
- Body MAX 80 words. Plain text, no emojis.
- Reference the original outreach ("Following up on my note from {days_ago} days ago about the {title} role at {company}").
- ONE concrete reason they should reply now (e.g. recent open-source contribution, relevant project).
- End with a clear ask: "If now's not a good time, even a one-line reply with timing would help."
- Sign with: {name}\\n{portfolio}

USER:
- Name: {name}
- Core skills: {skills}
- Portfolio: {portfolio}
- GitHub: {github}

JOB:
- Title: {title}
- Company: {company}

This is follow-up #{follow_up_number} of max {max_follow_ups}.

Return STRICT JSON only:
{{
  "subject": "Re: ... or short subject under 60 chars",
  "body": "plain text with \\n"
}}
"""


def draft(payload: dict, profile: dict) -> dict:
    follow_up_number = int(payload.get("follow_up_count", 0)) + 1
    prompt = PROMPT.format(
        days_ago=payload.get("days_since_contact") or 7,
        title=payload.get("job_title", ""),
        company=payload.get("company", ""),
        name=profile.get("name", ""),
        skills=", ".join(profile.get("core_skills", [])),
        portfolio=profile.get("links", {}).get("portfolio", ""),
        github=profile.get("links", {}).get("github", ""),
        follow_up_number=follow_up_number,
        max_follow_ups=2,
    )
    return generate_json(prompt, temperature=0.3)


def main() -> None:
    parser = argparse.ArgumentParser(description="Draft a follow-up email")
    parser.add_argument("--input", help="JSON file with job context")
    args = parser.parse_args()

    payload = json.load(open(args.input) if args.input else sys.stdin)
    profile = load_user_profile()
    result = draft(payload, profile)
    json.dump(result, sys.stdout, ensure_ascii=False)
    sys.stdout.write("\n")


if __name__ == "__main__":
    main()
