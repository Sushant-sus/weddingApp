# Wedding Management System

A production-ready, full-stack wedding planner: guest list, gift/contribution
recording, itinerary, and budget tracking — built as clean, plug-in feature
slices so new modules drop in with minimal friction.

> **Database architecture:** every DB operation goes through **PostgreSQL
> stored procedures** in the `wedding` schema. Prisma is used **only** as a
> query runner (`$queryRaw`) — never `prisma.model.*`. The single source of
> truth for all DDL + procedures is [`server/prisma/seed-procedures.sql`](server/prisma/seed-procedures.sql).

---

## Tech Stack

| Layer    | Tech |
|----------|------|
| Frontend | React 18, TypeScript, Vite, TanStack Table v8, TanStack Query v5, React Hook Form + Zod, Tailwind CSS + shadcn/ui, React Router v6, Lucide, Recharts, @dnd-kit |
| Backend  | Node.js, Express, TypeScript, Prisma (query runner only), Zod, dotenv, cors, helmet, morgan |
| Database | PostgreSQL (stored procedures, soft deletes) |

---

## Project Structure

```
wedding-app/
├── client/                 # React frontend (feature-sliced)
│   └── src/
│       ├── features/       # guests · gifts · itinerary · costs · dashboard
│       ├── components/ui/  # shadcn-style shared components
│       ├── components/layout/
│       ├── lib/            # api client, queryClient, utils
│       └── router/
├── server/                 # Express backend (feature-sliced)
│   ├── src/
│   │   ├── features/       # guests · gifts · itinerary · costs
│   │   │   └── <f>/        # *.routes · *.controller · *.service · *.schema
│   │   ├── middleware/     # validate · errorHandler · notFound
│   │   ├── prisma/         # Prisma client singleton
│   │   ├── config/         # env
│   │   ├── router/         # mounts all feature routers at /api/v1
│   │   └── app.ts / index.ts
│   └── prisma/
│       ├── schema.prisma           # models (for client generation + docs)
│       ├── seed-procedures.sql     # ⭐ source of truth: schema+tables+SPs
│       ├── seed-data.sql           # optional sample data
│       └── migrations/             # 001..005 split SQL (per feature)
└── README.md
```

---

## Prerequisites

- **Node.js** 18+ (tested on 20/22/25)
- **PostgreSQL** 14+ running locally (or a connection string to one)

---

## Setup

### 1. Database

Create a database:

```bash
createdb wedding_db          # or: psql -c "CREATE DATABASE wedding_db;"
```

### 2. Backend

```bash
cd server
cp .env.example .env          # then edit DATABASE_URL if needed
npm install
npm run prisma:generate       # generate the Prisma client

# Create the schema, tables, enums AND all stored procedures (idempotent):
npm run db:procedures         # runs prisma/seed-procedures.sql

# (optional) load sample guests/gifts/events/costs:
npm run db:seed-data

npm run dev                   # API on http://localhost:4000/api/v1
```

> `npm run db:procedures` uses a small cross-platform runner
> ([`scripts/run-sql.mjs`](server/scripts/run-sql.mjs)). If you prefer `psql`:
> `psql "$DATABASE_URL" -f prisma/seed-procedures.sql`
>
> The individual `prisma/migrations/00x_*.sql` files exist if you'd rather apply
> them one feature at a time (run `001` first, then `002`–`005`).

**Why not `prisma migrate`?** The procedures *are* the data layer, so the SQL
script is authoritative. `schema.prisma` is kept in sync for `prisma generate`
(typed client) and documentation.

### 3. Frontend

```bash
cd client
cp .env.example .env          # VITE_API_BASE_URL defaults to the local API
npm install
npm run dev                   # app on http://localhost:5173
```

---

## API (REST, mounted at `/api/v1`)

| Method | Path | Description |
|--------|------|-------------|
| GET    | `/guests` | list (filters: `familyType`, `rsvpStatus`, `side`) |
| POST   | `/guests` | create one |
| PATCH  | `/guests/batch` | batch update dirty grid rows |
| PATCH  | `/guests/:id` | update one |
| DELETE | `/guests/:id` | soft delete |
| GET    | `/guests/summary` | totals |
| GET    | `/gifts` · `/gifts/summary` | all gifts · totals |
| GET/POST | `/guests/:id/gifts` | gifts for / add to a guest |
| PATCH/DELETE | `/gifts/:id` | update · soft delete |
| GET    | `/itinerary` | events ordered by `order_index` |
| POST   | `/itinerary` · PATCH/DELETE `/itinerary/:id` | CRUD |
| PATCH  | `/itinerary/reorder` | drag-and-drop reorder |
| GET    | `/costs` · `/costs/summary` | items · per-category + grand totals |
| POST   | `/costs` · PATCH/DELETE `/costs/:id` | CRUD |

**Envelopes** — success: `{ success: true, data, meta? }`,
error: `{ success: false, error: { code, message, details? } }`.

---

## Key Features

- **Guests** — Excel-style editable TanStack Table with inline cells, a sticky
  summary bar, dirty-row tracking and a single **Save All Changes** batch
  `PATCH`, inline add row, delete-with-confirm, filters, and CSV export.
- **Gifts** — per-guest slide-over panel + standalone list, cash/in-kind totals.
- **Itinerary** — drag-and-drop timeline (@dnd-kit), category color-coding,
  CRUD dialog, and a print/PDF view.
- **Costs** — grouped editable estimated-vs-actual table, payment badges,
  budget-utilization bar, variance footer, and a Recharts comparison chart.
- **Dashboard** — summary cards, quick links, recent-activity feed.

---

## Adding a New Feature (e.g. Vendors)

1. `server/src/features/vendors/` → `vendor.{schema,service,controller,routes}.ts`
   (service calls `wedding.sp_vendor_*` via `$queryRaw`).
2. Add procedures to `seed-procedures.sql` (+ a `006_sp_vendors.sql` migration).
3. Register one line in [`server/src/router/index.ts`](server/src/router/index.ts).
4. `client/src/features/vendors/` → `*.api.ts`, `*.hooks.ts`, `*.types.ts`, page;
   add a route in [`client/src/router/index.tsx`](client/src/router/index.tsx).

No changes to existing code required.

---

## Scripts

**server**: `dev` · `build` · `start` · `typecheck` · `prisma:generate` ·
`db:procedures` · `db:seed-data`
**client**: `dev` · `build` · `preview` · `typecheck`
