# Setup

## Flutter SDK

Pinned to **3.24.5** (Dart ^3.5.4) because the primary dev machine runs macOS 12.7.6 — Flutter/Dart
releases newer than this require macOS 14+ to even run (`VM initialization failed: Current Mac OS X
version 12.0 is lower than minimum supported version 14.0`). Installed manually (not via Homebrew, which
only ships latest) to `~/development/flutter`, added to `PATH` in `~/.zshrc`. If developing on a newer
macOS, you can `flutter upgrade` freely — just re-check `pubspec.yaml` dependency ceilings first (some
packages there are pinned below their latest for SDK compatibility; see comments in `pubspec.yaml`).

## Supabase project

1. Create a project at [supabase.com](https://supabase.com) (or run one locally with the Supabase CLI —
   `supabase init && supabase start` — if you want a fully offline dev loop).
2. Open the SQL editor and run [`supabase/migrations/0001_init.sql`](../supabase/migrations/0001_init.sql)
   in full.
3. From Project Settings → API, copy the **Project URL** and **anon public key**.
4. Copy `.env.example` to `.env` in the repo root and fill in both values:
   ```
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_ANON_KEY=your-anon-key
   ```
   `.env` is gitignored — never commit real credentials.

## Running the app

```
flutter pub get
flutter run
```

Without a valid `.env`, the app boots to a "Missing configuration" screen instead of crashing — useful for
verifying UI changes before Supabase credentials are wired up.

## Tests

```
flutter test
```

Pure-logic tests (split calculation, debt simplification, model JSON round-trips) run with no network
dependency. Widget tests use `ProviderScope(overrides: [...])` to inject fake repositories.
