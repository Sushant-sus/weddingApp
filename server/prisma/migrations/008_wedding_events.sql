-- 008 — Multi-user wedding events: tables, event scoping on existing tables (idempotent)
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS wedding.wedding_events (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name         TEXT NOT NULL,
  wedding_date DATE NOT NULL,
  venue        TEXT,
  description  TEXT,
  created_by   UUID REFERENCES wedding.users(id),
  is_active    BOOLEAN NOT NULL DEFAULT TRUE,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at   TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS wedding.event_members (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id          UUID REFERENCES wedding.wedding_events(id) ON DELETE CASCADE,
  user_id           UUID REFERENCES wedding.users(id) ON DELETE CASCADE,
  event_role        TEXT NOT NULL,                  -- OWNER, LEADER, EDITOR, CONTRIBUTOR, VIEWER
  invited_by        UUID REFERENCES wedding.users(id),
  invite_status     TEXT NOT NULL DEFAULT 'PENDING',-- PENDING, ACCEPTED, DECLINED
  invite_token      TEXT,
  invite_expires_at TIMESTAMPTZ,
  joined_at         TIMESTAMPTZ,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (event_id, user_id)
);

CREATE TABLE IF NOT EXISTS wedding.event_activity_log (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id    UUID REFERENCES wedding.wedding_events(id),
  user_id     UUID REFERENCES wedding.users(id),
  action      TEXT NOT NULL,
  entity_type TEXT,
  entity_id   UUID,
  metadata    JSONB,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Scope existing feature tables to an event (nullable so legacy rows still work).
ALTER TABLE wedding.guests           ADD COLUMN IF NOT EXISTS event_id UUID REFERENCES wedding.wedding_events(id);
ALTER TABLE wedding.gifts            ADD COLUMN IF NOT EXISTS event_id UUID REFERENCES wedding.wedding_events(id);
ALTER TABLE wedding.itinerary_events ADD COLUMN IF NOT EXISTS event_id UUID REFERENCES wedding.wedding_events(id);
ALTER TABLE wedding.cost_items       ADD COLUMN IF NOT EXISTS event_id UUID REFERENCES wedding.wedding_events(id);

CREATE INDEX IF NOT EXISTS idx_guests_event_id    ON wedding.guests(event_id);
CREATE INDEX IF NOT EXISTS idx_gifts_event_id     ON wedding.gifts(event_id);
CREATE INDEX IF NOT EXISTS idx_itinerary_event_id ON wedding.itinerary_events(event_id);
CREATE INDEX IF NOT EXISTS idx_costs_event_id     ON wedding.cost_items(event_id);
CREATE INDEX IF NOT EXISTS idx_event_members_user ON wedding.event_members(user_id);
CREATE INDEX IF NOT EXISTS idx_activity_event     ON wedding.event_activity_log(event_id);
