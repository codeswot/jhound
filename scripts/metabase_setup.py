#!/usr/bin/env python3
"""One-shot: set up Metabase admin + add jhound Postgres datasource via API.
Idempotent — skips if already configured.
"""
from __future__ import annotations

import json
import os
import sys
import time

import requests

METABASE_URL = os.getenv("METABASE_URL", "http://localhost:3000")
ADMIN_EMAIL = os.getenv("METABASE_ADMIN_EMAIL", "mubarak@codeswot.me")
ADMIN_PASSWORD = os.getenv("METABASE_ADMIN_PASSWORD", "")

DB_NAME = os.getenv("POSTGRES_DB", "jhound")
DB_HOST = os.getenv("POSTGRES_HOST", "postgres")
DB_PORT = int(os.getenv("POSTGRES_PORT", "5432"))
DB_USER = os.getenv("POSTGRES_USER", "jhound")
DB_PASS = os.getenv("POSTGRES_PASSWORD", "")


def _safe_json(resp, default=None):
    try:
        return resp.json()
    except Exception:
        return default or {}


def _die(msg: str):
    print(msg, file=sys.stderr)
    sys.exit(1)


def wait_healthy(timeout: int = 120) -> None:
    print(f"Waiting for Metabase at {METABASE_URL}...")
    deadline = time.time() + timeout
    while time.time() < deadline:
        try:
            r = requests.get(f"{METABASE_URL}/api/health", timeout=5)
            if r.status_code == 200:
                print("Metabase healthy.")
                return
        except Exception:
            pass
        time.sleep(3)
    _die(f"Metabase not healthy after {timeout}s")


def get_session() -> str:
    resp = requests.post(
        f"{METABASE_URL}/api/session",
        json={"username": ADMIN_EMAIL, "password": ADMIN_PASSWORD},
        timeout=15,
    )
    if resp.status_code == 200:
        data = _safe_json(resp)
        sid = data.get("id")
        if sid:
            return sid
    _die(f"Login failed ({resp.status_code}): {resp.text[:300]}")


def datasource_exists(token: str) -> bool:
    resp = requests.get(
        f"{METABASE_URL}/api/database",
        headers={"X-Metabase-Session": token},
        timeout=15,
    )
    if resp.status_code != 200:
        return False
    for db in (_safe_json(resp).get("data") or []):
        if db.get("name") == "jHound Postgres":
            return True
    return False


def add_datasource(token: str) -> dict:
    payload = {
        "name": "jHound Postgres",
        "engine": "postgres",
        "details": {
            "host": DB_HOST,
            "port": DB_PORT,
            "dbname": DB_NAME,
            "user": DB_USER,
            "password": DB_PASS,
            "ssl": False,
        },
    }
    resp = requests.post(
        f"{METABASE_URL}/api/database",
        json=payload,
        headers={"X-Metabase-Session": token},
        timeout=30,
    )
    if resp.status_code not in (200, 201):
        msg = _safe_json(resp).get("message", resp.text)[:300]
        _die(f"Add datasource failed ({resp.status_code}): {msg}")
    return {"ok": True, "id": _safe_json(resp).get("id")}


def main() -> None:
    if not ADMIN_PASSWORD:
        _die("METABASE_ADMIN_PASSWORD not set")

    wait_healthy()

    # Check if setup already done by trying login
    try:
        token = get_session()
        print("Admin already exists. Logged in.")
    except SystemExit:
        # Setup needed — use the setup endpoint
        print("Running first-time setup...")

        # Fetch setup token from properties
        props_resp = requests.get(f"{METABASE_URL}/api/session/properties", timeout=15)
        setup_token = (_safe_json(props_resp) or {}).get("setup-token")
        if not setup_token or setup_token == "null":
            _die(f"No setup-token in properties. Status={props_resp.status_code}. Body={props_resp.text[:500]}")

        # Complete setup
        setup_payload = {
            "token": setup_token,
            "user": {
                "first_name": "Mubarak",
                "last_name": "Ibrahim",
                "email": ADMIN_EMAIL,
                "password": ADMIN_PASSWORD,
            },
            "prefs": {
                "site_name": "jHound",
                "site_locale": "en",
                "allow_tracking": False,
            },
        }
        setup_resp = requests.post(
            f"{METABASE_URL}/api/setup",
            json=setup_payload,
            timeout=30,
        )

        if setup_resp.status_code not in (200, 201):
            body = setup_resp.text[:500]
            _die(f"Setup failed ({setup_resp.status_code}): {body}")

        token = (_safe_json(setup_resp) or {}).get("id")
        if not token:
            _die(f"Setup returned no session id: {setup_resp.text[:500]}")
        print("Setup complete. Logged in.")

    # Add datasource
    if datasource_exists(token):
        print("Datasource 'jHound Postgres' already exists. Done.")
        return

    print(f"Connecting Metabase to Postgres at {DB_HOST}:{DB_PORT}/{DB_NAME} as {DB_USER}...")
    result = add_datasource(token)
    print(f"Added jHound Postgres datasource (id={result['id']}).")


if __name__ == "__main__":
    main()
