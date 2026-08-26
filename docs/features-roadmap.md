# Features & Roadmap

Reference: [Splitwise's own API docs](https://dev.splitwise.com/) (data model) and
[splitwise.com/pro](https://www.splitwise.com/pro) (paid-tier feature list) — both checked directly
against this project's schema.

## Built (free-tier feature parity)

Everything below needs only Supabase — no external paid accounts.

- [x] Auth (email/password, session persistence)
- [x] Profile (name, picture, default currency, locale)
- [x] Friends (add by email, friend list, per-friend balance)
- [x] Groups (create, types matching Splitwise's own — home/trip/couple/apartment/house/other, membership,
      invite-by-link)
- [x] Expenses: equal / exact / percentage / shares splits, **multi-payer**, categories (with
      subcategories, seeded from Splitwise's real taxonomy), notes, currency per expense
- [x] Payments (settle-up), modeled as expenses — see [database-schema.md](./database-schema.md)
- [x] Balances per group and per friend, with debt simplification (fewest-transactions settle-up
      suggestions)
- [x] Comments on expenses (user + system-generated, e.g. "created this expense")
- [x] Activity feed (expenses + payments + comments, merged and time-ordered)
- [x] In-app notifications (added to group, expense added, comment added, etc. — matches Splitwise's
      `notification_type` enum)
- [x] Expense search

## Deferred — needs an external paid service/account

These are real Splitwise Pro features. Each needs a decision from you (which provider, and its
credentials) before it can be built — the schema already has room for all of them without a rewrite.

| Feature | What it needs | Schema readiness |
|---|---|---|
| Bank transaction import | A provider like Plaid (paid, compliance-heavy) | Not modeled yet — separate `linked_accounts` + `imported_transactions` tables when this is prioritized |
| Receipt scanning / itemization | A vision/OCR API (e.g. Google Cloud Vision, AWS Textract) | `expenses` can take a `receipt_url` column; itemization would add an `expense_line_items` table |
| Live currency conversion | An FX rate API key (e.g. exchangerate.host, Open Exchange Rates) | `expenses.currency_code` already per-expense; conversion is a display-layer concern once rates are available |
| Push notifications | Firebase Cloud Messaging / APNs project setup | `notifications` table already exists as the source of truth; push is just a delivery channel on top of it |

## Explicitly not building

- Ads — this is our own app; "ad-free" is simply the default, nothing to build.
- Transaction import UI without a real bank-linking provider behind it (would be fake).

## How to pick up a deferred item

Tell me which provider you want for a given row above (e.g. "use Open Exchange Rates" or "use Google Cloud
Vision for receipts") and whether you already have an account/API key, and it gets scoped and built the
same way the rest of this app was — real schema, real RLS, no placeholders.
