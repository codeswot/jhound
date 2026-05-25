#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import sys

from _ollama import generate_json


PROMPT = """You classify hiring-related email replies. Return STRICT JSON only.

FROM: {from_email}
SUBJECT: {subject}
BODY (first 2k chars):
{body}

Categories: rejection, interview, offer, recruiter, ghosted_check, generic.

Definitions:
- rejection: clearly turned down ("not moving forward", "decided to go with another")
- interview: invites to a call/interview or asks availability
- offer: explicit offer with role/salary/start date
- recruiter: generic recruiter outreach asking for a chat/CV — even if from cold side
- ghosted_check: out-of-office, auto-acknowledgement, "we received your application"
- generic: any other human reply

Return:
{{
  "classification": "rejection|interview|offer|recruiter|ghosted_check|generic",
  "confidence": 0-100,
  "next_action": "respond|schedule_interview|no_action|follow_up_later|negotiate",
  "reasoning": "one sentence"
}}
"""


def classify(from_email: str, subject: str, body: str) -> dict:
    prompt = PROMPT.format(
        from_email=from_email or "",
        subject=subject or "",
        body=(body or "")[:2000],
    )
    return generate_json(prompt, temperature=0.0)


def main() -> None:
    parser = argparse.ArgumentParser(description="Classify a job-reply email")
    parser.add_argument("--input", help="JSON file with {from, subject, body}")
    args = parser.parse_args()

    payload = json.load(open(args.input) if args.input else sys.stdin)
    result = classify(
        payload.get("from_email") or payload.get("from") or "",
        payload.get("subject", ""),
        payload.get("body", ""),
    )
    json.dump(result, sys.stdout, ensure_ascii=False)
    sys.stdout.write("\n")


if __name__ == "__main__":
    main()
