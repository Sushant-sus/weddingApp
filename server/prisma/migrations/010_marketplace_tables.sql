-- 010 — Utsav service marketplace: tables, enums, indexes, seed categories (idempotent).
--
-- PURELY ADDITIVE. No existing table or stored procedure is altered. The itinerary
-- "service pill" is DERIVED via joins from service_requests, so wedding.itinerary_events
-- is never modified. Safe to run on a populated database without affecting present data.
CREATE EXTENSION IF NOT EXISTS pgcrypto;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type t JOIN pg_namespace n ON n.oid = t.typnamespace
                 WHERE t.typname = 'service_audience_enum' AND n.nspname = 'wedding') THEN
    CREATE TYPE wedding.service_audience_enum AS ENUM ('BROADCAST', 'TARGETED');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_type t JOIN pg_namespace n ON n.oid = t.typnamespace
                 WHERE t.typname = 'service_request_status_enum' AND n.nspname = 'wedding') THEN
    CREATE TYPE wedding.service_request_status_enum AS ENUM ('LIVE', 'BOOKED', 'CANCELLED');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_type t JOIN pg_namespace n ON n.oid = t.typnamespace
                 WHERE t.typname = 'pitch_status_enum' AND n.nspname = 'wedding') THEN
    CREATE TYPE wedding.pitch_status_enum AS ENUM ('NEW', 'SHORTLISTED', 'ACCEPTED', 'DECLINED');
  END IF;
END $$;

-- Service categories (Mehendi, Catering, ...). Drives the marketplace browse grid.
CREATE TABLE IF NOT EXISTS wedding.service_categories (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug       TEXT NOT NULL UNIQUE,          -- 'mehendi'
  name       TEXT NOT NULL,                 -- 'Mehendi'
  accent_hex TEXT,                          -- '#6FBF8E'
  sort_order INT  NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- A provider profile. One per user (in "provider mode"); user_id nullable so demo/seed
-- providers can exist without an account. categories holds category slugs.
CREATE TABLE IF NOT EXISTS wedding.service_providers (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID UNIQUE REFERENCES wedding.users(id) ON DELETE SET NULL,
  name         TEXT NOT NULL,
  bio          TEXT,
  categories   TEXT[] NOT NULL DEFAULT '{}',
  base_price   NUMERIC(12,2),
  city         TEXT,
  distance_km  NUMERIC(6,2),
  rating       NUMERIC(3,2) NOT NULL DEFAULT 0,   -- denormalized average of reviews
  review_count INT NOT NULL DEFAULT 0,
  is_verified  BOOLEAN NOT NULL DEFAULT FALSE,
  is_active    BOOLEAN NOT NULL DEFAULT TRUE,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at   TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS wedding.provider_portfolio (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_id UUID NOT NULL REFERENCES wedding.service_providers(id) ON DELETE CASCADE,
  image_url   TEXT,
  caption     TEXT,
  sort_order  INT NOT NULL DEFAULT 0,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS wedding.provider_reviews (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_id    UUID NOT NULL REFERENCES wedding.service_providers(id) ON DELETE CASCADE,
  author_user_id UUID REFERENCES wedding.users(id) ON DELETE SET NULL,
  author_name    TEXT,
  rating         INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
  body           TEXT,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- A host's request for a service, optionally tied to an itinerary item.
-- accepted_pitch_id is a soft reference to service_pitches (no FK to avoid a
-- circular dependency); integrity is maintained by sp_pitch_book.
CREATE TABLE IF NOT EXISTS wedding.service_requests (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id          UUID NOT NULL REFERENCES wedding.wedding_events(id) ON DELETE CASCADE,
  itinerary_item_id UUID REFERENCES wedding.itinerary_events(id),
  category          TEXT NOT NULL,
  title             TEXT NOT NULL,
  budget_min        NUMERIC(12,2),
  budget_max        NUMERIC(12,2),
  audience          wedding.service_audience_enum NOT NULL DEFAULT 'BROADCAST',
  status            wedding.service_request_status_enum NOT NULL DEFAULT 'LIVE',
  accepted_pitch_id UUID,
  created_by        UUID REFERENCES wedding.users(id),
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at        TIMESTAMPTZ
);

-- Targeted audience: which providers a request was sent to.
CREATE TABLE IF NOT EXISTS wedding.service_request_targets (
  request_id  UUID NOT NULL REFERENCES wedding.service_requests(id) ON DELETE CASCADE,
  provider_id UUID NOT NULL REFERENCES wedding.service_providers(id) ON DELETE CASCADE,
  PRIMARY KEY (request_id, provider_id)
);

-- A provider's price pitch for a request. One pitch per provider per request.
CREATE TABLE IF NOT EXISTS wedding.service_pitches (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  request_id        UUID NOT NULL REFERENCES wedding.service_requests(id) ON DELETE CASCADE,
  provider_id       UUID NOT NULL REFERENCES wedding.service_providers(id),
  price             NUMERIC(12,2) NOT NULL,
  message           TEXT,
  available_on_date BOOLEAN NOT NULL DEFAULT TRUE,
  status            wedding.pitch_status_enum NOT NULL DEFAULT 'NEW',
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at        TIMESTAMPTZ,
  UNIQUE (request_id, provider_id)
);

CREATE INDEX IF NOT EXISTS idx_providers_user        ON wedding.service_providers(user_id);
CREATE INDEX IF NOT EXISTS idx_providers_categories  ON wedding.service_providers USING GIN (categories);
CREATE INDEX IF NOT EXISTS idx_portfolio_provider    ON wedding.provider_portfolio(provider_id);
CREATE INDEX IF NOT EXISTS idx_reviews_provider      ON wedding.provider_reviews(provider_id);
CREATE INDEX IF NOT EXISTS idx_requests_event        ON wedding.service_requests(event_id);
CREATE INDEX IF NOT EXISTS idx_requests_item         ON wedding.service_requests(itinerary_item_id);
CREATE INDEX IF NOT EXISTS idx_requests_category     ON wedding.service_requests(category);
CREATE INDEX IF NOT EXISTS idx_requests_status       ON wedding.service_requests(status);
CREATE INDEX IF NOT EXISTS idx_pitches_request       ON wedding.service_pitches(request_id);
CREATE INDEX IF NOT EXISTS idx_pitches_provider      ON wedding.service_pitches(provider_id);

-- Seed the category catalogue (idempotent on slug).
INSERT INTO wedding.service_categories (slug, name, accent_hex, sort_order) VALUES
  ('mehendi',     'Mehendi',     '#6FBF8E', 1),
  ('catering',    'Catering',    '#E0A458', 2),
  ('photography', 'Photography', '#7FA8D9', 3),
  ('decor',       'Decor',       '#A88BD9', 4),
  ('makeup',      'Makeup',      '#D98A94', 5),
  ('dj_dhol',     'DJ/Dhol',     '#C9A28A', 6),
  ('pandit',      'Pandit',      '#E0A458', 7),
  ('mandap',      'Mandap',      '#7FA8D9', 8)
ON CONFLICT (slug) DO NOTHING;
