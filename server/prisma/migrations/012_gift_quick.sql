-- 012 — Fast gift-desk recording: allow gifts with a free-text giver (no guest row).
-- ADDITIVE + backward compatible. Existing gifts keep their guest_id and still show
-- their family_name. New gifts may instead carry a giver_name with a NULL guest_id.

-- guest_id becomes optional; add a free-text giver name.
ALTER TABLE wedding.gifts ALTER COLUMN guest_id DROP NOT NULL;
ALTER TABLE wedding.gifts ADD COLUMN IF NOT EXISTS giver_name TEXT;

-- Redefine the read SPs to LEFT JOIN guests and surface the giver either way.
-- family_name = the guest's family name, or the free-text giver name. This keeps
-- existing clients (which read family_name) working unchanged.
CREATE OR REPLACE FUNCTION wedding.sp_gift_get_by_id(p_id UUID)
RETURNS JSONB LANGUAGE plpgsql AS $$
DECLARE v_result JSONB;
BEGIN
  SELECT row_to_json(r) INTO v_result FROM (
    SELECT g.id, g.guest_id, g.gift_type, g.amount, g.description,
           g.received_at, g.remarks, g.event_id, g.created_at, g.updated_at,
           g.giver_name,
           COALESCE(gs.family_name, g.giver_name) AS family_name
    FROM wedding.gifts g
    LEFT JOIN wedding.guests gs ON gs.id = g.guest_id
    WHERE g.id = p_id AND g.deleted_at IS NULL
  ) r;
  IF v_result IS NULL THEN
    RAISE EXCEPTION 'GIFT_NOT_FOUND: Gift with id % not found', p_id;
  END IF;
  RETURN v_result;
END; $$;

CREATE OR REPLACE FUNCTION wedding.sp_gift_get_all(
  p_guest_id UUID DEFAULT NULL,
  p_event_id UUID DEFAULT NULL
) RETURNS JSONB LANGUAGE plpgsql AS $$
DECLARE v_result JSONB;
BEGIN
  SELECT json_agg(row_to_json(r)) INTO v_result FROM (
    SELECT g.id, g.guest_id, g.gift_type, g.amount, g.description,
           g.received_at, g.remarks, g.event_id, g.created_at, g.updated_at,
           g.giver_name,
           COALESCE(gs.family_name, g.giver_name) AS family_name
    FROM wedding.gifts g
    LEFT JOIN wedding.guests gs ON gs.id = g.guest_id
    WHERE g.deleted_at IS NULL
      AND (p_guest_id IS NULL OR g.guest_id = p_guest_id)
      AND (p_event_id IS NULL OR g.event_id = p_event_id)
    ORDER BY g.received_at DESC
  ) r;
  RETURN COALESCE(v_result, '[]'::JSONB);
END; $$;

-- Quick-create: record a gift tied to a guest OR to a free-text giver name.
CREATE OR REPLACE FUNCTION wedding.sp_gift_quick_create(
  p_event_id    UUID,
  p_guest_id    UUID    DEFAULT NULL,
  p_giver_name  TEXT    DEFAULT NULL,
  p_gift_type   TEXT    DEFAULT 'CASH',
  p_amount      NUMERIC DEFAULT NULL,
  p_description TEXT    DEFAULT NULL,
  p_remarks     TEXT    DEFAULT NULL
) RETURNS JSONB LANGUAGE plpgsql AS $$
DECLARE v_id UUID; v_event UUID;
BEGIN
  IF p_guest_id IS NULL AND (p_giver_name IS NULL OR btrim(p_giver_name) = '') THEN
    RAISE EXCEPTION 'GIVER_REQUIRED: A guest or giver name is required';
  END IF;

  v_event := p_event_id;
  IF p_guest_id IS NOT NULL THEN
    IF NOT EXISTS (SELECT 1 FROM wedding.guests WHERE id = p_guest_id AND deleted_at IS NULL) THEN
      RAISE EXCEPTION 'GUEST_NOT_FOUND: Guest with id % not found', p_guest_id;
    END IF;
    IF v_event IS NULL THEN
      SELECT event_id INTO v_event FROM wedding.guests WHERE id = p_guest_id;
    END IF;
  END IF;

  INSERT INTO wedding.gifts(guest_id, giver_name, gift_type, amount, description, received_at, remarks, event_id)
  VALUES (
    p_guest_id,
    CASE WHEN p_guest_id IS NULL THEN btrim(p_giver_name) ELSE NULL END,
    p_gift_type::wedding.gift_type_enum,
    p_amount, p_description, NOW(), p_remarks, v_event
  )
  RETURNING id INTO v_id;
  RETURN wedding.sp_gift_get_by_id(v_id);
END; $$;
