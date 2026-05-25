#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
import unittest
from pathlib import Path
from unittest.mock import MagicMock, patch

ROOT = Path(__file__).resolve().parent.parent
FIXTURES = ROOT / "tests" / "fixtures"

sys.path.insert(0, str(ROOT / "scripts"))
sys.path.insert(0, str(ROOT / "scripts" / "scrapers"))
sys.path.insert(0, str(ROOT / "scripts" / "ai"))


def _load_fixture_jobs() -> list[dict]:
    with open(FIXTURES / "jobs.json", "r", encoding="utf-8") as f:
        return json.load(f)


def _mock_ollama_for(job: dict) -> dict:
    expected = job.get("_expected", {})
    if not expected.get("accepted", True):
        return {"reject": True, "reason": expected.get("reject_reason", "low_score")}
    tier = expected.get("tier", 2)
    score = expected.get("min_score", 50) + 5
    tags = ["bitcoin", "nostr"] if tier == 1 else ["remote", "backend"]
    return {
        "reject": False,
        "score": score,
        "tier": tier,
        "tags": tags,
        "reasoning": "test fixture",
    }


class TestRemoteHeuristic(unittest.TestCase):
    def setUp(self):
        from _common import is_remote
        self.is_remote = is_remote

    def test_obvious_remote(self):
        self.assertTrue(self.is_remote("Remote (Worldwide)"))
        self.assertTrue(self.is_remote("100% remote"))
        self.assertTrue(self.is_remote("Distributed team"))

    def test_obvious_non_remote(self):
        self.assertFalse(self.is_remote("Hybrid Berlin"))
        self.assertFalse(self.is_remote("Onsite London"))
        self.assertFalse(self.is_remote("In-office, Lagos"))

    def test_empty(self):
        self.assertFalse(self.is_remote(""))
        self.assertFalse(self.is_remote(None))


class TestHardReject(unittest.TestCase):
    def setUp(self):
        from job_filter import hard_reject
        self.hard_reject = hard_reject
        self.profile = {
            "job_priority": {
                "rejected": ["onsite", "hybrid", "us only", "eu only"]
            }
        }

    def test_passes_remote_job(self):
        job = {"is_remote": True, "location": "Remote", "job_description": "build stuff", "job_title": "Dev"}
        self.assertIsNone(self.hard_reject(job, self.profile))

    def test_rejects_explicit_not_remote(self):
        job = {"is_remote": False, "location": "Onsite", "job_description": "", "job_title": ""}
        self.assertEqual(self.hard_reject(job, self.profile), "not_remote")

    def test_rejects_hybrid_keyword(self):
        job = {"is_remote": True, "location": "Hybrid Berlin", "job_description": "", "job_title": ""}
        self.assertEqual(self.hard_reject(job, self.profile), "not_remote")


class TestJobFilterMocked(unittest.TestCase):
    def test_full_pipeline(self):
        from scrapers._common import load_user_profile  # noqa: F401
        import job_filter

        fixture_jobs = _load_fixture_jobs()

        def fake_generate_json(prompt, **kwargs):
            for job in fixture_jobs:
                if job["job_title"] in prompt and job["company"] in prompt:
                    return _mock_ollama_for(job)
            return {"reject": True, "reason": "low_score"}

        with patch.object(job_filter, "generate_json", side_effect=fake_generate_json):
            profile = job_filter.load_user_profile() or {
                "skills": ["NestJS", "Flutter", "Bitcoin", "Nostr"],
                "core_skills": ["Bitcoin", "Nostr"],
                "job_priority": {
                    "rejected": ["onsite", "hybrid", "us only"],
                    "tier1_preferred": ["Bitcoin", "Nostr"],
                },
                "scoring": {"tier1_threshold": 80, "tier2_threshold": 50},
            }
            scoring = profile.get("scoring", {"tier1_threshold": 80, "tier2_threshold": 50})

            accepted, rejected = [], []
            for job in fixture_jobs:
                scored = job_filter.score_job(job, profile, scoring)
                (rejected if scored.get("ai_rejected") else accepted).append(scored)

            by_url = {j["job_url"]: j for j in accepted + rejected}
            for fix in fixture_jobs:
                exp = fix["_expected"]
                got = by_url[fix["job_url"]]
                if exp["accepted"]:
                    self.assertFalse(got.get("ai_rejected"), f"{fix['job_title']} should pass: {got}")
                    self.assertEqual(got["ai_priority_tier"], exp["tier"], f"{fix['job_title']} wrong tier")
                else:
                    self.assertTrue(got.get("ai_rejected"), f"{fix['job_title']} should reject")
                    self.assertEqual(got["reject_reason"], exp["reject_reason"], f"{fix['job_title']} wrong reason")


class TestWhatsAppFormatters(unittest.TestCase):
    def setUp(self):
        result = subprocess.run(
            ["node", "-e", """
                const { fmt } = require('./scripts/nostr_notifier.js');
                const out = {
                    daily: fmt.dailySummary({ total_today: 12, easy_apply_count: 7, email_count: 5, companies: ['Voltage','Damus'], week_total: 67, response_rate: 8 }),
                    job: fmt.jobAlert({ job_title: 'Backend', company: 'Voltage', application_method: 'email', ai_priority_tier: 1, ai_job_match_score: 90, job_url: 'http://x.test' }),
                    brief: fmt.companyBrief({ job: { company: 'Voltage', job_title: 'Backend', job_url: 'http://x.test' }, research: { one_liner: 'Bitcoin infra', summary: 'Voltage runs LN nodes.', industry: 'Bitcoin', tech_stack: ['Rust','Go'], website: 'https://voltage.cloud' } }),
                    response: fmt.responseAlert({ classification: 'interview', company: 'Voltage', job_title: 'Backend', from_email: 'hm@voltage.cloud', subject: 'Re: Application', snippet: 'Lets schedule.' }),
                    manual: fmt.manualDigest([{ job_title: 'X', company: 'Y', ai_priority_tier: 1, ai_job_match_score: 85, status: 'needs_manual', job_url: 'http://x.test' }]),
                    fastApply: fmt.fastApplyLink({ job: { job_title: 'Backend', company: 'Voltage', ai_priority_tier: 1, ai_job_match_score: 92, source_board: 'LinkedIn', job_url: 'https://linkedin.com/jobs/view/123' }, research: { one_liner: 'Bitcoin Lightning infrastructure', industry: 'Bitcoin', tech_stack: ['Rust','Go'] } }),
                    fastApplyLegacy: fmt.fastApplyLink({ job_title: 'Backend', company: 'Voltage', ai_priority_tier: 1, ai_job_match_score: 92, source_board: 'LinkedIn', job_url: 'https://linkedin.com/jobs/view/123' }),
                };
                process.stdout.write(JSON.stringify(out));
            """],
            cwd=str(ROOT),
            capture_output=True,
            text=True,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.formatted = json.loads(result.stdout)

    def test_daily_has_companies(self):
        self.assertIn("Voltage", self.formatted["daily"])
        self.assertIn("Damus", self.formatted["daily"])

    def test_brief_has_links(self):
        self.assertIn("voltage.cloud", self.formatted["brief"])
        self.assertIn("Bitcoin infra", self.formatted["brief"])

    def test_response_alert(self):
        self.assertIn("interview", self.formatted["response"])
        self.assertIn("voltage.cloud", self.formatted["response"])

    def test_manual_digest_non_empty(self):
        self.assertIn("Manual review", self.formatted["manual"])

    def test_fast_apply_link(self):
        self.assertIn("Fast-apply", self.formatted["fastApply"])
        self.assertIn("linkedin.com/jobs/view/123", self.formatted["fastApply"])
        self.assertIn("Voltage", self.formatted["fastApply"])
        self.assertIn("Bitcoin Lightning", self.formatted["fastApply"])
        self.assertIn("Rust", self.formatted["fastApply"])

    def test_fast_apply_link_legacy(self):
        self.assertIn("Fast-apply", self.formatted["fastApplyLegacy"])
        self.assertIn("Voltage", self.formatted["fastApplyLegacy"])


class TestSvixVerification(unittest.TestCase):
    def test_no_secret_passes(self):
        result = subprocess.run(
            ["python3", "scripts/verify_svix.py"],
            input=json.dumps({"headers": {}, "body": {}, "raw_body": ""}),
            capture_output=True,
            text=True,
            cwd=str(ROOT),
            env={**os.environ, "RESEND_WEBHOOK_SECRET": ""},
        )
        self.assertEqual(result.returncode, 0)
        data = json.loads(result.stdout)
        self.assertTrue(data["ok"])
        self.assertEqual(data["reason"], "no_secret_configured")

    def test_missing_headers_fail(self):
        result = subprocess.run(
            ["python3", "scripts/verify_svix.py"],
            input=json.dumps({"headers": {}, "body": {}, "raw_body": ""}),
            capture_output=True,
            text=True,
            cwd=str(ROOT),
            env={**os.environ, "RESEND_WEBHOOK_SECRET": "whsec_AAA"},
        )
        self.assertEqual(result.returncode, 0)
        data = json.loads(result.stdout)
        self.assertFalse(data["ok"])
        self.assertEqual(data["reason"], "missing_svix_headers")


class TestEmailFinderSmart(unittest.TestCase):
    def setUp(self):
        import email_finder
        patchers = [
            patch.object(email_finder, "redis_client"),
            patch.object(email_finder, "cached_get", return_value=None),
            patch.object(email_finder, "can_use_apollo", return_value=True),
            patch.object(email_finder, "use_apollo_quota"),
            patch.object(email_finder, "cached_set"),
            patch.object(email_finder, "quota_status", return_value={"day_used": 0, "day_limit": 10, "week_used": 0, "week_limit": 20, "month_used": 0, "month_limit": 80}),
            patch.object(email_finder, "apollo_quota_status", return_value={"month_used": 0, "month_limit": 500}),
        ]
        self.cleanups = [p.start() for p in patchers]
        self.find_smart = email_finder.find_smart

    def tearDown(self):
        for p in self.cleanups:
            p.stop()

    def _fake_apollo_people(self):
        return {
            "people": [
                {
                    "first_name": "Sarah",
                    "last_name": "Recruiter",
                    "title": "Head of Talent",
                    "email": "sarah@voltage.cloud",
                    "email_status": "verified",
                    "linkedin_url": "https://linkedin.com/in/sarah",
                }
            ]
        }

    def _fake_apollo_no_email(self):
        return {
            "people": [
                {
                    "first_name": "John",
                    "last_name": "Doe",
                    "title": "Engineering Manager",
                    "email": None,
                    "email_status": "unavailable",
                    "linkedin_url": "https://linkedin.com/in/johndoe",
                }
            ]
        }

    @patch("email_finder.apollo_people_search")
    def test_smart_apollo_verified(self, mock_apollo):
        mock_apollo.return_value = {"ok": True, "data": self._fake_apollo_people()}
        result = self.find_smart("voltage.cloud")
        self.assertEqual(result["email"], "sarah@voltage.cloud")
        self.assertEqual(result["method"], "apollo_verified")
        self.assertEqual(result["resolver"], "apollo")
        self.assertEqual(result["hm_name"], "Sarah Recruiter")
        self.assertEqual(result["hm_position"], "Head of Talent")

    @patch("email_finder.find_by_name")
    @patch("email_finder.apollo_people_search")
    def test_smart_apollo_fallback_to_hunter(self, mock_apollo, mock_finder):
        mock_apollo.return_value = {"ok": True, "data": self._fake_apollo_no_email()}
        mock_finder.return_value = {
            "email": "johndoe@voltage.cloud",
            "confidence": 85,
            "method": "hunter_email_finder",
        }
        result = self.find_smart("voltage.cloud")
        self.assertEqual(result["email"], "johndoe@voltage.cloud")
        self.assertIn("apollo_then_hunter", result["resolver"])
        self.assertEqual(result["hm_name"], "John Doe")

    @patch("email_finder.apollo_people_search")
    @patch("email_finder.find_by_domain")
    def test_smart_apollo_empty_fallback_to_domain(self, mock_domain, mock_apollo):
        mock_apollo.return_value = {"ok": True, "data": {"people": []}}
        mock_domain.return_value = {
            "email": "info@voltage.cloud",
            "confidence": 70,
            "method": "hunter_domain_search",
        }
        result = self.find_smart("voltage.cloud")
        self.assertEqual(result["email"], "info@voltage.cloud")
        self.assertEqual(result["resolver"], "hunter_domain_search")

    @patch("email_finder.apollo_people_search")
    def test_smart_apollo_skipped_no_key(self, mock_apollo):
        mock_apollo.return_value = {"ok": False, "status_code": 401}
        result = self.find_smart("voltage.cloud")
        self.assertEqual(result["resolver"], "hunter_domain_search")
        self.assertEqual(result["apollo"]["hit"], "apollo_error")


class TestDbCli(unittest.TestCase):
    def test_help(self):
        result = subprocess.run(
            ["python3", "scripts/db.py", "--help"],
            capture_output=True, text=True, cwd=str(ROOT),
        )
        self.assertEqual(result.returncode, 0)
        self.assertIn("record-application", result.stdout)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--verbose", "-v", action="store_true")
    args = parser.parse_args()

    loader = unittest.TestLoader()
    suite = unittest.TestSuite()
    for cls in [TestRemoteHeuristic, TestHardReject, TestJobFilterMocked,
                TestWhatsAppFormatters, TestSvixVerification, TestEmailFinderSmart, TestDbCli]:
        suite.addTests(loader.loadTestsFromTestCase(cls))

    runner = unittest.TextTestRunner(verbosity=2 if args.verbose else 1)
    result = runner.run(suite)
    sys.exit(0 if result.wasSuccessful() else 1)


if __name__ == "__main__":
    main()
