-- 013 — Itinerary event status: mark an event complete (DONE) or cancelled.
-- ADDITIVE + backward compatible. New nullable-with-default column; read SPs gain
-- a `status` field; existing rows default to 'PLANNED'. Idempotent.

ALTER TABLE wedding.itinerary_events
  ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'PLANNED';  -- PLANNED | DONE | CANCELLED

-- Read SPs now expose status (additive field; existing clients ignore it).
CREATE OR REPLACE FUNCTION wedding.sp_itinerary_get_by_id(p_id UUID)
RETURNS JSONB LANGUAGE plpgsql AS $$
DECLARE v_result JSONB;
BEGIN
  SELECT row_to_json(r) INTO v_result FROM (
    SELECT id, title, description, event_date, start_time, end_time,
           location, responsible, category, order_index, status,
           event_id, created_at, updated_at
    FROM wedding.itinerary_events WHERE id = p_id AND deleted_at IS NULL
  ) r;
  IF v_result IS NULL THEN
    RAISE EXCEPTION 'EVENT_NOT_FOUND: Itinerary event with id % not found', p_id;
  END IF;
  RETURN v_result;
END; $$;

CREATE OR REPLACE FUNCTION wedding.sp_itinerary_get_all(p_event_id UUID DEFAULT NULL)
RETURNS JSONB LANGUAGE plpgsql AS $$
DECLARE v_result JSONB;
BEGIN
  SELECT json_agg(row_to_json(r) ORDER BY r.order_index ASC, r.created_at ASC) INTO v_result FROM (
    SELECT id, title, description, event_date, start_time, end_time,
           location, responsible, category, order_index, status,
           event_id, created_at, updated_at
    FROM wedding.itinerary_events
    WHERE deleted_at IS NULL AND (p_event_id IS NULL OR event_id = p_event_id)
  ) r;
  RETURN COALESCE(v_result, '[]'::JSONB);
END; $$;

-- Set an event's status (PLANNED / DONE / CANCELLED).
CREATE OR REPLACE FUNCTION wedding.sp_itinerary_set_status(p_id UUID, p_status TEXT)
RETURNS JSONB LANGUAGE plpgsql AS $$
BEGIN
  IF p_status NOT IN ('PLANNED', 'DONE', 'CANCELLED') THEN
    RAISE EXCEPTION 'INVALID_STATUS: Status must be PLANNED, DONE or CANCELLED';
  END IF;
  UPDATE wedding.itinerary_events SET status = p_status, updated_at = NOW()
  WHERE id = p_id AND deleted_at IS NULL;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'EVENT_NOT_FOUND: Itinerary event with id % not found', p_id;
  END IF;
  RETURN wedding.sp_itinerary_get_by_id(p_id);
END; $$;
