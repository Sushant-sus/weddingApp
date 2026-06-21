-- 001 — schema, extensions, enums, tables, indexes (idempotent)
CREATE SCHEMA IF NOT EXISTS wedding;
CREATE EXTENSION IF NOT EXISTS pgcrypto;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type t JOIN pg_namespace n ON n.oid = t.typnamespace
                 WHERE t.typname = 'family_type_enum' AND n.nspname = 'wedding') THEN
    CREATE TYPE wedding.family_type_enum AS ENUM ('CHULEY', 'SINGLE');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_type t JOIN pg_namespace n ON n.oid = t.typnamespace
                 WHERE t.typname = 'side_enum' AND n.nspname = 'wedding') THEN
    CREATE TYPE wedding.side_enum AS ENUM ('BRIDE', 'GROOM', 'BOTH');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_type t JOIN pg_namespace n ON n.oid = t.typnamespace
                 WHERE t.typname = 'rsvp_status_enum' AND n.nspname = 'wedding') THEN
    CREATE TYPE wedding.rsvp_status_enum AS ENUM ('PENDING', 'CONFIRMED', 'DECLINED');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_type t JOIN pg_namespace n ON n.oid = t.typnamespace
                 WHERE t.typname = 'gift_type_enum' AND n.nspname = 'wedding') THEN
    CREATE TYPE wedding.gift_type_enum AS ENUM ('CASH', 'KIND');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_type t JOIN pg_namespace n ON n.oid = t.typnamespace
                 WHERE t.typname = 'event_category_enum' AND n.nspname = 'wedding') THEN
    CREATE TYPE wedding.event_category_enum AS ENUM
      ('CEREMONY', 'RECEPTION', 'RITUAL', 'MEAL', 'ENTERTAINMENT', 'OTHER');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_type t JOIN pg_namespace n ON n.oid = t.typnamespace
                 WHERE t.typname = 'payment_status_enum' AND n.nspname = 'wedding') THEN
    CREATE TYPE wedding.payment_status_enum AS ENUM ('UNPAID', 'PARTIAL', 'PAID');
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS wedding.guests (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  family_name     TEXT NOT NULL,
  family_type     wedding.family_type_enum NOT NULL,
  side            wedding.side_enum NOT NULL,
  attendee_count  INT NOT NULL DEFAULT 0,
  confirmed_count INT,
  contact_phone   TEXT,
  address         TEXT,
  remarks         TEXT,
  rsvp_status     wedding.rsvp_status_enum NOT NULL DEFAULT 'PENDING',
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at      TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS wedding.gifts (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  guest_id    UUID NOT NULL REFERENCES wedding.guests(id),
  gift_type   wedding.gift_type_enum NOT NULL,
  amount      NUMERIC(12,2),
  description TEXT,
  received_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  remarks     TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at  TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS wedding.itinerary_events (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title       TEXT NOT NULL,
  description TEXT,
  event_date  DATE NOT NULL,
  start_time  TEXT NOT NULL,
  end_time    TEXT,
  location    TEXT,
  responsible TEXT,
  category    wedding.event_category_enum NOT NULL DEFAULT 'OTHER',
  order_index INT NOT NULL DEFAULT 0,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at  TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS wedding.cost_items (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category       TEXT NOT NULL,
  item_name      TEXT NOT NULL,
  estimated_cost NUMERIC(12,2) NOT NULL DEFAULT 0,
  actual_cost    NUMERIC(12,2),
  vendor         TEXT,
  payment_status wedding.payment_status_enum NOT NULL DEFAULT 'UNPAID',
  notes          TEXT,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at     TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_guests_deleted_at ON wedding.guests(deleted_at);
CREATE INDEX IF NOT EXISTS idx_gifts_guest_id    ON wedding.gifts(guest_id);
CREATE INDEX IF NOT EXISTS idx_gifts_deleted_at  ON wedding.gifts(deleted_at);
CREATE INDEX IF NOT EXISTS idx_itinerary_order   ON wedding.itinerary_events(order_index);
CREATE INDEX IF NOT EXISTS idx_cost_category     ON wedding.cost_items(category);
