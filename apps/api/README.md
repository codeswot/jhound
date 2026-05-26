# jhound-api

Read/control plane for jHound. NestJS + TypeORM. Reads job state from the existing Postgres (written by n8n). **Email = Resend. DB stores drafts only.**

## Architecture

```
n8n (scrape/score/auto-apply)──► Postgres (jobs, follow-ups, oss opps)
                                      ▲
                                      │
                                      │
                                      ▼
                                jhound-api ────► Flutter app
                                      │ ▲
                                      │ │
                          Resend API ─┘ └─ Resend webhooks
                          (sent + received emails — source of truth)
```

- **Jobs / follow-ups / opensource opps:** read directly from the existing Postgres tables n8n writes.
- **Emails (inbound, sent, threading state):** queried live from Resend. We do not mirror them. No `email_responses` / `sent_messages` reads in this API.
- **Drafts:** only thing the API itself writes to Postgres — a single `drafts` table from [migrations/001_drafts.sql](migrations/001_drafts.sql).
- **Real-time:** Resend webhooks → `POST /v1/webhooks/resend` → (Phase 1) WS broadcast. Svix signature verified.

## Endpoints (v1)

### Jobs (from Postgres)
| Method | Path | Notes |
|--------|------|-------|
| GET | `/v1/jobs?limit&offset&status&source&tier&q&sort` | filter + search |
| GET | `/v1/jobs/:id` | with follow-ups |

### Emails (from Resend, live)
| Method | Path | Notes |
|--------|------|-------|
| GET | `/v1/emails/inbox?limit&after&before` | Resend `GET /emails/receiving` |
| GET | `/v1/emails/inbox/:id` | full body |
| GET | `/v1/emails/inbox/:id/attachments/:attId` | binary stream |
| GET | `/v1/emails/sent?limit&after&before` | Resend `GET /emails` |
| GET | `/v1/emails/sent/:id` | full body |
| POST | `/v1/emails/send` | direct send, tags with `kind` + `job_id` |
| POST | `/v1/emails/inbox/:id/reply` | builds `In-Reply-To` + `References` headers |

### Drafts (DB)
| Method | Path | Notes |
|--------|------|-------|
| GET | `/v1/drafts?limit&offset&unsent_only` | |
| GET | `/v1/drafts/:id` | |
| POST | `/v1/drafts` | create |
| PATCH | `/v1/drafts/:id` | edit |
| DELETE | `/v1/drafts/:id` | only if unsent |
| POST | `/v1/drafts/:id/send` | sends via Resend; supports `Idempotency-Key` header |

### Stats / health
| Method | Path | |
|--------|------|--|
| GET | `/v1/stats/overview` | today/week, response rate, tier counts |
| GET | `/v1/stats/weekly` | view `application_stats` |
| GET | `/v1/stats/sources` | view `source_performance` |
| GET | `/v1/health` | public |

### Webhooks
| Method | Path | |
|--------|------|--|
| POST | `/v1/webhooks/resend` | Svix-verified Resend events (11 email + 6 domain/contact types) |

Auth on everything except `/v1/health` and `/v1/webhooks/*`: `Authorization: Bearer $API_TOKEN`. NIP-46 replacement coming.

## Why no email mirror

Source-of-truth duplication causes more bugs than it solves:

1. n8n's `email_sender.js` writes `sent_messages` and a separate `EmailService` reading the same Resend data would race it. Both writers fighting over the same row is the bug class we're avoiding.
2. Resend already stores HTML, headers, attachments, last_event, delivery state. Re-storing those locally just means we drift.
3. Threading uses RFC 5322 `In-Reply-To` + `References` headers, which Resend persists. The API builds those on reply so the conversation rope stays intact on the recipient side.
4. Job ↔ email correlation rides on Resend `tags` (`job_id`, `kind`, `source=jhound-api`) — readable on any future fetch.

Drafts are the exception: they don't exist anywhere else until sent.

## Dev (hot reload via compose)

```bash
# from repo root
cp .env.example .env  # set API_TOKEN, RESEND_API_KEY, POSTGRES_PASSWORD, ...
docker-compose up -d postgres api
docker-compose logs -f api

# apply drafts migration once
docker exec -i jHound-postgres psql -U jhound -d jhound < apps/api/migrations/001_drafts.sql

curl -H "Authorization: Bearer $API_TOKEN" http://localhost:3000/v1/stats/overview
curl -H "Authorization: Bearer $API_TOKEN" http://localhost:3000/v1/emails/inbox?limit=5
```

The `docker-compose.override.yml` runs `nest start --watch` against mounted `src/`.

## Prod / Dokploy

Dokploy uses `docker-compose.yml` only. Set env via Dokploy panel:

```
API_TOKEN=<long random>
CORS_ORIGINS=https://app.jhound.codeswot.dev
POSTGRES_PASSWORD=<existing>
RESEND_API_KEY=<existing>
RESEND_WEBHOOK_SECRET=<from Resend webhook config>
RESEND_FROM=mubarak@codeswot.me
NOSTR_TARGET_NPUB=<existing>
```

Service builds from `apps/api/Dockerfile`, exposes `:3000`, healthcheck `GET /v1/health`. Behind Dokploy Traefik → just point a domain at the `api` service. Configure Resend webhook URL to `https://api.jhound.codeswot.dev/v1/webhooks/resend` and copy the signing secret into `RESEND_WEBHOOK_SECRET`.

## Roadmap

- [x] Phase 0 — REST reads + drafts + Resend proxy + Svix-verified webhook receiver
- [ ] Phase 1 — socket.io gateway, broadcast Resend events to mobile clients
- [ ] Phase 2 — Flutter `apps/mobile` (Riverpod + Drift + bunker URI paste)
- [ ] Phase 3 — NIP-46 auth (replace bearer)
- [ ] Phase 4 — Nostr DM passthrough over WS (aligns with NIP-04 → White Noise migration)
