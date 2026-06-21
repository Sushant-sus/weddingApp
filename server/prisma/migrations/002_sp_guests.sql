-- 002 — Guest stored procedures (wedding.sp_guest_*)
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
DECLARE v_item JSONB; v_count INT := 0;
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
