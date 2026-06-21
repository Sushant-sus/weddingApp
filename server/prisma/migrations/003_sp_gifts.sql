-- 003 — Gift stored procedures (wedding.sp_gift_*)
CREATE OR REPLACE FUNCTION wedding.sp_gift_get_by_id(p_id UUID)
RETURNS JSONB LANGUAGE plpgsql AS $$
DECLARE v_result JSONB;
BEGIN
  SELECT row_to_json(r) INTO v_result FROM (
    SELECT g.id, g.guest_id, g.gift_type, g.amount, g.description,
           g.received_at, g.remarks, g.created_at, g.updated_at, gs.family_name
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
           g.received_at, g.remarks, g.created_at, g.updated_at, gs.family_name
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
