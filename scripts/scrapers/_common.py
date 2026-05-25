from __future__ import annotations

import json
import math
import os
import re
import sys
from datetime import datetime, timezone
from typing import Iterable

REMOTE_KEYWORDS = {
    "remote", "anywhere", "worldwide", "work from home", "wfh",
    "distributed", "fully remote", "100% remote",
}

NON_REMOTE_KEYWORDS = {
    "onsite", "on-site", "on site", "in-office", "in office",
    "hybrid", "must relocate", "relocation required", "must be located in",
    "must reside in",
}


def is_remote(text: str | None) -> bool:
    if not text:
        return False
    lowered = text.lower()
    if any(kw in lowered for kw in NON_REMOTE_KEYWORDS):
        return False
    return any(kw in lowered for kw in REMOTE_KEYWORDS)


def _sanitise_for_json(obj):
    if isinstance(obj, dict):
        return {k: _sanitise_for_json(v) for k, v in obj.items()}
    if isinstance(obj, list):
        return [_sanitise_for_json(v) for v in obj]
    if isinstance(obj, float):
        if math.isnan(obj) or math.isinf(obj):
            return None
    return obj


def emit_jobs(jobs: Iterable[dict]) -> None:
    json.dump(_sanitise_for_json(list(jobs)), sys.stdout, ensure_ascii=False)
    sys.stdout.write("\n")


def now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def clean(text: str | None, limit: int = 5000) -> str:
    if not text:
        return ""
    cleaned = re.sub(r"\s+", " ", text).strip()
    return cleaned[:limit]


def load_user_profile() -> dict:
    profile_path = os.getenv(
        "USER_PROFILE_PATH",
        "/home/node/scripts/user_profile.json",
    )
    try:
        with open(profile_path, "r", encoding="utf-8") as f:
            return json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        return {}
