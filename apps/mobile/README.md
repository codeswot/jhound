# jhound_mobile

Flutter control app for jHound. Pairs with `jhound-api` via paste-token (NIP-46 next), then renders dashboard / jobs / inbox / drafts in real time over WebSocket.

## Stack

- Flutter 3.22+ / Dart 3.4+
- Riverpod (state)
- go_router (not strictly needed yet — using IndexedStack shell; reserved for deep links)
- dio (REST)
- socket_io_client (WS, `/v1/ws`)
- Drift + sqlite3 (local cache + offline drafts)
- flutter_secure_storage (token persistence)

## Architecture

```
SettingsStorage (secure) ──► ApiConfig ──► ApiClient (dio)
                                  └────► SocketClient (socket.io)
ApiClient ─► Repositories ─► Riverpod FutureProviders ─► Screens
SocketClient ── invalidate ───────────────────────────────┘
```

- **No email mirror.** Inbox + sent come live from the API, which proxies Resend.
- **Drafts** persist server-side; Drift table reserved for future offline-first compose (today the compose screen hits the API directly).
- **Real-time:** server broadcasts `job.*`, `email.*`, `followup.sent`, `oss.discovered`. `syncBootstrapProvider` wires those into Riverpod invalidations.

## Bootstrap (first time)

`apps/mobile` ships only `lib/` + `pubspec.yaml`. Generate platform projects + drift codegen:

```bash
cd apps/mobile
flutter create .                    # adds android/ ios/ macos/ web/ linux/ windows/
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # generates app_db.g.dart
flutter run
```

Pair screen accepts:

- **API base URL** — e.g. `http://localhost:3000` (sim/emulator: use `http://10.0.2.2:3000` on Android emulator, host machine IP on iOS device)
- **API token** — value of `API_TOKEN` from the root `.env`

Token + base URL stored in OS keychain (`flutter_secure_storage`).

## Screens

- `PairingScreen` — first-launch token paste.
- `HomeShell` — NavigationBar with 4 tabs.
- `DashboardScreen` — stats overview + last 7 days.
- `JobsScreen` — paginated list, tier filter, search by company/title.
- `InboxScreen` — Inbox + Sent tabs (Resend `GET /emails/receiving` / `GET /emails`).
- `DraftsScreen` + `DraftComposeScreen` — manual compose / edit / send.

## Real-time wiring

`HomeShell` watches `syncBootstrapProvider` which:

1. Reads `apiConfigProvider`.
2. Opens socket.io to `<wsUrl>/v1/ws` with `auth: { token }`.
3. Subscribes to `job.created`, `job.updated`, `followup.sent`, `oss.discovered`, all 11 `email.*` Resend events.
4. Each event triggers `ref.invalidate(...)` on the matching `FutureProvider` so the visible list refetches.

`SyncIndicator` (top right of dashboard) reflects connection state from `syncConnectionProvider`.

## Roadmap

- [x] Phase 2 — REST + WS + dashboard / jobs / inbox / drafts MVP
- [ ] Phase 3 — Drift-backed offline drafts + jobs cache (codegen wired, repos not yet writing through)
- [ ] Phase 4 — NIP-46 pairing (replace paste-token), bunker URI screen
- [ ] Phase 5 — Email detail (HTML render via `flutter_html`), reply flow from inbox tile
- [ ] Phase 6 — Push notifications on `email.received` for tier-1 jobs
