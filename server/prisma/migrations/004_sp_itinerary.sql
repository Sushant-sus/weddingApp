-- 004 — Itinerary stored procedures (wedding.sp_itinerary_*)
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
