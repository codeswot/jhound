#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from urllib.parse import quote_plus, urlparse

import requests
from bs4 import BeautifulSoup

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "ai"))
from _ollama import generate_json  # noqa: E402

UA = {"User-Agent": "Mozilla/5.0 (compatible; jHound/1.0; +https://codeswot.me)"}
TIMEOUT = 15


TLD_RETRY = [".com", ".io", ".co", ".app", ".org", ".dev"]


def guess_domains(company: str) -> list[str]:
    slug = re.sub(r"[^a-z0-9]", "", company.lower())
    return [f"{slug}{tld}" for tld in TLD_RETRY]


def find_homepage_across_tlds(domains: list[str]) -> tuple[str | None, str | None]:
    for domain in domains:
        for scheme in ("https", "http"):
            for prefix in ("", "www."):
                url = f"{scheme}://{prefix}{domain}"
                html = fetch(url)
                if html:
                    return url, html
    return None, None


def fetch(url: str) -> str | None:
    try:
        r = requests.get(url, headers=UA, timeout=TIMEOUT, allow_redirects=True)
        if r.status_code == 200 and "text" in r.headers.get("Content-Type", ""):
            return r.text
    except Exception as exc:
        print(f"fetch {url} failed: {exc}", file=sys.stderr)
    return None


def find_homepage(domain: str) -> tuple[str | None, str | None]:
    for scheme in ("https", "http"):
        for prefix in ("", "www."):
            url = f"{scheme}://{prefix}{domain}"
            html = fetch(url)
            if html:
                return url, html
    return None, None


def extract_meta(html: str) -> dict:
    soup = BeautifulSoup(html, "lxml")
    meta: dict = {}

    def _content(name: str, attr: str = "name") -> str | None:
        tag = soup.find("meta", attrs={attr: name})
        return tag.get("content", "").strip() if tag and tag.get("content") else None

    meta["title"] = (soup.title.string.strip() if soup.title and soup.title.string else None)
    meta["description"] = _content("description") or _content("og:description", "property")
    meta["og_site_name"] = _content("og:site_name", "property")
    meta["og_image"] = _content("og:image", "property")

    for el in soup(["script", "style", "noscript", "header", "footer", "nav"]):
        el.decompose()
    text = re.sub(r"\s+", " ", soup.get_text(" ")).strip()
    meta["body_excerpt"] = text[:4000]

    socials = {"linkedin": None, "twitter": None, "github": None}
    for a in soup.find_all("a", href=True):
        href = a["href"]
        if "linkedin.com/company" in href and not socials["linkedin"]:
            socials["linkedin"] = href
        elif ("twitter.com/" in href or "x.com/" in href) and not socials["twitter"]:
            socials["twitter"] = href.split("?")[0]
        elif "github.com/" in href and not socials["github"]:
            parts = urlparse(href).path.strip("/").split("/")
            if len(parts) == 1 and parts[0] not in {"login", "join", "features"}:
                socials["github"] = href.split("?")[0]
    meta.update(socials)
    return meta


def linkedin_company_search(company: str) -> str | None:
    url = f"https://www.google.com/search?q={quote_plus(f'site:linkedin.com/company {company}')}"
    html = fetch(url)
    if not html:
        return None
    match = re.search(r"https://[a-z]+\.linkedin\.com/company/[a-zA-Z0-9\-_/]+", html)
    return match.group(0) if match else None


def ai_summarise(company: str, meta: dict, job_description: str | None) -> dict:
    prompt = f"""You are summarising a company for a job applicant. Be factual and concise.
Return STRICT JSON only.

COMPANY: {company}
WEBSITE TITLE: {meta.get('title') or ''}
META DESCRIPTION: {meta.get('description') or ''}
HOMEPAGE EXCERPT (first 3k chars): {(meta.get('body_excerpt') or '')[:3000]}
JOB DESCRIPTION (optional context, 1500 chars): {(job_description or '')[:1500]}

Return:
{{
  "one_liner": "one sentence, under 120 chars, what the company does",
  "summary": "2-3 sentences. Industry, target customer, why notable. No fluff.",
  "industry": "single category (e.g. 'Bitcoin infra', 'Devtools', 'Fintech')",
  "size_hint": "startup | growth | enterprise | unknown",
  "funding_hint": "bootstrapped | seed | series A/B/C+ | public | unknown",
  "hq_location": "City, Country or 'remote-first' or null",
  "tech_stack": ["list", "of", "tech"],
  "is_open_source": true|false,
  "is_bitcoin_or_nostr": true|false
}}"""
    try:
        return generate_json(prompt, temperature=0.2)
    except Exception as exc:
        print(f"ollama summarise failed: {exc}", file=sys.stderr)
        return {}


def research(company: str, domain: str | None, job_description: str | None = None) -> dict:
    if domain:
        website, html = find_homepage_across_tlds([domain])
    else:
        website, html = find_homepage_across_tlds(guess_domains(company))
    if website:
        domain = website.replace("https://", "").replace("http://", "").split("/")[0].replace("www.", "")
    else:
        domain = domain or guess_domains(company)[0]
    meta = extract_meta(html) if html else {}

    linkedin = meta.get("linkedin") or linkedin_company_search(company)
    summary = ai_summarise(company, meta, job_description) if meta else {}

    return {
        "company": company,
        "domain": domain,
        "website": website,
        "linkedin": linkedin,
        "twitter": meta.get("twitter"),
        "github": meta.get("github"),
        "one_liner": summary.get("one_liner"),
        "summary": summary.get("summary"),
        "industry": summary.get("industry"),
        "size_hint": summary.get("size_hint"),
        "funding_hint": summary.get("funding_hint"),
        "hq_location": summary.get("hq_location"),
        "tech_stack": summary.get("tech_stack") or [],
        "is_open_source": bool(summary.get("is_open_source")),
        "is_bitcoin_or_nostr": bool(summary.get("is_bitcoin_or_nostr")),
        "raw_html_excerpt": (meta.get("body_excerpt") or "")[:2000],
    }


def main() -> None:
    parser = argparse.ArgumentParser(description="Research a company post-apply")
    parser.add_argument("--company")
    parser.add_argument("--domain")
    parser.add_argument("--job-description")
    parser.add_argument("--input", help="JSON file with {company, domain, job_description}")
    args = parser.parse_args()

    if args.input:
        payload = json.load(open(args.input))
        company = payload.get("company")
        if not company:
            parser.error("--company is required when --input payload has no 'company' field")
        result = research(
            company,
            payload.get("company_domain") or payload.get("domain"),
            payload.get("job_description"),
        )
    elif args.company:
        result = research(args.company, args.domain, args.job_description)
    else:
        parser.error("--company is required (or --input with company field in JSON)")

    json.dump(result, sys.stdout, ensure_ascii=False)
    sys.stdout.write("\n")


if __name__ == "__main__":
    main()
