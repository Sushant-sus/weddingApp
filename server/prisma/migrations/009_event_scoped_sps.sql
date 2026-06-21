-- 009 — Re-define data procedures to be event-scoped.
-- p_event_id is a trailing optional param: NULL = legacy behaviour (all rows),
-- a value = scoped to that wedding event. Routes pass it from /events/:eventId.

-- ---------- GUESTS ----------
CREATE OR REPLACE FUNCTION wedding.sp_guest_get_all(
  p_family_type TEXT DEFAULT NULL,
  p_rsvp_status TEXT DEFAULT NULL,
  p_side        TEXT DEFAULT NULL,
  p_event_id    UUID DEFAULT NULL
) RETURNS JSONB LANGUAGE plpgsql AS $$
DECLARE v_result JSONB;
BEGIN
  SELECT json_agg(row_to_json(r)) INTO v_result FROM (
    SELECT id, family_name, family_type, side, attendee_count, confirmed_count,
           contact_phone, address, remarks, rsvp_status, event_id, created_at, updated_at
    FROM wedding.guests
    WHERE deleted_at IS NULL
      AND (p_family_type IS NULL OR family_type = p_family_type::wedding.family_type_enum)
      AND (p_rsvp_status IS NULL OR rsvp_status = p_rsvp_status::wedding.rsvp_status_enum)
      AND (p_side        IS NULL OR side = p_side::wedding.side_enum)
      AND (p_event_id IS NULL OR event_id = p_event_id)
    ORDER BY created_at ASC
  ) r;
  RETURN COALESCE(v_result, '[]'::JSONB);
END; $$;

CREATE OR REPLACE FUNCTION wedding.sp_guest_create(
  p_family_name    TEXT,
  p_family_type    TEXT,
  p_side           TEXT,
  p_attendee_count INT,
  p_contact_phone  TEXT DEFAULT NULL,
  p_address        TEXT DEFAULT NULL,
  p_remarks        TEXT DEFAULT NULL,
  p_event_id       UUID DEFAULT NULL
) RETURNS JSONB LANGUAGE plpgsql AS $$
DECLARE v_id UUID; v_result JSONB;
BEGIN
  INSERT INTO wedding.guests(family_name, family_type, side, attendee_count,
              contact_phone, address, remarks, event_id)
  VALUES (p_family_name, p_family_type::wedding.family_type_enum,
          p_side::wedding.side_enum, p_attendee_count,
          p_contact_phone, p_address, p_remarks, p_event_id)
  RETURNING id INTO v_id;
  SELECT wedding.sp_guest_get_by_id(v_id) INTO v_result;
  RETURN v_result;
END; $$;

CREATE OR REPLACE FUNCTION wedding.sp_guest_get_summary(p_event_id UUID DEFAULT NULL)
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
    FROM wedding.guests
    WHERE deleted_at IS NULL AND (p_event_id IS NULL OR event_id = p_event_id)
  ) r;
  RETURN v_result;
END; $$;

-- ---------- GIFTS ----------
CREATE OR REPLACE FUNCTION wedding.sp_gift_get_all(
  p_guest_id UUID DEFAULT NULL,
  p_event_id UUID DEFAULT NULL
) RETURNS JSONB LANGUAGE plpgsql AS $$
DECLARE v_result JSONB;
BEGIN
  SELECT json_agg(row_to_json(r)) INTO v_result FROM (
    SELECT g.id, g.guest_id, g.gift_type, g.amount, g.description,
           g.received_at, g.remarks, g.event_id, g.created_at, g.updated_at, gs.family_name
    FROM wedding.gifts g
    JOIN wedding.guests gs ON gs.id = g.guest_id
    WHERE g.deleted_at IS NULL
      AND (p_guest_id IS NULL OR g.guest_id = p_guest_id)
      AND (p_event_id IS NULL OR g.event_id = p_event_id)
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
  p_remarks     TEXT        DEFAULT NULL,
  p_event_id    UUID        DEFAULT NULL
) RETURNS JSONB LANGUAGE plpgsql AS $$
DECLARE v_id UUID; v_event UUID;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM wedding.guests WHERE id = p_guest_id AND deleted_at IS NULL) THEN
    RAISE EXCEPTION 'GUEST_NOT_FOUND: Guest with id % not found', p_guest_id;
  END IF;
  -- default the gift's event to the guest's event when not provided
  v_event := p_event_id;
  IF v_event IS NULL THEN
    SELECT event_id INTO v_event FROM wedding.guests WHERE id = p_guest_id;
  END IF;

  INSERT INTO wedding.gifts(guest_id, gift_type, amount, description, received_at, remarks, event_id)
  VALUES (p_guest_id, p_gift_type::wedding.gift_type_enum,
          p_amount, p_description, COALESCE(p_received_at, NOW()), p_remarks, v_event)
  RETURNING id INTO v_id;
  RETURN wedding.sp_gift_get_by_id(v_id);
END; $$;

CREATE OR REPLACE FUNCTION wedding.sp_gift_get_summary(p_event_id UUID DEFAULT NULL)
RETURNS JSONB LANGUAGE plpgsql AS $$
DECLARE v_result JSONB;
BEGIN
  SELECT row_to_json(r) INTO v_result FROM (
    SELECT
      COALESCE(SUM(amount) FILTER (WHERE gift_type = 'CASH'), 0) AS total_cash,
      COUNT(*) FILTER (WHERE gift_type = 'KIND')                 AS total_kind_items,
      COUNT(*)                                                   AS total_gifts
    FROM wedding.gifts
    WHERE deleted_at IS NULL AND (p_event_id IS NULL OR event_id = p_event_id)
  ) r;
  RETURN v_result;
END; $$;

-- ---------- ITINERARY ----------
CREATE OR REPLACE FUNCTION wedding.sp_itinerary_get_all(p_event_id UUID DEFAULT NULL)
RETURNS JSONB LANGUAGE plpgsql AS $$
DECLARE v_result JSONB;
BEGIN
  SELECT json_agg(row_to_json(r) ORDER BY r.order_index ASC, r.created_at ASC) INTO v_result FROM (
    SELECT id, title, description, event_date, start_time, end_time,
           location, responsible, category, order_index, event_id, created_at, updated_at
    FROM wedding.itinerary_events
    WHERE deleted_at IS NULL AND (p_event_id IS NULL OR event_id = p_event_id)
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
  p_order_index INT  DEFAULT NULL,
  p_event_id    UUID DEFAULT NULL
) RETURNS JSONB LANGUAGE plpgsql AS $$
DECLARE v_id UUID; v_order INT;
BEGIN
  IF p_order_index IS NULL THEN
    SELECT COALESCE(MAX(order_index), -1) + 1 INTO v_order
    FROM wedding.itinerary_events
    WHERE deleted_at IS NULL AND (p_event_id IS NULL OR event_id = p_event_id);
  ELSE
    v_order := p_order_index;
  END IF;
  INSERT INTO wedding.itinerary_events(title, description, event_date, start_time, end_time,
    location, responsible, category, order_index, event_id)
  VALUES (p_title, p_description, p_event_date, p_start_time, p_end_time,
          p_location, p_responsible, p_category::wedding.event_category_enum, v_order, p_event_id)
  RETURNING id INTO v_id;
  RETURN wedding.sp_itinerary_get_by_id(v_id);
END; $$;

-- ---------- COSTS ----------
CREATE OR REPLACE FUNCTION wedding.sp_cost_get_all(
  p_category TEXT DEFAULT NULL,
  p_event_id UUID DEFAULT NULL
) RETURNS JSONB LANGUAGE plpgsql AS $$
DECLARE v_result JSONB;
BEGIN
  SELECT json_agg(row_to_json(r)) INTO v_result FROM (
    SELECT id, category, item_name, estimated_cost, actual_cost, vendor,
           payment_status, notes, event_id, created_at, updated_at
    FROM wedding.cost_items
    WHERE deleted_at IS NULL
      AND (p_category IS NULL OR category = p_category)
      AND (p_event_id IS NULL OR event_id = p_event_id)
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
  p_notes          TEXT    DEFAULT NULL,
  p_event_id       UUID    DEFAULT NULL
) RETURNS JSONB LANGUAGE plpgsql AS $$
DECLARE v_id UUID;
BEGIN
  INSERT INTO wedding.cost_items(category, item_name, estimated_cost, actual_cost,
                                  vendor, payment_status, notes, event_id)
  VALUES (p_category, p_item_name, p_estimated_cost, p_actual_cost, p_vendor,
          COALESCE(p_payment_status::wedding.payment_status_enum, 'UNPAID'), p_notes, p_event_id)
  RETURNING id INTO v_id;
  RETURN wedding.sp_cost_get_by_id(v_id);
END; $$;

CREATE OR REPLACE FUNCTION wedding.sp_cost_get_summary(p_event_id UUID DEFAULT NULL)
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
        (SELECT json_agg(cat_summary) FROM (
           SELECT category, SUM(estimated_cost) AS estimated,
                  SUM(COALESCE(actual_cost, 0)) AS actual, COUNT(*) AS items
           FROM wedding.cost_items
           WHERE deleted_at IS NULL AND (p_event_id IS NULL OR event_id = p_event_id)
           GROUP BY category ORDER BY category
         ) cat_summary), '[]'::json) AS by_category
    FROM wedding.cost_items
    WHERE deleted_at IS NULL AND (p_event_id IS NULL OR event_id = p_event_id)
  ) r;
  RETURN v_result;
END; $$;
