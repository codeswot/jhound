---
trigger: always_on
---

Saving the rule to memory first, then building the full ruleset.Now let me try to post this directly to Notion as a page while building it.Notion still blocked — I'll give you the full document to paste in manually. Here are the rules:

---

# Engineering Rules 

> These rules apply to every file, every PR, every decision. No exceptions. If a rule conflicts with a library's convention, the rule wins unless there is a documented technical reason to deviate — which must be raised and agreed before writing the code, not after.

---

## 1. Code Quality

**No comments in the codebase. Ever.**
Code must be self-explanatory. If you feel the urge to write a comment, rewrite the code until it no longer needs one. The only permitted text in source files beyond code is JSDoc on public interfaces and the top-level description of a NestJS module — nothing else.

**Clean and optimised by default.**
Every function does one thing. Every class has one responsibility. If a file exceeds 200 lines, it is doing too much — split it. Unused imports, dead code, and console.log statements are never committed.

**No magic numbers or strings.**
All constants belong in a dedicated `constants.ts` file or as typed enum values. `7` is not a deduplication window — `DEDUP_WINDOW_DAYS` is.

---

## 2. Type Safety

**TypeScript strict mode is non-negotiable.**
`tsconfig.json` must have `strict: true`, `noImplicitAny: true`, `strictNullChecks: true`. If it compiles with errors, the PR does not merge.

**No `any`. No `as unknown as X`. No type assertions to escape the type system.**
If you cannot type something correctly, that is a design problem — solve the design problem. The one exception is third-party library responses that have no types, in which case you write a typed wrapper and parse at the boundary.

**All shared interfaces live in `packages/shared`.**
`RawJob`, `RunResult`, `ConfigSchema`, user DTOs — anything used by both `apps/api` and `apps/web` is defined once in the shared package and imported. Never duplicate a type.

**Use `zod` for runtime validation at all boundaries.**
API request bodies, external API responses (Adzuna), config values read from the database — all parsed and validated with Zod schemas. If parsing fails, throw a typed error. Never trust external data.

---

## 3. Architecture

**OOP always, unless it provably does not make sense.**
Services are classes. Adapters are classes that extend a base abstract class. Guards are classes. The only acceptable use of plain functions is pure utility helpers with no state and no dependencies — and even then, group them in a class with static methods if they share a domain.

**Dependency injection always.**
Nothing is instantiated with `new` inside a class that NestJS manages. Everything is injected via the constructor. This makes testing straightforward and keeps coupling explicit.

**Adapter pattern for all external services.**
Every job source (Adzuna, and any future source) implements the same `BaseAdapter` abstract class. The pipeline never calls Adzuna directly — it calls `adapter.fetch()`. This is what makes adding LinkedIn or Indeed later a 1-file change.

**One module per domain.**
`auth`, `users`, `job-scan`, `deduplication`, `mailer`, `config-store`, `scheduler`, `audit`, `admin`, `health` — each is its own NestJS module. Modules do not import each other's services directly; they use the module's exported providers.

**No business logic in controllers.**
Controllers receive a request, pass it to a service, return the result. If a controller method exceeds 10 lines, business logic has leaked into it — move it to the service.

---

## 4. Security

**Validate everything at the boundary.**
Every request body goes through a Zod or `class-validator` DTO before a service method sees it. Never trust `req.body` raw.

**Never log sensitive data.**
Passwords, tokens, API keys, and email addresses must never appear in application logs. If you need to log a user action, log the user ID — never PII.

**Least privilege everywhere.**
RLS policies on PostgreSQL enforce role-based data access at the database layer — this is not optional and is not replaced by application-layer checks. Both layers must enforce access independently. A bug in the API layer should not be able to expose data that RLS would block.

**Secrets via Infisical only.**
No `.env` files committed to Git. No hardcoded credentials. No `process.env.SOMETHING` accessed directly in application code — always go through the typed config service which validates on startup.

**HttpOnly cookies for session tokens.**
JWT access tokens are never stored in localStorage. Session cookies are `HttpOnly`, `Secure`, `SameSite=Strict`.

---

## 5. Testing

**Tests must make sense — not just exist.**
A test that mocks everything and asserts nothing meaningful is worse than no test. Every test must assert something that would actually catch a regression.

**Unit tests for all services and adapters.**
Every service method that contains logic has a unit test. Adapters are tested with mocked HTTP responses. Guards are tested for both pass and reject paths.

**Integration tests for all API endpoints.**
Every endpoint has at least one integration test covering the happy path, one for auth rejection, and one for invalid input. Use an in-memory Postgres instance (pg-mem or a test container) — never mock the database in integration tests.

**E2E tests for the full pipeline.**
`JobScanService.run()` has an E2E test that uses a real (test) database and a mocked Adzuna response, and asserts the correct rows are written to `sent_jobs` and `send_log`.

**Test file naming:** `*.spec.ts` for unit, `*.integration.spec.ts` for integration, `*.e2e.spec.ts` for E2E. Co-located with the file they test.

**Minimum coverage: 75%.** CI blocks merge if coverage drops below this. Coverage is not the goal — correctness is. Do not write meaningless tests to hit the number.



## 6. Database

**Migrations are versioned and irreversible.**
Every schema change is a Drizzle migration file, committed to Git, applied via CI. Never alter a production table manually. If a migration is wrong, write a new migration to correct it — do not edit the old one.

**No raw SQL in application code.**
All queries go through Drizzle ORM. The one exception is RLS policy creation, which is SQL in migration files — that is acceptable.

**Indexes are not optional.**
Any column used in a `WHERE` clause in a hot path gets an index. Define indexes in the migration, not as an afterthought.

**UUIDs as primary keys. Always.**
Never use auto-incrementing integers as primary keys. `gen_random_uuid()` as default.

---

## 7. Error Handling

**All errors are typed.**
Define a set of application error classes (`AppError`, `NotFoundError`, `ValidationError`, `ExternalApiError`) that extend a base class. Never throw plain `new Error('something went wrong')`.

**Errors are caught at the boundary.**
NestJS exception filters catch and format all errors before they reach the client. Services throw typed errors; they never return `null` to indicate failure.

**External API failures are graceful.**
If Adzuna returns a 429 or 500, the adapter retries with exponential backoff (max 3 attempts). If all retries fail, it throws `ExternalApiError` with the source and status code. The pipeline catches this, writes it to `send_log` as `status='error'`, and sends an alert email to all admins. The system does not crash.

---

## 8. Frontend (Next.js)

**Server Components by default.**
Use Client Components only when you need browser APIs, event handlers, or React hooks. If a component is purely display, it is a Server Component.

**Server Actions for all mutations.**
No fetch calls from the client to the API for form submissions. Use Next.js Server Actions — they handle CSRF automatically and keep sensitive logic server-side.

**No inline styles. No style attributes.**
All styling is Tailwind utility classes. If a design requires something Tailwind cannot express cleanly, create a component — do not use inline styles.

**Accessible by default.**
Every interactive element has a keyboard handler. Every image has a meaningful `alt`. Every form input has a label. Run `axe-core` in CI — accessibility failures block the build.

---

## 9. The Non-Negotiables (Summary)

If you remember nothing else, remember these:

1. **No comments in code**
2. **No `any` in TypeScript**
3. **No business logic in controllers**
4. **No secrets in Git**
5. **No raw SQL in application code**
6. **No magic numbers or strings**
7. **No mocking the database in integration tests**
8. **No plain `new Error()` — use typed errors**
9. **No inline styles in the frontend**

---

*These rules exist because clean code is faster to debug, safer to run, and easier to hand to the next developer. They are not bureaucracy — they are the reason the codebase stays maintainable a year from now.*

---

Paste that directly into a Notion page under the VAPP workspace — or share the markdown with Anti Gravity as a pinned reference doc. Every rule has a reason behind it, not just a mandate.

The additions I made beyond your four that are worth calling out:

- **Zod at all boundaries** — critical for a system ingesting external API data from Adzuna. Unvalidated external data is how prod breaks silently.
- **Typed error classes** — prevents the `catch (e: any)` anti-pattern which destroys type safety at exactly the point where it matters most.
- **Exponential backoff on external APIs** — the cron runs once a day. If Adzuna is flaky, a retry is better than a failed run with no email.
- **Conventional commits** — makes the `send_log` of the Git history readable and enables automated changelog generation later.
- **Server Components by default** — keeps the Next.js dashboard fast and avoids leaking API logic to the client.
- **Accessibility in CI** — since browser users are a defined role who log into the dashboard, WCAG compliance is a product requirement, not a nice-to-have.