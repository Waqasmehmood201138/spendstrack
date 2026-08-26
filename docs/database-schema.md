# Database Schema

Source of truth: [`supabase/migrations/0001_init.sql`](../supabase/migrations/0001_init.sql). This document explains
the *why* behind the schema; read the SQL for the exact *what*.

## Key design decision: payments are expenses

The real Splitwise API models a settlement as an `expense` with `payment: true` and exactly two
`users` entries (the payer's `paid_share` equals the amount, the payee's `owed_share` equals the amount).
We do the same: there is **no separate `settlements` table**. `expenses.is_payment` distinguishes the two,
and every balance calculation sums `expense_users.paid_share - expense_users.owed_share` across *all*
non-deleted expenses regardless of `is_payment` — a payment naturally nets out the debt it settles because
its shares are structured that way. One code path, one set of RLS policies, no duplication.

## Why `expense_users` instead of `paid_by` + a splits table

Combining "who paid what" and "who owes what" into a single per-user row (`paid_share`, `owed_share`)
— exactly matching Splitwise's own `users` array on an expense — means multi-payer expenses (two
roommates split paying a bill they both fronted money for) require zero extra schema. A single-payer
expense is just the degenerate case where one row has `paid_share = cost` and every other row has
`paid_share = 0`.

`percentage` and `shares` columns are nullable and populated only when `split_type` is `percentage` or
`shares` respectively — they preserve the *inputs* to the split (not just the resolved dollar amounts) so
a future "edit this expense" feature can reconstruct the original form state instead of just showing
derived numbers.

## Group expenses vs. friend expenses

`expenses.group_id` is nullable. `null` means a direct expense between two friends outside any group —
mirrors Splitwise's "group 0" convention. Visibility (`can_access_expense` in the SQL) branches on this:
group expenses are visible to group members via `is_group_member`; friend expenses are visible to whoever
appears in that expense's `expense_users` rows via `is_expense_participant`.

## Balances

Two views, both `security_invoker = true` (critical — without it, a view runs with the *owner's*
privileges and silently bypasses RLS on the underlying tables, a well-documented Supabase footgun):

- `group_member_balances` — net balance per `(group_id, user_id, currency_code)`.
- `friend_balances` — net balance per `(viewer_id, friend_id, currency_code)`, computed by self-joining
  `expense_users` on non-group expenses.

Both are pure `SUM`/`GROUP BY` — cheap, always consistent, single source of truth.

## Debt simplification

Not done in SQL. It's an iterative greedy algorithm (repeatedly match the largest creditor against the
largest debtor) that's awkward to express set-based and has no reason to touch the database once it has a
balance list — implemented as a pure, unit-tested Dart function:
[`lib/features/balances/domain/debt_simplifier.dart`](../lib/features/balances/domain/debt_simplifier.dart).

## Integrity backstops

- `validate_expense_users_sum` (statement-level trigger): rejects any insert where `expense_users` rows
  for an expense don't sum to `expenses.cost` on *both* `paid_share` and `owed_share`, independent of any
  client-side bug in the split calculator.
- Money is stored as `numeric(12,2)` in Postgres but handled as **integer cents** throughout Dart — see
  [`lib/core/money/money.dart`](../lib/core/money/money.dart) — to avoid float-drift in split math.

## Row Level Security

Every table has RLS enabled. Two `security definer` helper functions (`is_group_member`,
`is_expense_participant`, composed into `can_access_expense`) avoid the classic "RLS policy queries the
table it's protecting" recursion problem. All multi-table writes (creating a group + adding its first
member, creating an expense + its `expense_users` rows) go through `security definer` RPC functions
(`create_group`, `create_expense`, `add_friend_by_email`, `join_group_by_invite`) rather than raw
multi-statement client inserts, so a dropped connection between two inserts can never leave an orphaned
expense with no splits, or a group with no members (which would lock its own creator out).

## Reference data

`currencies` and `categories` are seeded directly in the migration (`insert ... on conflict do nothing`),
matching Splitwise's real category taxonomy (Entertainment, Food and drink, Home, Life, Transportation,
Utilities, each with subcategories) so category pickers in the UI match what people expect.
