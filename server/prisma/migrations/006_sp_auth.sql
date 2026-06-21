-- 006 — Authentication stored procedures (wedding.sp_auth_*, wedding.sp_admin_*)

CREATE OR REPLACE FUNCTION wedding.sp_auth_register(
  p_full_name TEXT,
  p_email     TEXT,
  p_password_hash TEXT
) RETURNS JSONB LANGUAGE plpgsql AS $$
DECLARE v_user_id UUID; v_viewer_role_id UUID;
BEGIN
  IF EXISTS (SELECT 1 FROM wedding.users WHERE email = p_email AND deleted_at IS NULL) THEN
    RAISE EXCEPTION 'EMAIL_ALREADY_EXISTS: Email % is already registered', p_email;
  END IF;

  SELECT id INTO v_viewer_role_id FROM wedding.roles WHERE name = 'VIEWER';

  INSERT INTO wedding.users(full_name, email, password_hash, role_id)
  VALUES (p_full_name, p_email, p_password_hash, v_viewer_role_id)
  RETURNING id INTO v_user_id;

  RETURN jsonb_build_object('user_id', v_user_id, 'email', p_email);
END; $$;

CREATE OR REPLACE FUNCTION wedding.sp_auth_get_user_by_email(p_email TEXT)
RETURNS JSONB LANGUAGE plpgsql AS $$
DECLARE v_result JSONB;
BEGIN
  SELECT row_to_json(r) INTO v_result FROM (
    SELECT
      u.id, u.full_name, u.email, u.password_hash,
      u.is_active, u.is_email_verified,
      r.name AS role_name, r.id AS role_id,
      COALESCE(json_agg(p.name) FILTER (WHERE p.name IS NOT NULL), '[]') AS permissions
    FROM wedding.users u
    LEFT JOIN wedding.roles r ON r.id = u.role_id
    LEFT JOIN wedding.role_permissions rp ON rp.role_id = r.id
    LEFT JOIN wedding.permissions p ON p.id = rp.permission_id
    WHERE u.email = p_email AND u.deleted_at IS NULL
    GROUP BY u.id, r.name, r.id
  ) r;

  IF v_result IS NULL THEN
    RAISE EXCEPTION 'USER_NOT_FOUND: No user found with email %', p_email;
  END IF;
  RETURN v_result;
END; $$;

CREATE OR REPLACE FUNCTION wedding.sp_auth_save_refresh_token(
  p_user_id    UUID,
  p_token_hash TEXT,
  p_expires_at TIMESTAMPTZ
) RETURNS JSONB LANGUAGE plpgsql AS $$
DECLARE v_id UUID;
BEGIN
  UPDATE wedding.refresh_tokens SET revoked_at = NOW()
  WHERE user_id = p_user_id AND revoked_at IS NULL;

  INSERT INTO wedding.refresh_tokens(user_id, token_hash, expires_at)
  VALUES (p_user_id, p_token_hash, p_expires_at)
  RETURNING id INTO v_id;

  RETURN jsonb_build_object('token_id', v_id);
END; $$;

CREATE OR REPLACE FUNCTION wedding.sp_auth_validate_refresh_token(p_token_hash TEXT)
RETURNS JSONB LANGUAGE plpgsql AS $$
DECLARE v_result JSONB;
BEGIN
  SELECT row_to_json(r) INTO v_result FROM (
    SELECT rt.user_id, rt.expires_at,
           u.email, u.full_name, u.is_active,
           ro.name AS role_name,
           COALESCE(json_agg(p.name) FILTER (WHERE p.name IS NOT NULL), '[]') AS permissions
    FROM wedding.refresh_tokens rt
    JOIN wedding.users u ON u.id = rt.user_id
    LEFT JOIN wedding.roles ro ON ro.id = u.role_id
    LEFT JOIN wedding.role_permissions rp ON rp.role_id = ro.id
    LEFT JOIN wedding.permissions p ON p.id = rp.permission_id
    WHERE rt.token_hash = p_token_hash
      AND rt.revoked_at IS NULL
      AND rt.expires_at > NOW()
      AND u.deleted_at IS NULL
    GROUP BY rt.user_id, rt.expires_at, u.email, u.full_name, u.is_active, ro.name
  ) r;

  IF v_result IS NULL THEN
    RAISE EXCEPTION 'INVALID_REFRESH_TOKEN: Token is invalid or expired';
  END IF;
  RETURN v_result;
END; $$;

CREATE OR REPLACE FUNCTION wedding.sp_auth_revoke_refresh_token(p_user_id UUID)
RETURNS JSONB LANGUAGE plpgsql AS $$
BEGIN
  UPDATE wedding.refresh_tokens SET revoked_at = NOW()
  WHERE user_id = p_user_id AND revoked_at IS NULL;
  RETURN jsonb_build_object('logged_out', TRUE);
END; $$;

CREATE OR REPLACE FUNCTION wedding.sp_auth_save_otp(
  p_email TEXT, p_code_hash TEXT, p_type TEXT
) RETURNS JSONB LANGUAGE plpgsql AS $$
BEGIN
  UPDATE wedding.otp_codes SET used_at = NOW()
  WHERE email = p_email AND type = p_type AND used_at IS NULL;

  INSERT INTO wedding.otp_codes(email, code_hash, type, expires_at)
  VALUES (p_email, p_code_hash, p_type, NOW() + INTERVAL '10 minutes');

  RETURN jsonb_build_object('otp_sent', TRUE, 'expires_in', '10 minutes');
END; $$;

-- Verify OTP. NOTE: OTP is hashed with bcrypt (random salt), so we cannot match
-- by code_hash equality. We fetch the latest valid OTP and return its hash for
-- the service layer to bcrypt.compare(). On success the service calls
-- sp_auth_consume_otp to mark it used.
CREATE OR REPLACE FUNCTION wedding.sp_auth_get_active_otp(
  p_email TEXT, p_type TEXT
) RETURNS JSONB LANGUAGE plpgsql AS $$
DECLARE v_result JSONB;
BEGIN
  SELECT row_to_json(r) INTO v_result FROM (
    SELECT id, code_hash
    FROM wedding.otp_codes
    WHERE email = p_email AND type = p_type
      AND used_at IS NULL AND expires_at > NOW()
    ORDER BY created_at DESC
    LIMIT 1
  ) r;
  IF v_result IS NULL THEN
    RAISE EXCEPTION 'INVALID_OTP: OTP is invalid or has expired';
  END IF;
  RETURN v_result;
END; $$;

CREATE OR REPLACE FUNCTION wedding.sp_auth_consume_otp(
  p_otp_id UUID, p_email TEXT, p_type TEXT
) RETURNS JSONB LANGUAGE plpgsql AS $$
BEGIN
  UPDATE wedding.otp_codes SET used_at = NOW() WHERE id = p_otp_id AND used_at IS NULL;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'INVALID_OTP: OTP is invalid or has expired';
  END IF;

  IF p_type = 'VERIFY_EMAIL' THEN
    UPDATE wedding.users SET is_email_verified = TRUE, updated_at = NOW()
    WHERE email = p_email;
  END IF;

  RETURN jsonb_build_object('verified', TRUE);
END; $$;

CREATE OR REPLACE FUNCTION wedding.sp_auth_update_last_login(p_user_id UUID)
RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
  UPDATE wedding.users SET last_login_at = NOW() WHERE id = p_user_id;
END; $$;

CREATE OR REPLACE FUNCTION wedding.sp_auth_reset_password(
  p_email TEXT, p_password_hash TEXT
) RETURNS JSONB LANGUAGE plpgsql AS $$
DECLARE v_user_id UUID;
BEGIN
  UPDATE wedding.users SET password_hash = p_password_hash, updated_at = NOW()
  WHERE email = p_email AND deleted_at IS NULL
  RETURNING id INTO v_user_id;

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'USER_NOT_FOUND: No user found with email %', p_email;
  END IF;

  UPDATE wedding.refresh_tokens SET revoked_at = NOW()
  WHERE user_id = v_user_id AND revoked_at IS NULL;

  RETURN jsonb_build_object('password_reset', TRUE);
END; $$;

-- ----- ADMIN -----
CREATE OR REPLACE FUNCTION wedding.sp_admin_get_users(
  p_role_name TEXT DEFAULT NULL,
  p_is_active BOOLEAN DEFAULT NULL
) RETURNS JSONB LANGUAGE plpgsql AS $$
DECLARE v_result JSONB;
BEGIN
  SELECT json_agg(row_to_json(r)) INTO v_result FROM (
    SELECT u.id, u.full_name, u.email, u.is_active,
           u.is_email_verified, u.last_login_at, u.created_at,
           r.name AS role_name, r.id AS role_id
    FROM wedding.users u
    LEFT JOIN wedding.roles r ON r.id = u.role_id
    WHERE u.deleted_at IS NULL
      AND (p_role_name IS NULL OR r.name = p_role_name)
      AND (p_is_active IS NULL OR u.is_active = p_is_active)
    ORDER BY u.created_at DESC
  ) r;
  RETURN COALESCE(v_result, '[]'::JSONB);
END; $$;

CREATE OR REPLACE FUNCTION wedding.sp_admin_assign_role(p_user_id UUID, p_role_id UUID)
RETURNS JSONB LANGUAGE plpgsql AS $$
BEGIN
  UPDATE wedding.users SET role_id = p_role_id, updated_at = NOW()
  WHERE id = p_user_id AND deleted_at IS NULL;
  IF NOT FOUND THEN RAISE EXCEPTION 'USER_NOT_FOUND'; END IF;
  RETURN jsonb_build_object('role_assigned', TRUE, 'user_id', p_user_id);
END; $$;

CREATE OR REPLACE FUNCTION wedding.sp_admin_toggle_user_status(p_user_id UUID)
RETURNS JSONB LANGUAGE plpgsql AS $$
DECLARE v_new_status BOOLEAN;
BEGIN
  UPDATE wedding.users SET is_active = NOT is_active, updated_at = NOW()
  WHERE id = p_user_id AND deleted_at IS NULL
  RETURNING is_active INTO v_new_status;
  IF NOT FOUND THEN RAISE EXCEPTION 'USER_NOT_FOUND'; END IF;
  RETURN jsonb_build_object('is_active', v_new_status, 'user_id', p_user_id);
END; $$;

CREATE OR REPLACE FUNCTION wedding.sp_admin_get_roles()
RETURNS JSONB LANGUAGE plpgsql AS $$
DECLARE v_result JSONB;
BEGIN
  SELECT json_agg(row_to_json(r)) INTO v_result FROM (
    SELECT ro.id, ro.name, ro.description,
           COALESCE(json_agg(p.name) FILTER (WHERE p.name IS NOT NULL), '[]') AS permissions
    FROM wedding.roles ro
    LEFT JOIN wedding.role_permissions rp ON rp.role_id = ro.id
    LEFT JOIN wedding.permissions p ON p.id = rp.permission_id
    GROUP BY ro.id, ro.name, ro.description
    ORDER BY ro.name
  ) r;
  RETURN COALESCE(v_result, '[]'::JSONB);
END; $$;
