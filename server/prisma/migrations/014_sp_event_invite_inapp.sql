-- 014 — In-app invite acceptance.
-- Lets an authenticated user accept/decline an invite addressed to them by
-- event id (no email token needed). Secure: the WHERE clause only matches the
-- caller's own PENDING membership row. Expiry is intentionally NOT enforced
-- here — the user is signed in and acting on their own invite — so invites
-- whose 48h email-token window lapsed can still be accepted from inside the app.

CREATE OR REPLACE FUNCTION wedding.sp_event_accept_invite_by_event(
  p_user_id UUID, p_event_id UUID
) RETURNS JSONB LANGUAGE plpgsql AS $$
DECLARE v_event_id UUID;
BEGIN
  UPDATE wedding.event_members
  SET invite_status = 'ACCEPTED', joined_at = NOW(),
      invite_token = NULL, updated_at = NOW()
  WHERE user_id = p_user_id AND event_id = p_event_id
    AND invite_status = 'PENDING'
  RETURNING event_id INTO v_event_id;

  IF v_event_id IS NULL THEN
    RAISE EXCEPTION 'INVALID_INVITE: No pending invite for this event';
  END IF;
  RETURN wedding.sp_event_get_by_id(v_event_id, p_user_id);
END; $$;

CREATE OR REPLACE FUNCTION wedding.sp_event_decline_invite_by_event(
  p_user_id UUID, p_event_id UUID
) RETURNS JSONB LANGUAGE plpgsql AS $$
BEGIN
  UPDATE wedding.event_members
  SET invite_status = 'DECLINED', updated_at = NOW()
  WHERE user_id = p_user_id AND event_id = p_event_id AND invite_status = 'PENDING';
  IF NOT FOUND THEN
    RAISE EXCEPTION 'INVALID_INVITE: No pending invite for this event';
  END IF;
  RETURN jsonb_build_object('declined', TRUE);
END; $$;

-- Hide DECLINED memberships from the user's event list (ACCEPTED + PENDING stay
-- visible so a pending invite can be acted on from the list).
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
      AND em.invite_status <> 'DECLINED'
    ORDER BY e.wedding_date DESC
  ) r;
  RETURN COALESCE(v_result, '[]'::JSONB);
END; $$;
