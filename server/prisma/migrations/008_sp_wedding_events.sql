-- 008 — Wedding event + membership stored procedures (wedding.sp_event_*)

CREATE OR REPLACE FUNCTION wedding.sp_event_get_by_id(
  p_event_id UUID,
  p_user_id  UUID
) RETURNS JSONB LANGUAGE plpgsql AS $$
DECLARE v_result JSONB;
BEGIN
  SELECT row_to_json(r) INTO v_result FROM (
    SELECT
      e.id, e.name, e.wedding_date, e.venue, e.description,
      e.created_by, e.is_active, e.created_at, e.updated_at,
      em.event_role AS my_role,
      (SELECT COUNT(*) FROM wedding.event_members
       WHERE event_id = e.id AND invite_status = 'ACCEPTED') AS member_count
    FROM wedding.wedding_events e
    JOIN wedding.event_members em ON em.event_id = e.id
    WHERE e.id = p_event_id
      AND em.user_id = p_user_id
      AND em.invite_status = 'ACCEPTED'
      AND e.deleted_at IS NULL
  ) r;

  IF v_result IS NULL THEN
    RAISE EXCEPTION 'EVENT_NOT_FOUND_OR_NO_ACCESS';
  END IF;
  RETURN v_result;
END; $$;

CREATE OR REPLACE FUNCTION wedding.sp_event_create(
  p_user_id      UUID,
  p_name         TEXT,
  p_wedding_date DATE,
  p_venue        TEXT DEFAULT NULL,
  p_description  TEXT DEFAULT NULL
) RETURNS JSONB LANGUAGE plpgsql AS $$
DECLARE v_event_id UUID;
BEGIN
  INSERT INTO wedding.wedding_events(name, wedding_date, venue, description, created_by)
  VALUES (p_name, p_wedding_date, p_venue, p_description, p_user_id)
  RETURNING id INTO v_event_id;

  INSERT INTO wedding.event_members(event_id, user_id, event_role, invite_status, joined_at)
  VALUES (v_event_id, p_user_id, 'OWNER', 'ACCEPTED', NOW());

  RETURN wedding.sp_event_get_by_id(v_event_id, p_user_id);
END; $$;

CREATE OR REPLACE FUNCTION wedding.sp_event_get_all_for_user(p_user_id UUID)
RETURNS JSONB LANGUAGE plpgsql AS $$
DECLARE v_result JSONB;
BEGIN
  SELECT json_agg(row_to_json(r)) INTO v_result FROM (
    SELECT
      e.id, e.name, e.wedding_date, e.venue, e.description,
      e.is_active, e.created_at,
      em.event_role AS my_role,
      em.invite_status,
      (SELECT COUNT(*) FROM wedding.event_members
       WHERE event_id = e.id AND invite_status = 'ACCEPTED') AS member_count,
      (SELECT COUNT(*) FROM wedding.guests
       WHERE event_id = e.id AND deleted_at IS NULL) AS guest_count
    FROM wedding.wedding_events e
    JOIN wedding.event_members em ON em.event_id = e.id AND em.user_id = p_user_id
    WHERE e.deleted_at IS NULL
    ORDER BY e.wedding_date DESC
  ) r;
  RETURN COALESCE(v_result, '[]'::JSONB);
END; $$;

CREATE OR REPLACE FUNCTION wedding.sp_event_update(
  p_event_id    UUID,
  p_name        TEXT DEFAULT NULL,
  p_wedding_date DATE DEFAULT NULL,
  p_venue       TEXT DEFAULT NULL,
  p_description TEXT DEFAULT NULL
) RETURNS JSONB LANGUAGE plpgsql AS $$
DECLARE v_creator UUID;
BEGIN
  UPDATE wedding.wedding_events SET
    name         = COALESCE(p_name, name),
    wedding_date = COALESCE(p_wedding_date, wedding_date),
    venue        = COALESCE(p_venue, venue),
    description  = COALESCE(p_description, description),
    updated_at   = NOW()
  WHERE id = p_event_id AND deleted_at IS NULL
  RETURNING created_by INTO v_creator;

  IF v_creator IS NULL THEN RAISE EXCEPTION 'EVENT_NOT_FOUND'; END IF;
  RETURN wedding.sp_event_get_by_id(p_event_id, v_creator);
END; $$;

CREATE OR REPLACE FUNCTION wedding.sp_event_delete(p_event_id UUID)
RETURNS JSONB LANGUAGE plpgsql AS $$
BEGIN
  UPDATE wedding.wedding_events SET deleted_at = NOW(), updated_at = NOW()
  WHERE id = p_event_id AND deleted_at IS NULL;
  IF NOT FOUND THEN RAISE EXCEPTION 'EVENT_NOT_FOUND'; END IF;
  RETURN jsonb_build_object('deleted', TRUE, 'id', p_event_id);
END; $$;

CREATE OR REPLACE FUNCTION wedding.sp_event_get_members(p_event_id UUID)
RETURNS JSONB LANGUAGE plpgsql AS $$
DECLARE v_result JSONB;
BEGIN
  SELECT json_agg(row_to_json(r)) INTO v_result FROM (
    SELECT
      em.id, em.event_role, em.invite_status, em.joined_at,
      u.id AS user_id, u.full_name, u.email,
      inviter.full_name AS invited_by_name
    FROM wedding.event_members em
    JOIN wedding.users u ON u.id = em.user_id
    LEFT JOIN wedding.users inviter ON inviter.id = em.invited_by
    WHERE em.event_id = p_event_id
    ORDER BY CASE em.event_role
        WHEN 'OWNER' THEN 1 WHEN 'LEADER' THEN 2 WHEN 'EDITOR' THEN 3
        WHEN 'CONTRIBUTOR' THEN 4 WHEN 'VIEWER' THEN 5 END
  ) r;
  RETURN COALESCE(v_result, '[]'::JSONB);
END; $$;

CREATE OR REPLACE FUNCTION wedding.sp_event_invite_member(
  p_event_id   UUID,
  p_inviter_id UUID,
  p_email      TEXT,
  p_event_role TEXT
) RETURNS JSONB LANGUAGE plpgsql AS $$
DECLARE v_invitee_id UUID; v_invite_token TEXT; v_member_role TEXT;
BEGIN
  SELECT event_role INTO v_member_role FROM wedding.event_members
  WHERE event_id = p_event_id AND user_id = p_inviter_id AND invite_status = 'ACCEPTED';

  IF v_member_role IS NULL OR v_member_role NOT IN ('OWNER', 'LEADER') THEN
    RAISE EXCEPTION 'INSUFFICIENT_PERMISSION: Only OWNER or LEADER can invite members';
  END IF;
  IF v_member_role = 'LEADER' AND p_event_role = 'OWNER' THEN
    RAISE EXCEPTION 'INSUFFICIENT_PERMISSION: LEADER cannot assign OWNER role';
  END IF;

  SELECT id INTO v_invitee_id FROM wedding.users
  WHERE email = p_email AND deleted_at IS NULL AND is_active = TRUE;
  IF v_invitee_id IS NULL THEN
    RAISE EXCEPTION 'USER_NOT_FOUND: No registered user found with email %', p_email;
  END IF;

  IF EXISTS (SELECT 1 FROM wedding.event_members
             WHERE event_id = p_event_id AND user_id = v_invitee_id) THEN
    RAISE EXCEPTION 'ALREADY_A_MEMBER: User is already a member of this event';
  END IF;

  v_invite_token := encode(gen_random_bytes(32), 'hex');

  INSERT INTO wedding.event_members(
    event_id, user_id, event_role, invited_by, invite_token, invite_expires_at)
  VALUES (p_event_id, v_invitee_id, p_event_role, p_inviter_id,
          v_invite_token, NOW() + INTERVAL '48 hours');

  RETURN jsonb_build_object(
    'invite_token', v_invite_token, 'invitee_email', p_email,
    'event_role', p_event_role, 'expires_in', '48 hours');
END; $$;

CREATE OR REPLACE FUNCTION wedding.sp_event_accept_invite(
  p_user_id UUID, p_invite_token TEXT
) RETURNS JSONB LANGUAGE plpgsql AS $$
DECLARE v_event_id UUID;
BEGIN
  UPDATE wedding.event_members
  SET invite_status = 'ACCEPTED', joined_at = NOW(),
      invite_token = NULL, updated_at = NOW()
  WHERE user_id = p_user_id AND invite_token = p_invite_token
    AND invite_status = 'PENDING' AND invite_expires_at > NOW()
  RETURNING event_id INTO v_event_id;

  IF v_event_id IS NULL THEN
    RAISE EXCEPTION 'INVALID_INVITE: Invite token is invalid or expired';
  END IF;
  RETURN wedding.sp_event_get_by_id(v_event_id, p_user_id);
END; $$;

CREATE OR REPLACE FUNCTION wedding.sp_event_decline_invite(
  p_user_id UUID, p_invite_token TEXT
) RETURNS JSONB LANGUAGE plpgsql AS $$
BEGIN
  UPDATE wedding.event_members
  SET invite_status = 'DECLINED', updated_at = NOW()
  WHERE user_id = p_user_id AND invite_token = p_invite_token AND invite_status = 'PENDING';
  IF NOT FOUND THEN RAISE EXCEPTION 'INVALID_INVITE: Invite not found'; END IF;
  RETURN jsonb_build_object('declined', TRUE);
END; $$;

CREATE OR REPLACE FUNCTION wedding.sp_event_change_member_role(
  p_event_id UUID, p_changer_id UUID, p_target_user_id UUID, p_new_role TEXT
) RETURNS JSONB LANGUAGE plpgsql AS $$
DECLARE v_changer_role TEXT; v_target_role TEXT;
BEGIN
  SELECT event_role INTO v_changer_role FROM wedding.event_members
  WHERE event_id = p_event_id AND user_id = p_changer_id AND invite_status = 'ACCEPTED';
  SELECT event_role INTO v_target_role FROM wedding.event_members
  WHERE event_id = p_event_id AND user_id = p_target_user_id;

  IF v_target_role = 'OWNER' THEN RAISE EXCEPTION 'CANNOT_CHANGE_OWNER_ROLE'; END IF;
  IF v_changer_role IS NULL OR v_changer_role NOT IN ('OWNER', 'LEADER') THEN
    RAISE EXCEPTION 'INSUFFICIENT_PERMISSION';
  END IF;
  IF p_new_role = 'OWNER' OR (p_new_role = 'LEADER' AND v_changer_role <> 'OWNER') THEN
    RAISE EXCEPTION 'INSUFFICIENT_PERMISSION';
  END IF;

  UPDATE wedding.event_members SET event_role = p_new_role, updated_at = NOW()
  WHERE event_id = p_event_id AND user_id = p_target_user_id;

  RETURN jsonb_build_object('role_changed', TRUE, 'new_role', p_new_role);
END; $$;

CREATE OR REPLACE FUNCTION wedding.sp_event_remove_member(
  p_event_id UUID, p_remover_id UUID, p_target_user_id UUID
) RETURNS JSONB LANGUAGE plpgsql AS $$
DECLARE v_remover_role TEXT; v_target_role TEXT;
BEGIN
  SELECT event_role INTO v_remover_role FROM wedding.event_members
  WHERE event_id = p_event_id AND user_id = p_remover_id AND invite_status = 'ACCEPTED';
  SELECT event_role INTO v_target_role FROM wedding.event_members
  WHERE event_id = p_event_id AND user_id = p_target_user_id;

  IF v_target_role = 'OWNER' THEN RAISE EXCEPTION 'CANNOT_REMOVE_OWNER'; END IF;
  IF v_remover_role IS NULL OR v_remover_role NOT IN ('OWNER', 'LEADER') THEN
    RAISE EXCEPTION 'INSUFFICIENT_PERMISSION';
  END IF;

  DELETE FROM wedding.event_members
  WHERE event_id = p_event_id AND user_id = p_target_user_id;

  RETURN jsonb_build_object('removed', TRUE, 'user_id', p_target_user_id);
END; $$;

CREATE OR REPLACE FUNCTION wedding.sp_event_transfer_ownership(
  p_event_id UUID, p_current_owner_id UUID, p_new_owner_id UUID
) RETURNS JSONB LANGUAGE plpgsql AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM wedding.event_members
    WHERE event_id = p_event_id AND user_id = p_current_owner_id
      AND event_role = 'OWNER' AND invite_status = 'ACCEPTED') THEN
    RAISE EXCEPTION 'INSUFFICIENT_PERMISSION: Only OWNER can transfer ownership';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM wedding.event_members
    WHERE event_id = p_event_id AND user_id = p_new_owner_id AND invite_status = 'ACCEPTED') THEN
    RAISE EXCEPTION 'USER_NOT_MEMBER: New owner must already be a member';
  END IF;

  UPDATE wedding.event_members SET event_role = 'LEADER', updated_at = NOW()
  WHERE event_id = p_event_id AND user_id = p_current_owner_id;
  UPDATE wedding.event_members SET event_role = 'OWNER', updated_at = NOW()
  WHERE event_id = p_event_id AND user_id = p_new_owner_id;
  UPDATE wedding.wedding_events SET created_by = p_new_owner_id, updated_at = NOW()
  WHERE id = p_event_id;

  RETURN jsonb_build_object('ownership_transferred', TRUE);
END; $$;

CREATE OR REPLACE FUNCTION wedding.sp_event_log_activity(
  p_event_id UUID, p_user_id UUID, p_action TEXT,
  p_entity_type TEXT DEFAULT NULL, p_entity_id UUID DEFAULT NULL, p_metadata JSONB DEFAULT NULL
) RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO wedding.event_activity_log(event_id, user_id, action, entity_type, entity_id, metadata)
  VALUES (p_event_id, p_user_id, p_action, p_entity_type, p_entity_id, p_metadata);
END; $$;

CREATE OR REPLACE FUNCTION wedding.sp_event_get_activity_log(
  p_event_id UUID, p_limit INT DEFAULT 50
) RETURNS JSONB LANGUAGE plpgsql AS $$
DECLARE v_result JSONB;
BEGIN
  SELECT json_agg(row_to_json(r)) INTO v_result FROM (
    SELECT al.action, al.entity_type, al.entity_id, al.metadata, al.created_at,
           u.full_name, u.email
    FROM wedding.event_activity_log al
    JOIN wedding.users u ON u.id = al.user_id
    WHERE al.event_id = p_event_id
    ORDER BY al.created_at DESC
    LIMIT p_limit
  ) r;
  RETURN COALESCE(v_result, '[]'::JSONB);
END; $$;

-- Lightweight membership lookup used by the requireEventRole middleware.
CREATE OR REPLACE FUNCTION wedding.sp_event_get_my_membership(
  p_event_id UUID, p_user_id UUID
) RETURNS JSONB LANGUAGE plpgsql AS $$
DECLARE v_result JSONB;
BEGIN
  SELECT row_to_json(r) INTO v_result FROM (
    SELECT event_role, invite_status
    FROM wedding.event_members
    WHERE event_id = p_event_id AND user_id = p_user_id
  ) r;
  RETURN v_result; -- may be NULL (not a member); middleware handles it
END; $$;
