-- 011 — Utsav marketplace stored procedures (wedding.sp_provider_*, sp_service_request_*,
-- sp_pitch_*). All return JSONB; errors raised as 'CODE: message' for the error handler.
-- Idempotent via CREATE OR REPLACE.

-- ============================ CATEGORIES ============================
CREATE OR REPLACE FUNCTION wedding.sp_category_list()
RETURNS JSONB LANGUAGE plpgsql AS $$
DECLARE v_result JSONB;
BEGIN
  SELECT json_agg(row_to_json(r) ORDER BY r.sort_order) INTO v_result FROM (
    SELECT c.id, c.slug, c.name, c.accent_hex, c.sort_order,
           (SELECT COUNT(*) FROM wedding.service_providers p
             WHERE p.deleted_at IS NULL AND p.is_active
               AND c.slug = ANY(p.categories))::INT AS provider_count
    FROM wedding.service_categories c
  ) r;
  RETURN COALESCE(v_result, '[]'::JSONB);
END; $$;

-- ============================ PROVIDERS ============================
CREATE OR REPLACE FUNCTION wedding.sp_provider_get_by_id(p_id UUID)
RETURNS JSONB LANGUAGE plpgsql AS $$
DECLARE v_result JSONB;
BEGIN
  SELECT row_to_json(r) INTO v_result FROM (
    SELECT p.id, p.user_id, p.name, p.bio, p.categories, p.base_price, p.city,
           p.distance_km, p.rating, p.review_count, p.is_verified, p.is_active,
           p.created_at, p.updated_at,
           COALESCE((SELECT json_agg(row_to_json(pf) ORDER BY pf.sort_order, pf.created_at)
                     FROM (SELECT id, image_url, caption, sort_order, created_at
                           FROM wedding.provider_portfolio WHERE provider_id = p.id) pf), '[]'::JSON) AS portfolio,
           COALESCE((SELECT json_agg(row_to_json(rv) ORDER BY rv.created_at DESC)
                     FROM (SELECT id, author_name, rating, body, created_at
                           FROM wedding.provider_reviews WHERE provider_id = p.id) rv), '[]'::JSON) AS reviews
    FROM wedding.service_providers p
    WHERE p.id = p_id AND p.deleted_at IS NULL
  ) r;
  IF v_result IS NULL THEN
    RAISE EXCEPTION 'PROVIDER_NOT_FOUND: Provider with id % not found', p_id;
  END IF;
  RETURN v_result;
END; $$;

CREATE OR REPLACE FUNCTION wedding.sp_provider_get_by_user(p_user_id UUID)
RETURNS JSONB LANGUAGE plpgsql AS $$
DECLARE v_id UUID;
BEGIN
  SELECT id INTO v_id FROM wedding.service_providers
  WHERE user_id = p_user_id AND deleted_at IS NULL;
  IF v_id IS NULL THEN RETURN NULL; END IF;
  RETURN wedding.sp_provider_get_by_id(v_id);
END; $$;

-- Browse / discovery list. Optional category slug + free-text search on name.
CREATE OR REPLACE FUNCTION wedding.sp_provider_list(
  p_category TEXT DEFAULT NULL,
  p_search   TEXT DEFAULT NULL
) RETURNS JSONB LANGUAGE plpgsql AS $$
DECLARE v_result JSONB;
BEGIN
  SELECT json_agg(row_to_json(r) ORDER BY r.rating DESC, r.review_count DESC) INTO v_result FROM (
    SELECT id, user_id, name, bio, categories, base_price, city, distance_km,
           rating, review_count, is_verified, created_at
    FROM wedding.service_providers
    WHERE deleted_at IS NULL AND is_active
      AND (p_category IS NULL OR p_category = ANY(categories))
      AND (p_search IS NULL OR name ILIKE '%' || p_search || '%')
  ) r;
  RETURN COALESCE(v_result, '[]'::JSONB);
END; $$;

-- Create or update the calling user's provider profile (one per user).
CREATE OR REPLACE FUNCTION wedding.sp_provider_upsert(
  p_user_id     UUID,
  p_name        TEXT,
  p_bio         TEXT DEFAULT NULL,
  p_categories  TEXT[] DEFAULT '{}',
  p_base_price  NUMERIC DEFAULT NULL,
  p_city        TEXT DEFAULT NULL,
  p_distance_km NUMERIC DEFAULT NULL
) RETURNS JSONB LANGUAGE plpgsql AS $$
DECLARE v_id UUID;
BEGIN
  SELECT id INTO v_id FROM wedding.service_providers
  WHERE user_id = p_user_id AND deleted_at IS NULL;

  IF v_id IS NULL THEN
    INSERT INTO wedding.service_providers (user_id, name, bio, categories, base_price, city, distance_km)
    VALUES (p_user_id, p_name, p_bio, COALESCE(p_categories, '{}'), p_base_price, p_city, p_distance_km)
    RETURNING id INTO v_id;
  ELSE
    UPDATE wedding.service_providers SET
      name        = COALESCE(p_name, name),
      bio         = COALESCE(p_bio, bio),
      categories  = COALESCE(p_categories, categories),
      base_price  = COALESCE(p_base_price, base_price),
      city        = COALESCE(p_city, city),
      distance_km = COALESCE(p_distance_km, distance_km),
      updated_at  = NOW()
    WHERE id = v_id;
  END IF;
  RETURN wedding.sp_provider_get_by_id(v_id);
END; $$;

CREATE OR REPLACE FUNCTION wedding.sp_provider_portfolio_add(
  p_provider_id UUID,
  p_image_url   TEXT,
  p_caption     TEXT DEFAULT NULL,
  p_sort_order  INT DEFAULT 0
) RETURNS JSONB LANGUAGE plpgsql AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM wedding.service_providers WHERE id = p_provider_id AND deleted_at IS NULL) THEN
    RAISE EXCEPTION 'PROVIDER_NOT_FOUND: Provider with id % not found', p_provider_id;
  END IF;
  INSERT INTO wedding.provider_portfolio (provider_id, image_url, caption, sort_order)
  VALUES (p_provider_id, p_image_url, p_caption, p_sort_order);
  RETURN wedding.sp_provider_get_by_id(p_provider_id);
END; $$;

-- Add a review and recompute the provider's denormalized rating + review_count.
CREATE OR REPLACE FUNCTION wedding.sp_provider_review_add(
  p_provider_id    UUID,
  p_author_user_id UUID,
  p_author_name    TEXT,
  p_rating         INT,
  p_body           TEXT DEFAULT NULL
) RETURNS JSONB LANGUAGE plpgsql AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM wedding.service_providers WHERE id = p_provider_id AND deleted_at IS NULL) THEN
    RAISE EXCEPTION 'PROVIDER_NOT_FOUND: Provider with id % not found', p_provider_id;
  END IF;
  INSERT INTO wedding.provider_reviews (provider_id, author_user_id, author_name, rating, body)
  VALUES (p_provider_id, p_author_user_id, p_author_name, p_rating, p_body);

  UPDATE wedding.service_providers SET
    rating = (SELECT ROUND(AVG(rating)::NUMERIC, 2) FROM wedding.provider_reviews WHERE provider_id = p_provider_id),
    review_count = (SELECT COUNT(*) FROM wedding.provider_reviews WHERE provider_id = p_provider_id),
    updated_at = NOW()
  WHERE id = p_provider_id;
  RETURN wedding.sp_provider_get_by_id(p_provider_id);
END; $$;

-- ============================ SERVICE REQUESTS ============================
CREATE OR REPLACE FUNCTION wedding.sp_service_request_get_by_id(p_id UUID)
RETURNS JSONB LANGUAGE plpgsql AS $$
DECLARE v_result JSONB;
BEGIN
  SELECT row_to_json(r) INTO v_result FROM (
    SELECT sr.id, sr.event_id, sr.itinerary_item_id, sr.category, sr.title,
           sr.budget_min, sr.budget_max, sr.audience, sr.status, sr.accepted_pitch_id,
           sr.created_by, sr.created_at, sr.updated_at,
           (SELECT COUNT(*) FROM wedding.service_pitches sp
             WHERE sp.request_id = sr.id AND sp.deleted_at IS NULL)::INT AS pitch_count,
           it.title AS item_title, ev.name AS event_name, ev.wedding_date AS event_date
    FROM wedding.service_requests sr
    LEFT JOIN wedding.itinerary_events it ON it.id = sr.itinerary_item_id
    LEFT JOIN wedding.wedding_events ev ON ev.id = sr.event_id
    WHERE sr.id = p_id AND sr.deleted_at IS NULL
  ) r;
  IF v_result IS NULL THEN
    RAISE EXCEPTION 'REQUEST_NOT_FOUND: Service request with id % not found', p_id;
  END IF;
  RETURN v_result;
END; $$;

CREATE OR REPLACE FUNCTION wedding.sp_service_request_create(
  p_event_id          UUID,
  p_category          TEXT,
  p_title             TEXT,
  p_created_by        UUID,
  p_itinerary_item_id UUID DEFAULT NULL,
  p_budget_min        NUMERIC DEFAULT NULL,
  p_budget_max        NUMERIC DEFAULT NULL,
  p_audience          TEXT DEFAULT 'BROADCAST',
  p_target_provider_ids UUID[] DEFAULT NULL
) RETURNS JSONB LANGUAGE plpgsql AS $$
DECLARE v_id UUID; v_pid UUID;
BEGIN
  INSERT INTO wedding.service_requests
    (event_id, itinerary_item_id, category, title, budget_min, budget_max, audience, created_by)
  VALUES
    (p_event_id, p_itinerary_item_id, p_category, p_title, p_budget_min, p_budget_max,
     p_audience::wedding.service_audience_enum, p_created_by)
  RETURNING id INTO v_id;

  IF p_audience = 'TARGETED' AND p_target_provider_ids IS NOT NULL THEN
    FOREACH v_pid IN ARRAY p_target_provider_ids LOOP
      INSERT INTO wedding.service_request_targets (request_id, provider_id)
      VALUES (v_id, v_pid) ON CONFLICT DO NOTHING;
    END LOOP;
  END IF;
  RETURN wedding.sp_service_request_get_by_id(v_id);
END; $$;

-- All requests for an event (host view), newest first, with pitch counts.
CREATE OR REPLACE FUNCTION wedding.sp_service_request_list_for_event(p_event_id UUID)
RETURNS JSONB LANGUAGE plpgsql AS $$
DECLARE v_result JSONB;
BEGIN
  SELECT json_agg(row_to_json(r) ORDER BY r.created_at DESC) INTO v_result FROM (
    SELECT sr.id, sr.event_id, sr.itinerary_item_id, sr.category, sr.title,
           sr.budget_min, sr.budget_max, sr.audience, sr.status, sr.created_at,
           (SELECT COUNT(*) FROM wedding.service_pitches sp
             WHERE sp.request_id = sr.id AND sp.deleted_at IS NULL)::INT AS pitch_count
    FROM wedding.service_requests sr
    WHERE sr.event_id = p_event_id AND sr.deleted_at IS NULL
  ) r;
  RETURN COALESCE(v_result, '[]'::JSONB);
END; $$;

-- Itinerary items for an event joined with their active service request (the "service pill").
-- NEW procedure — does not alter sp_itinerary_get_all.
CREATE OR REPLACE FUNCTION wedding.sp_itinerary_with_services(p_event_id UUID)
RETURNS JSONB LANGUAGE plpgsql AS $$
DECLARE v_result JSONB;
BEGIN
  SELECT json_agg(row_to_json(r) ORDER BY r.order_index ASC, r.created_at ASC) INTO v_result FROM (
    SELECT it.id, it.title, it.description, it.event_date, it.start_time, it.end_time,
           it.location, it.responsible, it.category, it.order_index, it.created_at, it.updated_at,
           (SELECT row_to_json(s) FROM (
              SELECT sr.id, sr.title, sr.category AS service_category, sr.status,
                     (SELECT COUNT(*) FROM wedding.service_pitches sp
                       WHERE sp.request_id = sr.id AND sp.deleted_at IS NULL)::INT AS pitch_count
              FROM wedding.service_requests sr
              WHERE sr.itinerary_item_id = it.id AND sr.deleted_at IS NULL
                AND sr.status <> 'CANCELLED'
              ORDER BY sr.created_at DESC LIMIT 1
           ) s) AS service
    FROM wedding.itinerary_events it
    WHERE it.deleted_at IS NULL
      AND (p_event_id IS NULL OR it.event_id = p_event_id)
  ) r;
  RETURN COALESCE(v_result, '[]'::JSONB);
END; $$;

CREATE OR REPLACE FUNCTION wedding.sp_service_request_cancel(p_id UUID)
RETURNS JSONB LANGUAGE plpgsql AS $$
BEGIN
  UPDATE wedding.service_requests
  SET status = 'CANCELLED', updated_at = NOW()
  WHERE id = p_id AND deleted_at IS NULL;
  IF NOT FOUND THEN RAISE EXCEPTION 'REQUEST_NOT_FOUND: Service request with id % not found', p_id; END IF;
  RETURN wedding.sp_service_request_get_by_id(p_id);
END; $$;

-- The event role of a user relative to a request's event (NULL if not a member).
-- Used by the API to authorize host-side actions on a request.
CREATE OR REPLACE FUNCTION wedding.sp_request_event_role(p_request_id UUID, p_user_id UUID)
RETURNS TEXT LANGUAGE plpgsql AS $$
DECLARE v_role TEXT;
BEGIN
  SELECT em.event_role INTO v_role
  FROM wedding.service_requests sr
  JOIN wedding.event_members em ON em.event_id = sr.event_id
  WHERE sr.id = p_request_id AND em.user_id = p_user_id
    AND em.invite_status = 'ACCEPTED' AND sr.deleted_at IS NULL;
  RETURN v_role;  -- NULL when not a member
END; $$;

-- The event role of a user relative to a pitch's event (NULL if not a member).
CREATE OR REPLACE FUNCTION wedding.sp_pitch_event_role(p_pitch_id UUID, p_user_id UUID)
RETURNS TEXT LANGUAGE plpgsql AS $$
DECLARE v_role TEXT;
BEGIN
  SELECT em.event_role INTO v_role
  FROM wedding.service_pitches sp
  JOIN wedding.service_requests sr ON sr.id = sp.request_id
  JOIN wedding.event_members em ON em.event_id = sr.event_id
  WHERE sp.id = p_pitch_id AND em.user_id = p_user_id
    AND em.invite_status = 'ACCEPTED' AND sp.deleted_at IS NULL;
  RETURN v_role;  -- NULL when not a member
END; $$;

-- ============================ PITCHES ============================
-- Pitch list for a request, joined with provider info, "best match" first
-- (rating desc, then lowest price). The top row is the recommended pitch.
CREATE OR REPLACE FUNCTION wedding.sp_pitch_list_for_request(p_request_id UUID)
RETURNS JSONB LANGUAGE plpgsql AS $$
DECLARE v_result JSONB;
BEGIN
  SELECT json_agg(row_to_json(r) ORDER BY r.provider_rating DESC, r.price ASC) INTO v_result FROM (
    SELECT sp.id, sp.request_id, sp.provider_id, sp.price, sp.message,
           sp.available_on_date, sp.status, sp.created_at,
           p.name AS provider_name, p.rating AS provider_rating,
           p.review_count AS provider_review_count, p.distance_km AS provider_distance_km,
           p.is_verified AS provider_verified
    FROM wedding.service_pitches sp
    JOIN wedding.service_providers p ON p.id = sp.provider_id
    WHERE sp.request_id = p_request_id AND sp.deleted_at IS NULL
  ) r;
  RETURN COALESCE(v_result, '[]'::JSONB);
END; $$;

CREATE OR REPLACE FUNCTION wedding.sp_pitch_create(
  p_request_id        UUID,
  p_provider_id       UUID,
  p_price             NUMERIC,
  p_message           TEXT DEFAULT NULL,
  p_available_on_date BOOLEAN DEFAULT TRUE
) RETURNS JSONB LANGUAGE plpgsql AS $$
DECLARE v_status wedding.service_request_status_enum; v_id UUID;
BEGIN
  SELECT status INTO v_status FROM wedding.service_requests
  WHERE id = p_request_id AND deleted_at IS NULL;
  IF v_status IS NULL THEN
    RAISE EXCEPTION 'REQUEST_NOT_FOUND: Service request with id % not found', p_request_id;
  END IF;
  IF v_status <> 'LIVE' THEN
    RAISE EXCEPTION 'REQUEST_NOT_LIVE: This request is no longer accepting pitches';
  END IF;
  IF EXISTS (SELECT 1 FROM wedding.service_pitches
             WHERE request_id = p_request_id AND provider_id = p_provider_id AND deleted_at IS NULL) THEN
    RAISE EXCEPTION 'ALREADY_PITCHED: You have already pitched for this request';
  END IF;

  INSERT INTO wedding.service_pitches (request_id, provider_id, price, message, available_on_date)
  VALUES (p_request_id, p_provider_id, p_price, p_message, p_available_on_date)
  RETURNING id INTO v_id;
  RETURN (SELECT row_to_json(r) FROM (
    SELECT id, request_id, provider_id, price, message, available_on_date, status, created_at
    FROM wedding.service_pitches WHERE id = v_id
  ) r);
END; $$;

CREATE OR REPLACE FUNCTION wedding.sp_pitch_decline(p_id UUID)
RETURNS JSONB LANGUAGE plpgsql AS $$
BEGIN
  UPDATE wedding.service_pitches SET status = 'DECLINED', updated_at = NOW()
  WHERE id = p_id AND deleted_at IS NULL;
  IF NOT FOUND THEN RAISE EXCEPTION 'PITCH_NOT_FOUND: Pitch with id % not found', p_id; END IF;
  RETURN jsonb_build_object('id', p_id, 'status', 'DECLINED');
END; $$;

-- Book a pitch: mark it ACCEPTED, decline all siblings, flip the request to BOOKED.
-- Runs in a single statement batch (implicit transaction inside the function).
CREATE OR REPLACE FUNCTION wedding.sp_pitch_book(p_id UUID)
RETURNS JSONB LANGUAGE plpgsql AS $$
DECLARE v_request_id UUID;
BEGIN
  SELECT request_id INTO v_request_id FROM wedding.service_pitches
  WHERE id = p_id AND deleted_at IS NULL;
  IF v_request_id IS NULL THEN
    RAISE EXCEPTION 'PITCH_NOT_FOUND: Pitch with id % not found', p_id;
  END IF;

  UPDATE wedding.service_pitches SET status = 'ACCEPTED', updated_at = NOW() WHERE id = p_id;
  UPDATE wedding.service_pitches SET status = 'DECLINED', updated_at = NOW()
  WHERE request_id = v_request_id AND id <> p_id AND deleted_at IS NULL;
  UPDATE wedding.service_requests
  SET status = 'BOOKED', accepted_pitch_id = p_id, updated_at = NOW()
  WHERE id = v_request_id;

  RETURN wedding.sp_service_request_get_by_id(v_request_id);
END; $$;

-- Provider dashboard feed: LIVE requests matching the provider's categories
-- (broadcast to all, or targeted to this provider), excluding ones already pitched.
CREATE OR REPLACE FUNCTION wedding.sp_provider_dashboard_feed(p_provider_id UUID)
RETURNS JSONB LANGUAGE plpgsql AS $$
DECLARE v_result JSONB; v_categories TEXT[];
BEGIN
  SELECT categories INTO v_categories FROM wedding.service_providers
  WHERE id = p_provider_id AND deleted_at IS NULL;
  IF v_categories IS NULL THEN
    RAISE EXCEPTION 'PROVIDER_NOT_FOUND: Provider with id % not found', p_provider_id;
  END IF;

  SELECT json_agg(row_to_json(r) ORDER BY r.created_at DESC) INTO v_result FROM (
    SELECT sr.id, sr.category, sr.title, sr.budget_min, sr.budget_max, sr.audience,
           sr.created_at, ev.name AS event_name, ev.wedding_date AS event_date,
           it.event_date AS item_date,
           (SELECT COUNT(*) FROM wedding.service_pitches sp
             WHERE sp.request_id = sr.id AND sp.deleted_at IS NULL)::INT AS pitch_count
    FROM wedding.service_requests sr
    JOIN wedding.wedding_events ev ON ev.id = sr.event_id AND ev.deleted_at IS NULL
    LEFT JOIN wedding.itinerary_events it ON it.id = sr.itinerary_item_id
    WHERE sr.deleted_at IS NULL AND sr.status = 'LIVE'
      AND sr.category = ANY(v_categories)
      AND (sr.audience = 'BROADCAST'
           OR EXISTS (SELECT 1 FROM wedding.service_request_targets t
                      WHERE t.request_id = sr.id AND t.provider_id = p_provider_id))
      AND NOT EXISTS (SELECT 1 FROM wedding.service_pitches sp
                      WHERE sp.request_id = sr.id AND sp.provider_id = p_provider_id AND sp.deleted_at IS NULL)
  ) r;
  RETURN COALESCE(v_result, '[]'::JSONB);
END; $$;
