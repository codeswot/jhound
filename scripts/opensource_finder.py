#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import re
import sys

import requests

GITHUB_API = "https://api.github.com"
GITHUB_TOKEN = os.getenv("GITHUB_TOKEN", "")

GRANT_FRIENDLY_ORGS = [
    "bitcoin", "bitcoindevkit", "lightningnetwork", "lightningdevkit",
    "nostr-protocol", "nostrlabs-io", "fiatjaf",
    "cashubtc", "ArkLabsHQ", "fedimint",
    "BlockstreamResearch", "alphabill-org",
]

BOUNTY_LABELS = ["bounty", "paid", "gitcoin", "reward", "$"]

BOUNTY_REGEX = [
    re.compile(r"\$\s*([\d,]+(?:\.\d{2})?)"),
    re.compile(r"([\d,]+)\s*(?:usd|dollars?)", re.IGNORECASE),
    re.compile(r"bounty[:\s]+\$?\s*([\d,]+)", re.IGNORECASE),
]


def _headers() -> dict:
    h = {"Accept": "application/vnd.github+json", "X-GitHub-Api-Version": "2022-11-28"}
    if GITHUB_TOKEN:
        h["Authorization"] = f"Bearer {GITHUB_TOKEN}"
    return h


def extract_bounty(title: str, body: str) -> int:
    text = f"{title} {body}"
    amounts: list[int] = []
    for rgx in BOUNTY_REGEX:
        for match in rgx.findall(text):
            try:
                amounts.append(int(match.replace(",", "").split(".")[0]))
            except ValueError:
                pass
    return max(amounts) if amounts else 0


def search_bounty_issues(keywords: list[str], min_bounty: int) -> list[dict]:
    found: list[dict] = []
    for keyword in keywords:
        for label in BOUNTY_LABELS[:3]:
            query = f"{keyword} label:{label} is:issue is:open"
            try:
                resp = requests.get(
                    f"{GITHUB_API}/search/issues",
                    params={"q": query, "sort": "created", "order": "desc", "per_page": 20},
                    headers=_headers(),
                    timeout=20,
                )
                if resp.status_code != 200:
                    continue
                for issue in resp.json().get("items", []):
                    bounty = extract_bounty(issue["title"], issue.get("body") or "")
                    if bounty < min_bounty:
                        continue
                    found.append({
                        "title": issue["title"],
                        "repository": "/".join(issue["repository_url"].split("/")[-2:]),
                        "url": issue["html_url"],
                        "bounty_amount": bounty,
                        "labels": [lbl["name"] for lbl in issue.get("labels", [])],
                        "created_at": issue["created_at"],
                        "matched_skills": [keyword],
                        "source": "github_bounty",
                    })
            except Exception as exc:
                print(f"bounty search error: {exc}", file=sys.stderr)
    return found


def search_grant_orgs(skills: list[str]) -> list[dict]:
    out: list[dict] = []
    skills_lower = [s.lower() for s in skills]

    for org in GRANT_FRIENDLY_ORGS:
        try:
            resp = requests.get(
                f"{GITHUB_API}/orgs/{org}/repos",
                params={"per_page": 30, "sort": "updated"},
                headers=_headers(),
                timeout=20,
            )
            if resp.status_code != 200:
                continue
            for repo in resp.json():
                language = (repo.get("language") or "").lower()
                description = (repo.get("description") or "").lower()
                topics = [t.lower() for t in repo.get("topics", [])]

                matched = [s for s in skills if s.lower() in language or s.lower() in description or s.lower() in topics]
                if not matched and repo.get("stargazers_count", 0) < 200:
                    continue

                out.append({
                    "title": repo["name"],
                    "repository": repo["full_name"],
                    "url": repo["html_url"],
                    "description": repo.get("description"),
                    "language": repo.get("language"),
                    "stars": repo.get("stargazers_count", 0),
                    "matched_skills": matched,
                    "source": "grant_org",
                    "grant_hint": "Likely covered by OpenSats, Spiral, or HRF grants",
                })
        except Exception as exc:
            print(f"grant org error: {exc}", file=sys.stderr)
    return out


def score(opportunity: dict, user_skills: list[str]) -> int:
    points = 0
    points += len(opportunity.get("matched_skills", [])) * 25
    if any(s.lower() in (opportunity.get("language") or "").lower() for s in user_skills):
        points += 20
    stars = opportunity.get("stars", 0)
    if stars > 1000:
        points += 15
    elif stars > 500:
        points += 10
    if opportunity.get("bounty_amount"):
        points += 25
    if opportunity.get("source") == "grant_org":
        points += 10
    return min(100, points)


def main() -> None:
    parser = argparse.ArgumentParser(description="Find paid open-source opportunities")
    parser.add_argument("--skills", nargs="+", default=["NestJS", "TypeScript", "Flutter", "Bitcoin", "Nostr"])
    parser.add_argument("--min-bounty", type=int, default=100)
    parser.add_argument("--min-score", type=int, default=50)
    args = parser.parse_args()

    opportunities: list[dict] = []
    opportunities.extend(search_bounty_issues(args.skills, args.min_bounty))
    opportunities.extend(search_grant_orgs(args.skills))

    ranked = []
    for opp in opportunities:
        s = score(opp, args.skills)
        if s >= args.min_score:
            opp["relevance_score"] = s
            ranked.append(opp)

    ranked.sort(key=lambda x: x["relevance_score"], reverse=True)
    json.dump(ranked, sys.stdout, ensure_ascii=False)
    sys.stdout.write("\n")


if __name__ == "__main__":
    main()
