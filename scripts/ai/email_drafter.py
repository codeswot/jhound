#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "scrapers"))
from _common import load_user_profile  # noqa: E402

from _ollama import generate_json  # noqa: E402


PROMPT = """You are drafting a cold outreach email from a senior engineer to a hiring manager.

WRITING STYLE:
- Plain, direct, no fluff. No emojis. No "I hope this email finds you well".
- 110 words MAX in the body.
- If a hiring manager name is given, open with "Hi {{first name}},"; otherwise open with "Hi,".
- Second sentence: ONE specific observation about the company using the research below.
- Mention 1-2 concrete projects/skills that match the role.
- End with a clear ask: 15-min call OR review of CV.
- Sign with: {name}\\n{portfolio} | github.com/{github_handle}

USER:
- Name: {name}
- Core skills: {core_skills}
- Portfolio: {portfolio}
- GitHub: {github}
- Has attached: CV ({cv_filename}) and 2 recommendation letters

JOB:
- Title: {title}
- Company: {company}
- Description: {description}

HIRING MANAGER (if known — address by first name in opening):
- Name: {hm_name}
- Title: {hm_position}

COMPANY RESEARCH (use to personalise the opening sentence):
- One-liner: {research_one_liner}
- Industry: {research_industry}
- Tech stack: {research_tech_stack}
- Summary: {research_summary}

Return STRICT JSON only:
{{
  "subject": "concise subject line, under 60 chars",
  "body": "the email body, plaintext, with \\n line breaks"
}}
"""


def _split_payload(payload: dict) -> tuple[dict, dict, dict]:
    if "job" in payload and isinstance(payload.get("job"), dict):
        return payload["job"], payload.get("research") or {}, payload.get("hm") or {}
    return payload, {}, {}


def draft(payload: dict, profile: dict) -> dict:
    job, research, hm = _split_payload(payload)
    prompt = PROMPT.format(
        name=profile.get("name", ""),
        core_skills=", ".join(profile.get("core_skills", [])),
        portfolio=profile.get("links", {}).get("portfolio", ""),
        github=profile.get("links", {}).get("github", ""),
        github_handle=profile.get("handle", ""),
        cv_filename=Path(profile.get("resume_path", "cv.docx")).name,
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
    return generate_json(prompt, temperature=0.4)


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
