# Deployment Guide

Three pieces, three free hosts:

| Piece | Host | Notes |
|-------|------|-------|
| PostgreSQL | **Supabase** | already set up |
| Backend API (`server/`) | **Render** | free web service |
| Frontend (`client/`) | **Vercel** | free static hosting |

> The production build + start command (`npm start` → `node dist/index.js`)
> has been verified locally against Supabase with `NODE_ENV=production`.

---

## 0. Push your latest commit

```bash
git push origin main
```

This includes `render.yaml`, `client/vercel.json`, and the root `.gitignore`.

---

## 1. Database — Supabase (done)

The schema, stored procedures, and sample data are already loaded
(`server/prisma/seed-procedures.sql` + `seed-data.sql`).

You need the **Session pooler** connection string for the deployed backend
(Render can't reach Supabase's IPv6-only direct host):

- Supabase → **Project Settings → Database → Connection string → URI**
- Toggle to **Session pooler**. It looks like:
  ```
  postgresql://postgres.sxnhkzwwylfaqjocmyyy:[PASSWORD]@aws-0-<region>.pooler.supabase.com:5432/postgres
  ```
- Append `?sslmode=require` and URL-encode special chars in the password
  (`%`→`%25`, `#`→`%23`, `:`→`%3A`).

🔐 **Rotate the DB password** (Project Settings → Database) before going live —
the dev password was shared in chat.

---

## 2. Backend — Render

**Easiest: Blueprint (uses `render.yaml`)**
1. Render → **New → Blueprint** → select the `weddingApp` repo.
2. It reads `render.yaml` (rootDir=server, build, start, health check).
3. Fill the secret env vars when prompted:
   - `DATABASE_URL` = the Supabase **Session pooler** URI from step 1
   - `CORS_ORIGIN` = your Vercel URL (set after step 3; can update later)

**Or fix an existing service manually** (this resolves
"Couldn't find a package.json"): Settings →
- **Root Directory**: `server`
- **Build Command**: `npm install && npm run prisma:generate && npm run build`
- **Start Command**: `npm start`
- **Health Check Path**: `/api/v1/health`
- Env: `NODE_ENV=production`, `DATABASE_URL=...`, `CORS_ORIGIN=...`

Note: Render free instances cold-start after ~15 min idle (first request is slow).

---

## 3. Frontend — Vercel

1. Vercel → **Add New → Project** → import the `weddingApp` repo.
2. **Root Directory**: `client` (Vercel auto-detects Vite via `vercel.json`).
3. Environment variable:
   - `VITE_API_BASE_URL` = `https://<your-render-service>.onrender.com/api/v1`
4. Deploy. Then go back to Render and set `CORS_ORIGIN` to the Vercel URL,
   and redeploy the API.

---

## Quick verification after deploy

```bash
# API up?
curl https://<your-render-service>.onrender.com/api/v1/health
# Data flowing from Supabase?
curl https://<your-render-service>.onrender.com/api/v1/guests/summary
```

Then open the Vercel URL — the dashboard should load with live data.
