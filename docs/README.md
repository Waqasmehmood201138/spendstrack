# SpendsTrack Documentation

SpendsTrack is a Splitwise clone: shared expense tracking with groups, friends,
flexible splits, balance simplification, and settle-up. Flutter client,
Supabase (Postgres + Auth + Realtime) backend.

- [architecture.md](./architecture.md) — app structure, state management, routing, conventions
- [database-schema.md](./database-schema.md) — full Postgres schema, RLS model, balance/debt-simplification design
- [features-roadmap.md](./features-roadmap.md) — what's built, what's next, and what needs external services
- [setup.md](./setup.md) — local dev setup: Flutter SDK, Supabase project, running the app

## Quick facts

- Flutter SDK is pinned to **3.24.5** / Dart **^3.5.4** — the dev machine runs macOS 12.7.6, which cannot
  run newer Flutter/Dart toolchains (they require macOS 14+). See [setup.md](./setup.md).
- Backend is Supabase. Schema lives in `supabase/migrations/`, applied via the Supabase SQL editor or CLI.
- No code generation (no freezed, no riverpod_generator) — see [architecture.md](./architecture.md#no-codegen) for why.
