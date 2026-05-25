from __future__ import annotations

import json
import os
import sys
import time

import requests

OLLAMA_API_KEY = os.getenv("OLLAMA_API_KEY", "").strip()
OLLAMA_HOST = "https://ollama.com"
DEFAULT_MODEL = os.getenv("OLLAMA_MODEL", "gpt-oss:120b-cloud")
REQUEST_TIMEOUT = int(os.getenv("OLLAMA_TIMEOUT", "180"))
MAX_RETRIES = int(os.getenv("OLLAMA_MAX_RETRIES", "3"))


def _headers() -> dict:
    if not OLLAMA_API_KEY:
        raise RuntimeError("OLLAMA_API_KEY is required — get one at https://ollama.com")
    return {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {OLLAMA_API_KEY}",
    }


def generate(prompt: str, model: str | None = None, json_mode: bool = False, temperature: float = 0.2) -> str:
    payload = {
        "model": model or DEFAULT_MODEL,
        "prompt": prompt,
        "stream": False,
        "options": {"temperature": temperature},
    }
    if json_mode:
        payload["format"] = "json"

    last_exc = None
    for attempt in range(MAX_RETRIES):
        try:
            resp = requests.post(
                f"{OLLAMA_HOST}/api/generate",
                json=payload,
                headers=_headers(),
                timeout=REQUEST_TIMEOUT,
            )
            resp.raise_for_status()
            body = resp.json()
            text = (body.get("response") or "").strip()
            if not text:
                print(f"ollama empty response (attempt {attempt+1})", file=sys.stderr)
                time.sleep(2 ** attempt)
                continue
            return text
        except requests.Timeout:
            last_exc = RuntimeError(f"Ollama timed out after {REQUEST_TIMEOUT}s")
            print(f"ollama timeout (attempt {attempt+1})", file=sys.stderr)
        except requests.RequestException as exc:
            last_exc = exc
            code = getattr(getattr(exc, "response", None), "status_code", None)
            if code and code < 500:
                raise
            print(f"ollama HTTP error (attempt {attempt+1}): {exc}", file=sys.stderr)
        time.sleep(2 ** attempt)

    raise last_exc or RuntimeError("Ollama request failed after retries")


def generate_json(prompt: str, model: str | None = None, temperature: float = 0.1) -> dict:
    raw = generate(prompt, model=model, json_mode=True, temperature=temperature)
    try:
        result = json.loads(raw)
        if not isinstance(result, dict):
            raise json.JSONDecodeError("Not a dict", raw, 0)
        return result
    except json.JSONDecodeError:
        start = raw.find("{")
        end = raw.rfind("}")
        if start >= 0 and end > start:
            return json.loads(raw[start:end + 1])
        print(f"ollama unparseable JSON: {raw[:300]}", file=sys.stderr)
        raise
