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
|---|---|
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

The custom n8n image (built from `Dockerfile.n8n`) bakes in Python 3, all Python deps, and Node deps. No more `pip install` / `npm install` post-boot steps.

## Local development (Apple Silicon — M-series Macs)

All images are multi-arch (`linux/arm64`). The image is browser-free: JobSpy uses TLS-level requests, email finding goes through Hunter.io / Apollo APIs, and notifications go through Nostr encrypted DMs (relay WebSockets, no Chromium, no phone). Total image is ~400 MB Python+Node only.

- **Ollama Cloud** is required. Set `OLLAMA_API_KEY` in `.env` (sign up at [ollama.com](https://ollama.com)).
- **Build time**: first `make up` builds the image (~1-2 min on M4 Pro). Subsequent runs use the cached image. After any change to `requirements.txt` or `package.json`, run `make build` to rebuild.
- **Nostr**: encrypted DMs via [nostr-tools](https://github.com/nbd-wtf/nostr-tools) (NIP-04 kind-4). See "Nostr DMs" section below.

### Dev-only overrides

Copy `docker-compose.override.yml.example` → `docker-compose.override.yml` (gitignored) to enable:
- Exposing Postgres/Redis on host ports for psql/RedisInsight
- `N8N_LOG_LEVEL=debug`
- `restart: no` so crashes don't loop during iteration

### Running tests on the host

`make test` creates a `.venv-test/` (gitignored) with just the deps the tests need, then runs them locally. No Docker required for tests.

## Production deployment (Dokploy on Debian 13 VPS)

Dokploy uses Docker Compose under the hood. With a domain you get Traefik+TLS; without a domain you access services by `<vps-ip>:<port>`.

- **Internal services** (`postgres`, `redis`) bind no host ports → not reachable from public internet, only over the internal Docker network.
- **Host-published ports** (compose `ports:`):
  - `5678` — n8n UI + webhooks
  - `3001` — Metabase (default `METABASE_HOST_PORT`, set in `.env`). **Dokploy itself uses 3000**, so do not map Metabase there.
  - `5050` — pgAdmin (only with `--profile admin`)
- **Healthchecks** on every service give Dokploy accurate up/down status.
- Named volumes (`n8n_data`, `postgres_data`, `redis_data`, `metabase_data`) persist across deploys.

### Steps in Dokploy (no-domain, IP-only deploy)

1. **Create application** → type: `Docker Compose` → connect this repo (or paste the compose file).
2. **Build** uses `Dockerfile.n8n` automatically (compose `build:` context).
3. **Environment** tab → paste your `.env`. Critical values for IP-only deploy:
   - `WEBHOOK_URL=http://<vps-ip>:5678` (Resend + n8n external webhook callers reach this)
   - `N8N_INTERNAL_URL=http://localhost:5678` (the Nostr listener uses this — internal, no public round-trip)
   - `METABASE_HOST_PORT=3001` (or any free port; do NOT use 3000 — that's Dokploy)
4. **Domains** tab → leave empty if no domain. Otherwise add domain → port `5678` → enable HTTPS.
5. **Deploy**. First build ~1–2 min, subsequent deploys reuse cache.

After deploy, services are reachable at:
- n8n UI: `http://<vps-ip>:5678`
- Metabase: `http://<vps-ip>:3001`

### Post-deploy one-time setup

```bash
# SSH into the VPS (Dokploy doesn't expose `docker exec` from its UI)
ssh user@vps

# Smoke test
docker exec -it jHound-n8n python3 /home/node/tests/test_pipeline.py
```

Then:

- Open `http://<vps-ip>:5678` (or your domain). Workflows auto-import + activate on first boot.
- In Resend dashboard, set the inbound webhook URL to `http://<vps-ip>:5678/webhook/${RESEND_WEBHOOK_PATH}` (or `https://your-domain/...` if you have one) and copy the Svix secret into `RESEND_WEBHOOK_SECRET`.

### What Dokploy buys you

- Push-to-deploy from git
- Auto-TLS via Traefik
- Container logs in the UI
- Restart policies tied to healthcheck state
- One-click rollback to a previous deploy

### Caveats

- **Nostr keypair** is stored in `.env` only (`NOSTR_NSEC` + `NOSTR_TARGET_NPUB`). Rotate freely with `nostr_notifier.js keygen`; queued (undelivered) DMs sit at `/tmp/jhound_wa_queue.json` inside the container and survive container restarts only if the path is volume-mounted.
- **Resources folder** (`./resources/cv.docx` + recommendation PDFs) ships with the repo — make sure they're committed (or at least present on the VPS) before deploy.

```
make up               # build + start
make logs             # tail n8n
make ps               # service status
make shell            # sh into n8n container
make db-shell         # psql into Postgres
make clean-cache      # clear pycache + Hunter quota Redis keys
make down             # stop (volumes survive)
```

## Nostr DMs (notifications)

jHound uses Nostr encrypted DMs (NIP-04) for notifications. No phone numbers, no Meta, no business verification. Messages arrive in any Nostr client (Damus, Amethyst, Primal, etc.).

**One-time setup:**
```bash
# Generate a keypair from inside the container
docker exec -it jHound-n8n node /home/node/scripts/nostr_notifier.js keygen
# Output: {"nsec":"nsec1...","npub":"npub1..."}
```

- Paste `nsec` → `NOSTR_NSEC` in `.env` (the bot's private key)
- Paste `npub` → `NOSTR_TARGET_NPUB` in `.env` (your personal npub to receive DMs)
- Find your personal npub in your Nostr client settings (Damus: Profile → Share → Copy npub)

The bot sends encrypted DMs to `NOSTR_TARGET_NPUB` via 3 default relays (`relay.damus.io`, `relay.primal.net`, `nos.lol`). Override with `NOSTR_RELAYS` in `.env`.

## Project layout

```
jhound/
├── desc.md                    # Full design spec
├── docker-compose.yml         # All services
├── .env.example               # Env template
├── scripts/
│   ├── user_profile.json      # Single source of truth for skills/preferences
│   ├── init.sql               # Postgres schema
│   ├── scrapers/              # LinkedIn + generic board scrapers
│   ├── ai/                    # Ollama: tier scoring + email drafting
│   ├── automation/            # Easy Apply bot
│   ├── email_finder.py        # Google + Hunter.io email lookup
│   ├── opensource_finder.py   # GitHub bounty / grant discovery
│   ├── nostr_notifier.js      # Nostr encrypted DMs (NIP-04, relay WebSockets)
│   ├── email_sender.js        # Resend wrapper with CV attachments
│   └── package.json
├── workflows/                 # n8n workflow JSON exports
└── resources/                 # CV + recommendation letters (mounted into containers)
```

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

In production behind Dokploy, route `metabase.<domain>` to port 3000 via Traefik.

### Suggested dashboard cards

| Card | Query / view |
|---|---|
| Applications per day (last 30d) | `SELECT date, total_applications FROM application_stats ORDER BY date DESC LIMIT 30` |
| Response rate by source | `source_performance` view |
| Tier-1 vs Tier-2 split | `application_stats` view (`tier1_count`, `tier2_count`) |
| Workflow health (errors last 30d) | `workflow_health` view |
| Recent errors | `SELECT workflow_name, message, created_at FROM execution_logs WHERE status='error' ORDER BY created_at DESC LIMIT 20` |
| Manual review queue | `needs_manual_review` view |
| Rejection reasons | `rejection_breakdown` view |
| OSS opportunities | `SELECT title, repository, bounty_amount, relevance_score FROM opensource_opportunities ORDER BY discovered_at DESC LIMIT 50` |

## Resume variants per tier

`scripts/email_sender.js` picks attachments based on `tier` in the payload:

| Tier | Primary CV attached | Falls back to |
|---|---|---|
| 1 (Bitcoin/Nostr/OSS) | `resources/cv_tier1.docx` if present | `resources/cv.docx` |
| 2 (other remote) | `resources/cv.docx` | — |

To enable tier-1 tailoring, drop a Bitcoin/Nostr-focused CV at `resources/cv_tier1.docx`. The file is renamed to `cv.docx` on the email attachment so the recipient sees a normal filename. Recommendation PDFs always go along regardless of tier.

## Manual approval via Nostr DM reply (workflow 08)

Tier-1 fast-apply sends a Nostr DM with the job link and marks the row `awaiting_user_apply` in Postgres. A long-running listener (`nostr_notifier.js listen`, started by the container entrypoint when `NOSTR_NSEC` + `NOSTR_TARGET_NPUB` are set) subscribes to incoming kind-4 DMs from your `NOSTR_TARGET_NPUB`, decrypts them, and POSTs the plain text to the `jhound-nostr-inbound` webhook (workflow 08). Reply with `applied 3` / `skip 3` (or similar, parsed by workflow 08) to update the matching row.

## Workflow error handling

`workflows/07_error_handler.json` is auto-attached to every workflow via the `N8N_DEFAULT_ERROR_WORKFLOW=jhound07errorhandler` env var on the n8n service. On any node failure it:

1. Writes a row into `execution_logs` (workflow_name, execution_id, failed node, error message).
2. Sends a Nostr DM alert via `nostr_notifier.js error-alert`.

The Discovery workflow also writes a `success` row to `execution_logs` at the end of each Friday run, so the `workflow_health` view tells you "last successful Discovery: X days ago" without parsing n8n logs.

## Tier scoring rules

These live in [scripts/user_profile.json](./scripts/user_profile.json) and are enforced in [scripts/ai/job_filter.py](./scripts/ai/job_filter.py).

| Outcome | Condition |
|---|---|
| **Hard reject** | Onsite, hybrid, geographically restricted, or `is_remote=false` from scraper |
| **Tier 1 (80-100)** | Bitcoin / Nostr / Lightning / Open Source / Decentralized |
| **Tier 2 (50-79)** | Any remote tech role overlapping with the user's skills |
| **Soft reject** | AI score below 50 |

Tier 1 jobs are applied to first.

## Testing individual components

```bash
# Scrape via JobSpy (LinkedIn + Indeed + Glassdoor + ZipRecruiter + Google Jobs)
docker exec -it jHound-n8n python3 /home/node/scripts/scrapers/jobspy_scraper.py --keywords Bitcoin Nostr --results-per-keyword 10

# Scrape RemoteOK
docker exec -it jHound-n8n python3 /home/node/scripts/scrapers/generic_scraper.py --source remoteok --keywords Bitcoin Nostr

# Score one job through the AI filter
echo '[{"job_title":"Senior Backend","company":"Acme","job_description":"Build Bitcoin payment rails","location":"Remote","is_remote":true,"job_url":"https://example.com/1","source_board":"test"}]' \
  | docker exec -i jHound-n8n python3 /home/node/scripts/ai/job_filter.py

# Open-source opportunity finder
docker exec -it jHound-n8n python3 /home/node/scripts/opensource_finder.py --skills Bitcoin Nostr Flutter --min-bounty 100

# Nostr test
docker exec -it jHound-n8n sh -c "printf %s 'jHound online' | node /home/node/scripts/nostr_notifier.js send -"
```
