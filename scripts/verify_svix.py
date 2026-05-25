#!/usr/bin/env python3
from __future__ import annotations

import base64
import hashlib
import hmac
import json
import os
import sys
import time

TOLERANCE_SECONDS = 5 * 60


def _emit(payload: dict) -> None:
    json.dump(payload, sys.stdout, ensure_ascii=False)
    sys.stdout.write("\n")


def _header(headers: dict, name: str) -> str | None:
    if not headers:
        return None
    target = name.lower()
    for k, v in headers.items():
        if k.lower() == target:
            return v if isinstance(v, str) else (v[0] if v else None)
    return None


def main() -> None:
    payload = json.load(sys.stdin)
    secret_env = os.getenv("RESEND_WEBHOOK_SECRET", "").strip()

    if not secret_env:
        _emit({"ok": True, "reason": "no_secret_configured"})
        return

    headers = payload.get("headers") or {}
    svix_id = _header(headers, "svix-id")
    svix_ts = _header(headers, "svix-timestamp")
    svix_sig = _header(headers, "svix-signature")

    if not (svix_id and svix_ts and svix_sig):
        _emit({"ok": False, "reason": "missing_svix_headers"})
        return

    try:
        ts_int = int(svix_ts)
    except ValueError:
        _emit({"ok": False, "reason": "bad_timestamp"})
        return

    if abs(time.time() - ts_int) > TOLERANCE_SECONDS:
        _emit({"ok": False, "reason": "timestamp_out_of_range"})
        return

    raw_body = payload.get("raw_body")
    if raw_body is None:
        raw_body = json.dumps(payload.get("body") or {}, separators=(",", ":"))

    if secret_env.startswith("whsec_"):
        try:
            secret_bytes = base64.b64decode(secret_env[len("whsec_"):])
        except Exception:
            _emit({"ok": False, "reason": "bad_secret_encoding"})
            return
    else:
        secret_bytes = secret_env.encode("utf-8")

    signed_payload = f"{svix_id}.{svix_ts}.{raw_body}".encode("utf-8")
    expected = base64.b64encode(
        hmac.new(secret_bytes, signed_payload, hashlib.sha256).digest()
    ).decode("utf-8")

    for entry in svix_sig.split():
        version, _, sig = entry.partition(",")
        if version != "v1":
            continue
        if hmac.compare_digest(sig, expected):
            _emit({"ok": True, "reason": "signature_match"})
            return

    _emit({"ok": False, "reason": "no_matching_signature"})


if __name__ == "__main__":
    main()
