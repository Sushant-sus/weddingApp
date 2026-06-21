-- =============================================================================
-- Wedding Management System — DATABASE SOURCE OF TRUTH
-- =============================================================================
-- This single file creates EVERYTHING and is fully idempotent:
--   1. the `wedding` schema
--   2. all ENUM types
--   3. all tables (with soft-delete `deleted_at` columns)
--   4. all stored procedures (CREATE OR REPLACE)
--
-- Run with:  psql "$DATABASE_URL" -f prisma/seed-procedures.sql
--        or: npm run db:procedures   (from server/)
--
-- All application DB access goes through these procedures. Prisma is only a
-- query runner ($queryRaw) that SELECTs these functions.
-- =============================================================================

-- 1. SCHEMA ------------------------------------------------------------------
CREATE SCHEMA IF NOT EXISTS wedding;

-- pgcrypto for gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 2. ENUMS -------------------------------------------------------------------
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

-- 3. TABLES ------------------------------------------------------------------
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

CREATE INDEX IF NOT EXISTS idx_guests_deleted_at  ON wedding.guests(deleted_at);
CREATE INDEX IF NOT EXISTS idx_gifts_guest_id     ON wedding.gifts(guest_id);
CREATE INDEX IF NOT EXISTS idx_gifts_deleted_at   ON wedding.gifts(deleted_at);
CREATE INDEX IF NOT EXISTS idx_itinerary_order    ON wedding.itinerary_events(order_index);
CREATE INDEX IF NOT EXISTS idx_cost_category      ON wedding.cost_items(category);

-- ===========================================================================
-- 4. STORED PROCEDURES
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- GUESTS
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION wedding.sp_guest_get_all(
  p_family_type TEXT DEFAULT NULL,
  p_rsvp_status TEXT DEFAULT NULL,
  p_side        TEXT DEFAULT NULL
) RETURNS JSONB LANGUAGE plpgsql AS $$
DECLARE v_result JSONB;
BEGIN
  SELECT json_agg(row_to_json(r)) INTO v_result
  FROM (
    SELECT id, family_name, family_type, side, attendee_count,
           confirmed_count, contact_phone, address, remarks,
           rsvp_status, created_at, updated_at
    FROM wedding.guests
    WHERE deleted_at IS NULL
      AND (p_family_type IS NULL OR family_type = p_family_type::wedding.family_type_enum)
      AND (p_rsvp_status IS NULL OR rsvp_status = p_rsvp_status::wedding.rsvp_status_enum)
      AND (p_side        IS NULL OR side = p_side::wedding.side_enum)
    ORDER BY created_at ASC
  ) r;
  RETURN COALESCE(v_result, '[]'::JSONB);
EXCEPTION WHEN OTHERS THEN
  RAISE EXCEPTION 'sp_guest_get_all failed: %', SQLERRM;
END; $$;

CREATE OR REPLACE FUNCTION wedding.sp_guest_get_by_id(p_id UUID)
RETURNS JSONB LANGUAGE plpgsql AS $$
DECLARE v_result JSONB;
BEGIN
  SELECT row_to_json(r) INTO v_result
  FROM (
    SELECT id, family_name, family_type, side, attendee_count,
           confirmed_count, contact_phone, address, remarks,
           rsvp_status, created_at, updated_at
    FROM wedding.guests WHERE id = p_id AND deleted_at IS NULL
  ) r;
  IF v_result IS NULL THEN
    RAISE EXCEPTION 'GUEST_NOT_FOUND: Guest with id % not found', p_id;
  END IF;
  RETURN v_result;
END; $$;

CREATE OR REPLACE FUNCTION wedding.sp_guest_create(
  p_family_name    TEXT,
  p_family_type    TEXT,
  p_side           TEXT,
  p_attendee_count INT,
  p_contact_phone  TEXT DEFAULT NULL,
  p_address        TEXT DEFAULT NULL,
  p_remarks        TEXT DEFAULT NULL
) RETURNS JSONB LANGUAGE plpgsql AS $$
DECLARE v_id UUID; v_result JSONB;
BEGIN
  INSERT INTO wedding.guests(family_name, family_type, side, attendee_count,
              contact_phone, address, remarks)
  VALUES (p_family_name, p_family_type::wedding.family_type_enum,
          p_side::wedding.side_enum, p_attendee_count,
          p_contact_phone, p_address, p_remarks)
  RETURNING id INTO v_id;

  SELECT wedding.sp_guest_get_by_id(v_id) INTO v_result;
  RETURN v_result;
EXCEPTION WHEN OTHERS THEN
  RAISE EXCEPTION 'sp_guest_create failed: %', SQLERRM;
END; $$;

CREATE OR REPLACE FUNCTION wedding.sp_guest_update(
  p_id              UUID,
  p_family_name     TEXT DEFAULT NULL,
  p_family_type     TEXT DEFAULT NULL,
  p_side            TEXT DEFAULT NULL,
  p_attendee_count  INT  DEFAULT NULL,
  p_confirmed_count INT  DEFAULT NULL,
  p_contact_phone   TEXT DEFAULT NULL,
  p_address         TEXT DEFAULT NULL,
  p_remarks         TEXT DEFAULT NULL,
  p_rsvp_status     TEXT DEFAULT NULL
) RETURNS JSONB LANGUAGE plpgsql AS $$
DECLARE v_result JSONB;
BEGIN
  UPDATE wedding.guests SET
    family_name     = COALESCE(p_family_name,     family_name),
    family_type     = COALESCE(p_family_type::wedding.family_type_enum, family_type),
    side            = COALESCE(p_side::wedding.side_enum,               side),
    attendee_count  = COALESCE(p_attendee_count,  attendee_count),
    confirmed_count = COALESCE(p_confirmed_count, confirmed_count),
    contact_phone   = COALESCE(p_contact_phone,   contact_phone),
    address         = COALESCE(p_address,         address),
    remarks         = COALESCE(p_remarks,         remarks),
    rsvp_status     = COALESCE(p_rsvp_status::wedding.rsvp_status_enum, rsvp_status),
    updated_at      = NOW()
  WHERE id = p_id AND deleted_at IS NULL;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'GUEST_NOT_FOUND: Guest with id % not found', p_id;
  END IF;

  SELECT wedding.sp_guest_get_by_id(p_id) INTO v_result;
  RETURN v_result;
END; $$;

CREATE OR REPLACE FUNCTION wedding.sp_guest_batch_update(p_updates JSONB)
RETURNS JSONB LANGUAGE plpgsql AS $$
DECLARE
  v_item  JSONB;
  v_count INT := 0;
BEGIN
  FOR v_item IN SELECT * FROM jsonb_array_elements(p_updates)
  LOOP
    PERFORM wedding.sp_guest_update(
      (v_item->>'id')::UUID,
      v_item->>'familyName',
      v_item->>'familyType',
      v_item->>'side',
      NULLIF(v_item->>'attendeeCount','')::INT,
      NULLIF(v_item->>'confirmedCount','')::INT,
      v_item->>'contactPhone',
      v_item->>'address',
      v_item->>'remarks',
      v_item->>'rsvpStatus'
    );
    v_count := v_count + 1;
  END LOOP;
  RETURN jsonb_build_object('updated', v_count);
EXCEPTION WHEN OTHERS THEN
  RAISE EXCEPTION 'sp_guest_batch_update failed: %', SQLERRM;
END; $$;

CREATE OR REPLACE FUNCTION wedding.sp_guest_delete(p_id UUID)
RETURNS JSONB LANGUAGE plpgsql AS $$
BEGIN
  UPDATE wedding.guests SET deleted_at = NOW()
  WHERE id = p_id AND deleted_at IS NULL;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'GUEST_NOT_FOUND: Guest with id % not found', p_id;
  END IF;
  RETURN jsonb_build_object('deleted', TRUE, 'id', p_id);
END; $$;

CREATE OR REPLACE FUNCTION wedding.sp_guest_get_summary()
RETURNS JSONB LANGUAGE plpgsql AS $$
DECLARE v_result JSONB;
BEGIN
  SELECT row_to_json(r) INTO v_result FROM (
    SELECT
      COUNT(*)                                          AS total_families,
      COALESCE(SUM(attendee_count), 0)                  AS total_estimated_attendees,
      COALESCE(SUM(COALESCE(confirmed_count, 0)), 0)    AS total_confirmed_attendees,
      COUNT(*) FILTER (WHERE family_type = 'CHULEY')    AS chuley_count,
      COUNT(*) FILTER (WHERE family_type = 'SINGLE')    AS single_count,
      COUNT(*) FILTER (WHERE rsvp_status = 'CONFIRMED') AS rsvp_confirmed,
      COUNT(*) FILTER (WHERE rsvp_status = 'DECLINED')  AS rsvp_declined,
      COUNT(*) FILTER (WHERE rsvp_status = 'PENDING')   AS rsvp_pending
    FROM wedding.guests WHERE deleted_at IS NULL
  ) r;
  RETURN v_result;
END; $$;

-- ---------------------------------------------------------------------------
-- GIFTS
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION wedding.sp_gift_get_by_id(p_id UUID)
RETURNS JSONB LANGUAGE plpgsql AS $$
DECLARE v_result JSONB;
BEGIN
  SELECT row_to_json(r) INTO v_result FROM (
    SELECT g.id, g.guest_id, g.gift_type, g.amount, g.description,
           g.received_at, g.remarks, g.created_at, g.updated_at,
           gs.family_name
    FROM wedding.gifts g
    JOIN wedding.guests gs ON gs.id = g.guest_id
    WHERE g.id = p_id AND g.deleted_at IS NULL
  ) r;
  IF v_result IS NULL THEN
    RAISE EXCEPTION 'GIFT_NOT_FOUND: Gift with id % not found', p_id;
  END IF;
  RETURN v_result;
END; $$;

CREATE OR REPLACE FUNCTION wedding.sp_gift_get_all(p_guest_id UUID DEFAULT NULL)
RETURNS JSONB LANGUAGE plpgsql AS $$
DECLARE v_result JSONB;
BEGIN
  SELECT json_agg(row_to_json(r)) INTO v_result FROM (
    SELECT g.id, g.guest_id, g.gift_type, g.amount, g.description,
           g.received_at, g.remarks, g.created_at, g.updated_at,
           gs.family_name
    FROM wedding.gifts g
    JOIN wedding.guests gs ON gs.id = g.guest_id
    WHERE g.deleted_at IS NULL
      AND (p_guest_id IS NULL OR g.guest_id = p_guest_id)
    ORDER BY g.received_at DESC
  ) r;
  RETURN COALESCE(v_result, '[]'::JSONB);
END; $$;

CREATE OR REPLACE FUNCTION wedding.sp_gift_create(
  p_guest_id    UUID,
  p_gift_type   TEXT,
  p_amount      NUMERIC     DEFAULT NULL,
  p_description TEXT        DEFAULT NULL,
  p_received_at TIMESTAMPTZ DEFAULT NOW(),
  p_remarks     TEXT        DEFAULT NULL
) RETURNS JSONB LANGUAGE plpgsql AS $$
DECLARE v_id UUID;
BEGIN
  -- ensure the guest exists (and is not soft-deleted)
  IF NOT EXISTS (SELECT 1 FROM wedding.guests WHERE id = p_guest_id AND deleted_at IS NULL) THEN
    RAISE EXCEPTION 'GUEST_NOT_FOUND: Guest with id % not found', p_guest_id;
  END IF;

  INSERT INTO wedding.gifts(guest_id, gift_type, amount, description, received_at, remarks)
  VALUES (p_guest_id, p_gift_type::wedding.gift_type_enum,
          p_amount, p_description, COALESCE(p_received_at, NOW()), p_remarks)
  RETURNING id INTO v_id;
  RETURN wedding.sp_gift_get_by_id(v_id);
END; $$;

CREATE OR REPLACE FUNCTION wedding.sp_gift_update(
  p_id          UUID,
  p_gift_type   TEXT    DEFAULT NULL,
  p_amount      NUMERIC DEFAULT NULL,
  p_description TEXT    DEFAULT NULL,
  p_remarks     TEXT    DEFAULT NULL
) RETURNS JSONB LANGUAGE plpgsql AS $$
BEGIN
  UPDATE wedding.gifts SET
    gift_type   = COALESCE(p_gift_type::wedding.gift_type_enum, gift_type),
    amount      = COALESCE(p_amount,      amount),
    description = COALESCE(p_description, description),
    remarks     = COALESCE(p_remarks,     remarks),
    updated_at  = NOW()
  WHERE id = p_id AND deleted_at IS NULL;
  IF NOT FOUND THEN RAISE EXCEPTION 'GIFT_NOT_FOUND: Gift with id % not found', p_id; END IF;
  RETURN wedding.sp_gift_get_by_id(p_id);
END; $$;

CREATE OR REPLACE FUNCTION wedding.sp_gift_get_summary()
RETURNS JSONB LANGUAGE plpgsql AS $$
DECLARE v_result JSONB;
BEGIN
  SELECT row_to_json(r) INTO v_result FROM (
    SELECT
      COALESCE(SUM(amount) FILTER (WHERE gift_type = 'CASH'), 0) AS total_cash,
      COUNT(*) FILTER (WHERE gift_type = 'KIND')                 AS total_kind_items,
      COUNT(*)                                                   AS total_gifts
    FROM wedding.gifts WHERE deleted_at IS NULL
  ) r;
  RETURN v_result;
END; $$;

CREATE OR REPLACE FUNCTION wedding.sp_gift_delete(p_id UUID)
RETURNS JSONB LANGUAGE plpgsql AS $$
BEGIN
  UPDATE wedding.gifts SET deleted_at = NOW() WHERE id = p_id AND deleted_at IS NULL;
  IF NOT FOUND THEN RAISE EXCEPTION 'GIFT_NOT_FOUND: Gift with id % not found', p_id; END IF;
  RETURN jsonb_build_object('deleted', TRUE, 'id', p_id);
END; $$;

-- ---------------------------------------------------------------------------
-- ITINERARY
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION wedding.sp_itinerary_get_by_id(p_id UUID)
RETURNS JSONB LANGUAGE plpgsql AS $$
DECLARE v_result JSONB;
BEGIN
  SELECT row_to_json(r) INTO v_result FROM (
    SELECT id, title, description, event_date, start_time, end_time,
           location, responsible, category, order_index, created_at, updated_at
    FROM wedding.itinerary_events WHERE id = p_id AND deleted_at IS NULL
  ) r;
  IF v_result IS NULL THEN
    RAISE EXCEPTION 'EVENT_NOT_FOUND: Itinerary event with id % not found', p_id;
  END IF;
  RETURN v_result;
END; $$;

CREATE OR REPLACE FUNCTION wedding.sp_itinerary_get_all()
RETURNS JSONB LANGUAGE plpgsql AS $$
DECLARE v_result JSONB;
BEGIN
  SELECT json_agg(row_to_json(r) ORDER BY r.order_index ASC, r.created_at ASC) INTO v_result FROM (
    SELECT id, title, description, event_date, start_time, end_time,
           location, responsible, category, order_index, created_at, updated_at
    FROM wedding.itinerary_events WHERE deleted_at IS NULL
  ) r;
  RETURN COALESCE(v_result, '[]'::JSONB);
END; $$;

CREATE OR REPLACE FUNCTION wedding.sp_itinerary_create(
  p_title       TEXT,
  p_event_date  DATE,
  p_start_time  TEXT,
  p_description TEXT DEFAULT NULL,
  p_end_time    TEXT DEFAULT NULL,
  p_location    TEXT DEFAULT NULL,
  p_responsible TEXT DEFAULT NULL,
  p_category    TEXT DEFAULT 'OTHER',
  p_order_index INT  DEFAULT NULL
) RETURNS JSONB LANGUAGE plpgsql AS $$
DECLARE v_id UUID; v_order INT;
BEGIN
  -- if no order given, append to the end
  IF p_order_index IS NULL THEN
    SELECT COALESCE(MAX(order_index), -1) + 1 INTO v_order
    FROM wedding.itinerary_events WHERE deleted_at IS NULL;
  ELSE
    v_order := p_order_index;
  END IF;

  INSERT INTO wedding.itinerary_events(title, description, event_date,
    start_time, end_time, location, responsible, category, order_index)
  VALUES (p_title, p_description, p_event_date, p_start_time, p_end_time,
          p_location, p_responsible, p_category::wedding.event_category_enum, v_order)
  RETURNING id INTO v_id;
  RETURN wedding.sp_itinerary_get_by_id(v_id);
END; $$;

CREATE OR REPLACE FUNCTION wedding.sp_itinerary_update(
  p_id          UUID,
  p_title       TEXT DEFAULT NULL,
  p_description TEXT DEFAULT NULL,
  p_event_date  DATE DEFAULT NULL,
  p_start_time  TEXT DEFAULT NULL,
  p_end_time    TEXT DEFAULT NULL,
  p_location    TEXT DEFAULT NULL,
  p_responsible TEXT DEFAULT NULL,
  p_category    TEXT DEFAULT NULL,
  p_order_index INT  DEFAULT NULL
) RETURNS JSONB LANGUAGE plpgsql AS $$
BEGIN
  UPDATE wedding.itinerary_events SET
    title       = COALESCE(p_title,       title),
    description = COALESCE(p_description, description),
    event_date  = COALESCE(p_event_date,  event_date),
    start_time  = COALESCE(p_start_time,  start_time),
    end_time    = COALESCE(p_end_time,    end_time),
    location    = COALESCE(p_location,    location),
    responsible = COALESCE(p_responsible, responsible),
    category    = COALESCE(p_category::wedding.event_category_enum, category),
    order_index = COALESCE(p_order_index, order_index),
    updated_at  = NOW()
  WHERE id = p_id AND deleted_at IS NULL;
  IF NOT FOUND THEN RAISE EXCEPTION 'EVENT_NOT_FOUND: Itinerary event with id % not found', p_id; END IF;
  RETURN wedding.sp_itinerary_get_by_id(p_id);
END; $$;

CREATE OR REPLACE FUNCTION wedding.sp_itinerary_reorder(p_order JSONB)
RETURNS JSONB LANGUAGE plpgsql AS $$
DECLARE v_item JSONB;
BEGIN
  FOR v_item IN SELECT * FROM jsonb_array_elements(p_order) LOOP
    UPDATE wedding.itinerary_events
    SET order_index = (v_item->>'orderIndex')::INT, updated_at = NOW()
    WHERE id = (v_item->>'id')::UUID AND deleted_at IS NULL;
  END LOOP;
  RETURN jsonb_build_object('reordered', jsonb_array_length(p_order));
END; $$;

CREATE OR REPLACE FUNCTION wedding.sp_itinerary_delete(p_id UUID)
RETURNS JSONB LANGUAGE plpgsql AS $$
BEGIN
  UPDATE wedding.itinerary_events SET deleted_at = NOW()
  WHERE id = p_id AND deleted_at IS NULL;
  IF NOT FOUND THEN RAISE EXCEPTION 'EVENT_NOT_FOUND: Itinerary event with id % not found', p_id; END IF;
  RETURN jsonb_build_object('deleted', TRUE, 'id', p_id);
END; $$;

-- ---------------------------------------------------------------------------
-- COSTS
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION wedding.sp_cost_get_by_id(p_id UUID)
RETURNS JSONB LANGUAGE plpgsql AS $$
DECLARE v_result JSONB;
BEGIN
  SELECT row_to_json(r) INTO v_result FROM (
    SELECT id, category, item_name, estimated_cost, actual_cost, vendor,
           payment_status, notes, created_at, updated_at
    FROM wedding.cost_items WHERE id = p_id AND deleted_at IS NULL
  ) r;
  IF v_result IS NULL THEN
    RAISE EXCEPTION 'COST_ITEM_NOT_FOUND: Cost item with id % not found', p_id;
  END IF;
  RETURN v_result;
END; $$;

CREATE OR REPLACE FUNCTION wedding.sp_cost_get_all(p_category TEXT DEFAULT NULL)
RETURNS JSONB LANGUAGE plpgsql AS $$
DECLARE v_result JSONB;
BEGIN
  SELECT json_agg(row_to_json(r)) INTO v_result FROM (
    SELECT id, category, item_name, estimated_cost, actual_cost, vendor,
           payment_status, notes, created_at, updated_at
    FROM wedding.cost_items
    WHERE deleted_at IS NULL
      AND (p_category IS NULL OR category = p_category)
    ORDER BY category ASC, created_at ASC
  ) r;
  RETURN COALESCE(v_result, '[]'::JSONB);
END; $$;

CREATE OR REPLACE FUNCTION wedding.sp_cost_create(
  p_category       TEXT,
  p_item_name      TEXT,
  p_estimated_cost NUMERIC,
  p_actual_cost    NUMERIC DEFAULT NULL,
  p_vendor         TEXT    DEFAULT NULL,
  p_payment_status TEXT    DEFAULT NULL,
  p_notes          TEXT    DEFAULT NULL
) RETURNS JSONB LANGUAGE plpgsql AS $$
DECLARE v_id UUID;
BEGIN
  INSERT INTO wedding.cost_items(category, item_name, estimated_cost,
                                  actual_cost, vendor, payment_status, notes)
  VALUES (p_category, p_item_name, p_estimated_cost, p_actual_cost, p_vendor,
          COALESCE(p_payment_status::wedding.payment_status_enum, 'UNPAID'), p_notes)
  RETURNING id INTO v_id;
  RETURN wedding.sp_cost_get_by_id(v_id);
END; $$;

CREATE OR REPLACE FUNCTION wedding.sp_cost_update(
  p_id             UUID,
  p_category       TEXT    DEFAULT NULL,
  p_item_name      TEXT    DEFAULT NULL,
  p_estimated_cost NUMERIC DEFAULT NULL,
  p_actual_cost    NUMERIC DEFAULT NULL,
  p_vendor         TEXT    DEFAULT NULL,
  p_payment_status TEXT    DEFAULT NULL,
  p_notes          TEXT    DEFAULT NULL
) RETURNS JSONB LANGUAGE plpgsql AS $$
BEGIN
  UPDATE wedding.cost_items SET
    category       = COALESCE(p_category,        category),
    item_name      = COALESCE(p_item_name,       item_name),
    estimated_cost = COALESCE(p_estimated_cost,  estimated_cost),
    actual_cost    = COALESCE(p_actual_cost,     actual_cost),
    vendor         = COALESCE(p_vendor,          vendor),
    payment_status = COALESCE(p_payment_status::wedding.payment_status_enum, payment_status),
    notes          = COALESCE(p_notes,           notes),
    updated_at     = NOW()
  WHERE id = p_id AND deleted_at IS NULL;
  IF NOT FOUND THEN RAISE EXCEPTION 'COST_ITEM_NOT_FOUND: Cost item with id % not found', p_id; END IF;
  RETURN wedding.sp_cost_get_by_id(p_id);
END; $$;

CREATE OR REPLACE FUNCTION wedding.sp_cost_get_summary()
RETURNS JSONB LANGUAGE plpgsql AS $$
DECLARE v_result JSONB;
BEGIN
  SELECT row_to_json(r) INTO v_result FROM (
    SELECT
      COALESCE(SUM(estimated_cost), 0)             AS grand_estimated,
      COALESCE(SUM(COALESCE(actual_cost, 0)), 0)   AS grand_actual,
      COALESCE(SUM(estimated_cost), 0) -
        COALESCE(SUM(COALESCE(actual_cost, 0)), 0) AS variance,
      COALESCE(
        (SELECT json_agg(cat_summary)
         FROM (
           SELECT
             category,
             SUM(estimated_cost)           AS estimated,
             SUM(COALESCE(actual_cost, 0)) AS actual,
             COUNT(*)                      AS items
           FROM wedding.cost_items WHERE deleted_at IS NULL
           GROUP BY category
           ORDER BY category
         ) cat_summary),
        '[]'::json
      ) AS by_category
    FROM wedding.cost_items WHERE deleted_at IS NULL
  ) r;
  RETURN v_result;
END; $$;

CREATE OR REPLACE FUNCTION wedding.sp_cost_delete(p_id UUID)
RETURNS JSONB LANGUAGE plpgsql AS $$
BEGIN
  UPDATE wedding.cost_items SET deleted_at = NOW()
  WHERE id = p_id AND deleted_at IS NULL;
  IF NOT FOUND THEN RAISE EXCEPTION 'COST_ITEM_NOT_FOUND: Cost item with id % not found', p_id; END IF;
  RETURN jsonb_build_object('deleted', TRUE, 'id', p_id);
END; $$;

-- =============================================================================
-- END — all objects created/replaced idempotently.
-- =============================================================================
