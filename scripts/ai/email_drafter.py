#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "scrapers"))
from _common import load_user_profile  # noqa: E402

from _ollama import generate_json  # noqa: E402


PROMPT = """You are writing a cold outreach email as Mubarak. You ARE Mubarak — first person, conversational, no formal corporate tone. Write like a tired engineer who picked one job out of 30 because something specifically caught his eye, not like a recruiter spamming.

ABSOLUTE RULES:
- 90 words MAX in the body. Brevity is the point. If it sounds polished it sounds AI — cut it.
- NO em dashes (— or –). Use commas or periods.
- NO "delighted", "thrilled", "passionate", "I would love to", "I am writing to", "I came across", "I hope this finds you well", "actively seeking", "leverage", "synergy", "ecosystem", "best-in-class", "world-class".
- NO bullet lists in the body.
- Open with "Hi {{first_name}}," if hiring-manager name given, else "Hi,". No "Hi Team" or "To whom it may concern".
- ONE specific concrete sentence about THEIR company / product based on the research, in the user's voice. Sound like you actually read about them, not like you generated a summary.
- ONE sentence with the user's relevant project/experience from EXPERIENCE_ANCHOR below — paraphrase, do not copy verbatim, and do not exaggerate.
- ONE soft ask. Either "Worth a 15-min call?" or "Happy to send over my CV if useful — attached." or "Open to a quick chat next week?". Vary it.
- Sign-off: just the name, portfolio URL, github URL on three lines. No "Best regards", no "Sincerely", no "Cheers".
- Lower-case "i" and "im" are fine ONLY in informal phrasing if it reads natural; default to standard casing.
- Contractions OK and encouraged: "I'm", "I've", "you're".
- Subject line: short, specific, no clickbait. Examples: "Flutter + Nostr at White Noise", "NestJS — Lightning processor", "Flutter mobile, interested in {company}". Under 55 chars.

VOICE EXAMPLES (style, do not copy):

  Hi Maarten,
  Saw InvestSuite ships white-label wealth platforms on Flutter. I've been doing Flutter + gRPC daily and recently contributed to White Noise, a Nostr secure messenger using MLS in Flutter. Happy to send over my CV and a couple of recommendation letters if useful — they're attached.
  Mubarak Ibrahim
  https://codeswot.me
  github.com/codeswot

  Hi,
  Noticed Zulip's mobile is going hard on Flutter. I ship production Flutter at SkuidPay and I'm a contributor on White Noise (parres/white_noise) — a Flutter MLS messenger. Open to a quick chat?
  Mubarak Ibrahim
  https://codeswot.me
  github.com/codeswot

USER PROFILE
- Name: {name}
- Portfolio: {portfolio}
- GitHub handle: {github_handle}

EXPERIENCE_ANCHOR (use ONE matching anchor, paraphrased, in body):
{experience_anchor}

JOB
- Title: {title}
- Company: {company}
- Description: {description}

HIRING MANAGER
- Name: {hm_name}
- Title: {hm_position}

COMPANY RESEARCH
- One-liner: {research_one_liner}
- Industry: {research_industry}
- Tech stack: {research_tech_stack}
- Summary: {research_summary}

Return STRICT JSON only:
{{
  "subject": "short specific subject line, under 55 chars",
  "body": "email body, plaintext with \\n line breaks"
}}
"""


def _pick_anchor(profile: dict, job: dict) -> str:
    anchors = profile.get("experience_anchors") or {}
    if not anchors:
        return ""
    haystack = " ".join([
        (job.get("job_title") or ""),
        (job.get("job_description") or "")[:1500],
        " ".join(job.get("ai_tags") or []),
    ]).lower()
    priority = ["flutter", "nostr", "lightning", "bitcoin", "nestjs", "typescript"]
    for key in priority:
        if key in haystack and key in anchors:
            return anchors[key]
    return anchors.get("default", "")


def _split_payload(payload: dict) -> tuple[dict, dict, dict]:
    if "job" in payload and isinstance(payload.get("job"), dict):
        return payload["job"], payload.get("research") or {}, payload.get("hm") or {}
    return payload, {}, {}


def draft(payload: dict, profile: dict) -> dict:
    job, research, hm = _split_payload(payload)
    prompt = PROMPT.format(
        name=profile.get("name", ""),
        portfolio=profile.get("links", {}).get("portfolio", ""),
        github_handle=profile.get("handle", ""),
        experience_anchor=_pick_anchor(profile, job),
        title=job.get("job_title", ""),
        company=job.get("company", ""),
        description=(job.get("job_description", "") or "")[:1500],
        hm_name=hm.get("name") or "(unknown — open with 'Hi,')",
        hm_position=hm.get("position") or "(unknown)",
        research_one_liner=research.get("one_liner") or "(none)",
        research_industry=research.get("industry") or "(unknown)",
        research_tech_stack=", ".join(research.get("tech_stack") or []) or "(unknown)",
        research_summary=(research.get("summary") or "")[:600] or "(none)",
    )
    return generate_json(prompt, temperature=0.75)


def main() -> None:
    parser = argparse.ArgumentParser(description="Draft hiring-manager email")
    parser.add_argument("--input", help="JSON file. Accepts either a job object OR {job, research}.")
    args = parser.parse_args()

    if args.input:
        with open(args.input, "r", encoding="utf-8") as f:
            payload = json.load(f)
    else:
        payload = json.load(sys.stdin)

    profile = load_user_profile()
    result = draft(payload, profile)
    json.dump(result, sys.stdout, ensure_ascii=False)
    sys.stdout.write("\n")


if __name__ == "__main__":
    main()
