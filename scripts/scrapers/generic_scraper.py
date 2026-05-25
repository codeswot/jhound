#!/usr/bin/env python3
from __future__ import annotations

import argparse
import re
import sys
from urllib.parse import quote_plus

import requests
from bs4 import BeautifulSoup

from _common import clean, emit_jobs, is_remote, now_iso

UA = {"User-Agent": "Mozilla/5.0 (compatible; jHound/1.0; +https://codeswot.me)"}


def scrape_remoteok(keywords: list[str]) -> list[dict]:
    try:
        resp = requests.get("https://remoteok.com/api", headers=UA, timeout=20)
        resp.raise_for_status()
        data = resp.json()
    except Exception as exc:
        print(f"remoteok error: {exc}", file=sys.stderr)
        return []

    jobs: list[dict] = []
    kw_lower = [k.lower() for k in keywords]

    for item in data:
        if not isinstance(item, dict) or "id" not in item:
            continue
        title = item.get("position") or item.get("title") or ""
        desc = item.get("description", "")
        tags = " ".join(item.get("tags", []) if isinstance(item.get("tags"), list) else [])
        haystack = f"{title} {desc} {tags}".lower()

        if not any(k in haystack for k in kw_lower):
            continue

        jobs.append({
            "job_title": clean(title, 200),
            "company": clean(item.get("company", ""), 200),
            "location": clean(item.get("location", "Remote"), 200),
            "job_description": clean(desc, 5000),
            "job_url": item.get("url") or item.get("apply_url") or f"https://remoteok.com/remote-jobs/{item.get('id')}",
            "source_board": "RemoteOK",
            "has_easy_apply": False,
            "is_remote": True,
            "scraped_at": now_iso(),
        })
    return jobs


def scrape_weworkremotely(keywords: list[str]) -> list[dict]:
    jobs: list[dict] = []
    for kw in keywords:
        url = f"https://weworkremotely.com/remote-jobs/search?term={quote_plus(kw)}"
        try:
            resp = requests.get(url, headers=UA, timeout=20)
            resp.raise_for_status()
        except Exception as exc:
            print(f"wwr error for {kw}: {exc}", file=sys.stderr)
            continue

        soup = BeautifulSoup(resp.text, "lxml")
        for li in soup.select("li.feature, li.new-listing-container"):
            link = li.find("a", href=True)
            if not link:
                continue
            company_el = li.select_one("span.company") or li.select_one(".new-listing__company-name")
            title_el = li.select_one("span.title") or li.select_one(".new-listing__header__title")
            region_el = li.select_one("span.region") or li.select_one(".new-listing__company-headquarters")

            job_url = "https://weworkremotely.com" + link["href"]
            jobs.append({
                "job_title": clean(title_el.get_text() if title_el else "", 200),
                "company": clean(company_el.get_text() if company_el else "", 200),
                "location": clean(region_el.get_text() if region_el else "Remote", 200),
                "job_description": "",
                "job_url": job_url,
                "source_board": "WeWorkRemotely",
                "has_easy_apply": False,
                "is_remote": True,
                "scraped_at": now_iso(),
                "search_keyword": kw,
            })
    return jobs


def scrape_cryptocurrencyjobs(keywords: list[str]) -> list[dict]:
    jobs: list[dict] = []
    for kw in keywords:
        url = f"https://cryptocurrencyjobs.co/?s={quote_plus(kw)}"
        try:
            resp = requests.get(url, headers=UA, timeout=20)
            resp.raise_for_status()
        except Exception as exc:
            print(f"cryptojobs error: {exc}", file=sys.stderr)
            continue

        soup = BeautifulSoup(resp.text, "lxml")
        for card in soup.select("li.job"):
            link = card.find("a", href=True)
            if not link:
                continue
            title_el = card.select_one("h2") or card.select_one(".job-title")
            company_el = card.select_one(".job-company") or card.select_one("h3")
            loc_el = card.select_one(".job-location") or card.select_one(".location")
            location_text = loc_el.get_text() if loc_el else "Remote"

            if not is_remote(location_text):
                continue

            jobs.append({
                "job_title": clean(title_el.get_text() if title_el else "", 200),
                "company": clean(company_el.get_text() if company_el else "", 200),
                "location": clean(location_text, 200),
                "job_description": "",
                "job_url": link["href"] if link["href"].startswith("http") else f"https://cryptocurrencyjobs.co{link['href']}",
                "source_board": "CryptocurrencyJobs",
                "has_easy_apply": False,
                "is_remote": True,
                "scraped_at": now_iso(),
                "search_keyword": kw,
            })
    return jobs


def scrape_bitcoinerjobs(keywords: list[str]) -> list[dict]:
    jobs: list[dict] = []
    for base in ("https://bitcoinerjobs.com", "https://bitcoinerjobs.co"):
        try:
            resp = requests.get(base, headers=UA, timeout=20)
            if resp.status_code != 200:
                continue
        except Exception as exc:
            print(f"bitcoinerjobs error: {exc}", file=sys.stderr)
            continue

        soup = BeautifulSoup(resp.text, "lxml")
        for card in soup.select("a[href*='/jobs/'], a[href*='/job/']"):
            href = card.get("href", "")
            if not href:
                continue
            text = card.get_text(" ", strip=True)
            if len(text) < 10:
                continue

            url = href if href.startswith("http") else f"{base}{href}"
            kw_match = next((k for k in keywords if k.lower() in text.lower()), None)
            if keywords and not kw_match and not any(k.lower() in {"bitcoin", "nostr", "lightning"} for k in keywords):
                continue

            jobs.append({
                "job_title": clean(text, 200),
                "company": "",
                "location": "Remote",
                "job_description": "",
                "job_url": url,
                "source_board": "BitcoinerJobs",
                "has_easy_apply": False,
                "is_remote": True,
                "scraped_at": now_iso(),
                "search_keyword": kw_match or "bitcoin",
            })
        break
    return jobs


def scrape_hn_whoishiring(keywords: list[str]) -> list[dict]:
    jobs: list[dict] = []
    for kw in keywords:
        query = f"{kw} REMOTE"
        try:
            resp = requests.get(
                f"https://hn.algolia.com/api/v1/search?query={quote_plus(query)}&tags=comment&hitsPerPage=20",
                headers=UA,
                timeout=20,
            )
            resp.raise_for_status()
            data = resp.json()
        except Exception as exc:
            print(f"hn error: {exc}", file=sys.stderr)
            continue

        for hit in data.get("hits", []):
            story_title = (hit.get("story_title") or "").lower()
            if "hiring" not in story_title and "who is hiring" not in story_title:
                continue

            text = hit.get("comment_text") or ""
            if not text or len(text) < 100:
                continue
            text_plain = re.sub(r"<[^>]+>", " ", text)
            if not is_remote(text_plain):
                continue

            company_match = re.search(r"^([A-Z][A-Za-z0-9 &\-,.']{2,60})\s*[\|\-–—]", text_plain.strip())
            company = company_match.group(1) if company_match else "HN Listing"

            jobs.append({
                "job_title": f"{kw} role via HN Who is Hiring",
                "company": clean(company, 200),
                "location": "Remote",
                "job_description": clean(text_plain, 5000),
                "job_url": f"https://news.ycombinator.com/item?id={hit.get('objectID')}",
                "source_board": "HNWhoIsHiring",
                "has_easy_apply": False,
                "is_remote": True,
                "scraped_at": now_iso(),
                "search_keyword": kw,
            })
    return jobs


SOURCES = {
    "remoteok": scrape_remoteok,
    "weworkremotely": scrape_weworkremotely,
    "cryptocurrencyjobs": scrape_cryptocurrencyjobs,
    "bitcoinerjobs": scrape_bitcoinerjobs,
    "hn": scrape_hn_whoishiring,
}


def main() -> None:
    parser = argparse.ArgumentParser(description="Generic remote job board scraper")
    parser.add_argument("--source", required=True, choices=list(SOURCES.keys()) + ["all"])
    parser.add_argument("--keywords", nargs="+", default=["Bitcoin", "Nostr", "NestJS", "Flutter", "TypeScript"])
    args = parser.parse_args()

    if args.source == "all":
        out: list[dict] = []
        for name, fn in SOURCES.items():
            try:
                out.extend(fn(args.keywords))
            except Exception as exc:
                print(f"{name} failed: {exc}", file=sys.stderr)
        emit_jobs(out)
    else:
        emit_jobs(SOURCES[args.source](args.keywords))


if __name__ == "__main__":
    main()
