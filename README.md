# jHound

> Fully automated, zero-cost remote job hunting. AI-filtered, tier-prioritised, self-hosted.

**Author:** Mubarak Ibrahim ([codeswot.me](https://codeswot.me))

See [desc.md](./desc.md) for the full architecture, design rationale, and tier-scoring rules. This README is the quick start.

## What it does

- **Discovers** remote jobs **every Friday morning** from multiple boards. LinkedIn, Indeed, Glassdoor, ZipRecruiter, and Google Jobs run through [JobSpy](https://github.com/Bunsly/JobSpy) (single maintained lib, no DIY selectors). RemoteOK, WeWorkRemotely, Cryptocurrency Jobs, Bitcoiner Jobs, and HN Who is Hiring run through [scripts/scrapers/generic_scraper.py](./scripts/scrapers/generic_scraper.py).
- **Hard-rejects** anything non-remote.
- **Scores** the rest with Ollama into two tiers: Tier 1 (Bitcoin/Nostr/Lightning/Open Source) and Tier 2 (any remote tech role matching the user's stack).
- **Applies** via LinkedIn Easy Apply or cold email (with CV + 2 recommendation letters attached).
- **Tracks** everything in Postgres, **notifies** via Nostr encrypted DMs (any Nostr client, free, no phone number).
- **Finds** paid open-source opportunities (bounties + Bitcoin/Nostr grant work) **Mon-Fri, 1/day**.

## Cadence

The system runs on a weekly rhythm — applications in a single Friday batch, with daily/hourly observability tasks running in the background.

| When | What |
| --- | --- |  
| **Fri 08:00 WAT** | Discovery: 3 parallel scraper groups (JobSpy / generic / Wellfound) → AI filter → tier 1+2 → trigger applications |
| **Fri 08:30–17:00** | Applications: Easy Apply or email-with-CV+letters → company research → tier-1 Nostr brief instant, tier-2 batched |
| **Fri 17:00** | Manual review digest (suppressed when queue empty) |
| **Fri 20:00** | Daily Nostr summary (today + week breakdown) + flush tier-2 batch |
| **Sun 18:00** | Weekly digest: HTML email + Nostr per-job batch (title, contact, website) |
| **Mon-Fri 09:00** | Open-source discovery (1/day) → Nostr alert |
| **Daily 10:00** | Follow-up sweep (mostly a no-op) |
| **Every 6h** | Resend inbound webhook + backfill → Svix verify → classify → DB → Nostr alert |

## Quick start

```bash
cp .env.example .env
# fill in at minimum: N8N_INSTANCE_OWNER_PASSWORD, POSTGRES_PASSWORD, RESEND_API_KEY,
# NOSTR_NSEC, NOSTR_TARGET_NPUB, OLLAMA_API_KEY (required — get one at https://ollama.com)

make up               # builds the custom n8n image, starts all services
make test-in-docker   # smoke-test the pipeline (20 tests, ~0.5s)

# Open http://localhost:5678 — owner auto-created, workflows auto-imported
# Open http://localhost:3000 — Metabase dashboards
# See Nostr DMs section below to configure notifications
```

The custom n8n image (built from `Dockerfile.n8n`) bakes in Python 3, all Python deps, and Node deps. `pip install` / `npm install` post-boot steps.

## Nostr DMs (notifications)

jHound uses Nostr encrypted DMs (NIP-04) for notifications.

**One-time setup:**

```bash
# Generate a keypair from inside the container
docker exec -it jHound-n8n node /home/node/scripts/nostr_notifier.js keygen
or bring you own nsec
# Output: {"nsec":"nsec1...","npub":"npub1..."}
```

- Paste `nsec` → `NOSTR_NSEC` in `.env` (the bot's private key)
- Paste `npub` → `NOSTR_TARGET_NPUB` in `.env` (your personal npub to receive DMs)
- Find your personal npub in your Nostr client settings (Damus: Profile → Share → Copy npub)

The bot sends encrypted DMs to `NOSTR_TARGET_NPUB` via 3 default relays (`relay.damus.io`, `relay.primal.net`, `nos.lol`). Override with `NOSTR_RELAYS` in `.env`.

## Dashboard (Metabase)

Metabase ships in `docker-compose.yml` and stores its own state in the same Postgres instance (separate `metabase` database, auto-created by `init.sql`). It reads the `jhound` database read-only via the credentials you set up in the Metabase UI.

```bash
# Already running once `make up` is up
open http://localhost:3000

# First boot:
# 1. Create admin user
# 2. Add database → PostgreSQL
#    Host: postgres   Port: 5432   DB: jhound
#    User: jhound     Pass: $POSTGRES_PASSWORD
# 3. Build dashboards off the existing views:
#    application_stats, source_performance, awaiting_followup,
#    needs_manual_review, rejection_breakdown
```

## Manual approval via Nostr DM reply (workflow 08)

Tier-1 fast-apply sends a Nostr DM with the job link and marks the row `awaiting_user_apply` in Postgres. A long-running listener (`nostr_notifier.js listen`, started by the container entrypoint when `NOSTR_NSEC` + `NOSTR_TARGET_NPUB` are set) subscribes to incoming kind-4 DMs from your `NOSTR_TARGET_NPUB`, decrypts them, and POSTs the plain text to the `jhound-nostr-inbound` webhook (workflow 08). Reply with `applied 3` / `skip 3` (or similar, parsed by workflow 08) to update the matching row.
