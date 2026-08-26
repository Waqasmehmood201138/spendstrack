# Architecture

## Stack

- **Flutter 3.24.5 / Dart ^3.5.4** (pinned — see [setup.md](./setup.md))
- **Supabase**: Postgres + Auth + Realtime as the entire backend, accessed via `supabase_flutter`
- **Riverpod** (`flutter_riverpod`) for state management
- **go_router** for navigation, gated on Supabase auth state

## No codegen {#no-codegen}

Deliberately no `freezed`, no `riverpod_generator`/`riverpod_annotation`, no `build_runner`. Reasoning:

1. Dart 3's sealed classes + exhaustive `switch` expressions cover the one place this app needs a union
   type (the activity feed's expense-vs-payment-vs-comment items) with zero codegen.
2. None of the data models need `copyWith` — every one is either created once or refetched wholesale from
   a realtime stream, never partially mutated locally. That removes the main reason to reach for freezed.
3. Plain Riverpod (`Provider`, `NotifierProvider`, `StreamProvider`, `FutureProvider`, with
   `.family`/`.autoDispose`) does everything this app needs without generated code.
4. The old pinned Dart SDK makes `build_runner`/analyzer version mismatches a real risk — fewer moving
   parts is a deliberate hedge, not just a style preference.

Tradeoff accepted: hand-written `fromJson` has no compile-time link to actual Postgres column names — a
typo returns `null` at runtime instead of failing at build time. Mitigated by a `fromJson(toJson(x)) == x`
round-trip unit test per model (doubles as a schema-contract check).

## Folder structure

```
lib/
  main.dart                 -- loads .env, initializes Supabase, runApp(ProviderScope)
  app.dart                  -- MaterialApp.router
  core/
    config/                 -- Env (reads .env / --dart-define), never hardcode secrets
    supabase/                -- Supabase client provider
    router/                  -- go_router config + auth-gated redirect
    money/                   -- integer-cents Money type + formatting
    widgets/                 -- shared building blocks (async state, avatars, empty states)
  features/
    auth/                    -- sign in / sign up / session
    profile/                 -- current user's profile
    friends/                 -- friend list, add friend, friend balances
    groups/                  -- group CRUD, membership, invite links
    categories/               -- category picker (reads seeded reference data)
    expenses/                 -- add/edit expense, split calculator, comments
    balances/                 -- balance views + debt simplification
    activity/                 -- merged activity/notification feed
    search/                   -- expense search
  models/                   -- (only if a model is shared across >1 feature; otherwise co-located with its feature under data/)
```

Each feature follows the same internal shape: `data/` (models + repository wrapping Supabase calls),
`providers/` (Riverpod providers over the repository), `presentation/` (screens/widgets). Pure business
logic that doesn't touch Supabase lives in `domain/` within its feature (e.g.
`expenses/domain/split_calculator.dart`, `balances/domain/debt_simplifier.dart`) so it can be unit tested
with zero network dependency.

## Money

All arithmetic (split calculation, debt simplification) happens in **integer cents**, never `double`.
Conversion to/from Postgres `numeric` happens once, at the repository boundary. See
[`lib/core/money/money.dart`](../lib/core/money/money.dart).

## Auth gating

`Supabase.instance.client.auth.onAuthStateChange` feeds a `GoRouterRefreshStream` (the standard go_router
adapter turning a stream into a `ChangeNotifier`), wired into `GoRouter(refreshListenable: ...)`. The
router's `redirect:` callback checks `auth.currentSession` and bounces unauthenticated users to
`/sign-in`, authenticated users away from `/sign-in`/`/sign-up`.

## Error/loading conventions

Repositories return domain models or throw; providers expose `AsyncValue<T>` (via `FutureProvider`/
`StreamProvider`); screens consume `AsyncValue` through a single shared
[`AsyncValueWidget`](../lib/core/widgets/async_value_widget.dart) so loading/error/empty states render
consistently everywhere instead of being reimplemented per screen.
