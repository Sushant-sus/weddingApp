# Database Changes Log

All database changes made in this work, with the scripts that implement them. Everything is
**additive and backward-compatible** — no existing table, column, or stored procedure behaviour
was removed, so present data is unaffected. Every script is **idempotent** (`CREATE OR REPLACE`,
`IF NOT EXISTS`, `DROP NOT NULL`) and safe to re-run.

All objects live in the PostgreSQL `wedding` schema and follow the project's stored-procedure
architecture (the app only calls `wedding.sp_*` via Prisma `$queryRaw`/`$executeRaw`).

## How to apply
```bash
cd server
npm run db:migrate     # runs every prisma/migrations/*.sql in filename order (idempotent)
```
Or paste a single file into the Supabase SQL editor. (Migrations 010–012 were already applied to
the live Supabase database during development.)

---

## Scripts created

| File | Purpose |
|---|---|
| `server/prisma/migrations/010_marketplace_tables.sql` | Utsav service-marketplace tables, enums, indexes, seed categories |
| `server/prisma/migrations/011_sp_marketplace.sql` | Marketplace stored procedures (providers, requests, pitches) |
| `server/prisma/migrations/012_gift_quick.sql` | Fast gift-desk recording (free-text giver support) |

---

## 010 — Service marketplace: tables, enums, seed
`server/prisma/migrations/010_marketplace_tables.sql`

**Enums (new):**
- `wedding.service_audience_enum` — `BROADCAST | TARGETED`
- `wedding.service_request_status_enum` — `LIVE | BOOKED | CANCELLED`
- `wedding.pitch_status_enum` — `NEW | SHORTLISTED | ACCEPTED | DECLINED`

**Tables (new):**
- `wedding.service_categories` — catalogue (seeded: Mehendi, Catering, Photography, Decor, Makeup,
  DJ/Dhol, Pandit, Mandap), with `slug`, `name`, `accent_hex`, `sort_order`.
- `wedding.service_providers` — provider profile (`user_id` unique nullable, `name`, `bio`,
  `categories TEXT[]`, `base_price`, `city`, `distance_km`, denormalized `rating`/`review_count`,
  `is_verified`, soft delete).
- `wedding.provider_portfolio` — portfolio images per provider.
- `wedding.provider_reviews` — reviews (`rating 1–5`, recomputes provider rating).
- `wedding.service_requests` — a host's request (`event_id`, optional `itinerary_item_id`,
  `category`, `title`, `budget_min/max`, `audience`, `status`, `accepted_pitch_id`, `created_by`).
- `wedding.service_request_targets` — provider targets for `TARGETED` requests.
- `wedding.service_pitches` — provider price pitches (`request_id`, `provider_id`, `price`,
  `message`, `available_on_date`, `status`; unique per request+provider).

**Indexes:** GIN on `service_providers.categories`; btree on the request/pitch foreign keys + status.

## 011 — Marketplace stored procedures
`server/prisma/migrations/011_sp_marketplace.sql`

**Categories / providers:** `sp_category_list`, `sp_provider_get_by_id`, `sp_provider_get_by_user`,
`sp_provider_list`, `sp_provider_upsert`, `sp_provider_portfolio_add`, `sp_provider_review_add`.

**Requests:** `sp_service_request_get_by_id`, `sp_service_request_create`,
`sp_service_request_list_for_event`, `sp_service_request_cancel`, `sp_itinerary_with_services`
(itinerary items joined with their active service request — derives the "service pill" **without
altering** `sp_itinerary_get_all` or the `itinerary_events` table).

**Pitches:** `sp_pitch_list_for_request` (best-match ranked), `sp_pitch_create`, `sp_pitch_decline`,
`sp_pitch_book` (accepts one pitch, declines siblings, flips request to `BOOKED`),
`sp_provider_dashboard_feed` (matched live requests; excludes soft-deleted events).

**Authorization helpers:** `sp_request_event_role`, `sp_pitch_event_role` (return the caller's
event role for a request/pitch, or `NULL`).

---

## 012 — Fast gift-desk recording (free-text giver)
`server/prisma/migrations/012_gift_quick.sql`

Enables recording gifts from givers who are **not** in the guest list (the "gift desk" workflow),
while keeping existing guest-linked gifts intact.

**Schema changes to `wedding.gifts`:**
- `ALTER COLUMN guest_id DROP NOT NULL` — a gift may now have no linked guest.
- `ADD COLUMN giver_name TEXT` — free-text giver name when there's no guest.

**Stored procedures redefined (backward-compatible):**
- `sp_gift_get_by_id` and `sp_gift_get_all` — changed the guest join from `JOIN` to **`LEFT JOIN`**
  and now return `family_name = COALESCE(guest.family_name, gift.giver_name)` plus a `giver_name`
  field. Existing clients that read `family_name` keep working unchanged.

**Stored procedure (new):**
- `sp_gift_quick_create(p_event_id, p_guest_id, p_giver_name, p_gift_type, p_amount, p_description,
  p_remarks)` — records a gift tied to a guest **or** to a free-text giver. Raises
  `GIVER_REQUIRED` if neither is supplied; `GUEST_NOT_FOUND` if a bad guest id is passed.

**Backend wiring for this change (TypeScript, not DB):**
- `POST /events/:eventId/gifts` (Contributor+) → `giftController.quickCreate` → `sp_gift_quick_create`.
- `quickGiftSchema` validation + `GIVER_REQUIRED` mapped to HTTP 400 in `errorHandler.ts`.

---

## Note on the hosted (Render) backend
Migrations 010–012 were applied to the **Supabase** database directly. The **server code** that
calls the new procedures (routes/services for marketplace and gift quick-create) must be committed
and pushed so Render redeploys — the database is ready, but the deployed API serves the new
endpoints only after that deploy.
