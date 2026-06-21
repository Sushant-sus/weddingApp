-- 005 — Cost stored procedures (wedding.sp_cost_*)
CREATE OR REPLACE FUNCTION wedding.sp_cost_get_by_id(p_id UUID)
RETURNS JSONB LANGUAGE plpgsql AS $$
DECLARE v_result JSONB;
BEGIN
  SELECT row_to_json(r) INTO v_result FROM (
    SELECT id, category, item_name, estimated_cost, actual_cost, vendor,
           payment_status, notes, created_at, updated_at
    FROM wedding.cost_items WHERE id = p_id AND deleted_at IS NULL
  ) r;
  IF v_result IS NULL THEN
    RAISE EXCEPTION 'COST_ITEM_NOT_FOUND: Cost item with id % not found', p_id;
  END IF;
  RETURN v_result;
END; $$;

CREATE OR REPLACE FUNCTION wedding.sp_cost_get_all(p_category TEXT DEFAULT NULL)
RETURNS JSONB LANGUAGE plpgsql AS $$
DECLARE v_result JSONB;
BEGIN
  SELECT json_agg(row_to_json(r)) INTO v_result FROM (
    SELECT id, category, item_name, estimated_cost, actual_cost, vendor,
           payment_status, notes, created_at, updated_at
    FROM wedding.cost_items
    WHERE deleted_at IS NULL
      AND (p_category IS NULL OR category = p_category)
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
  p_notes          TEXT    DEFAULT NULL
) RETURNS JSONB LANGUAGE plpgsql AS $$
DECLARE v_id UUID;
BEGIN
  INSERT INTO wedding.cost_items(category, item_name, estimated_cost,
                                  actual_cost, vendor, payment_status, notes)
  VALUES (p_category, p_item_name, p_estimated_cost, p_actual_cost, p_vendor,
          COALESCE(p_payment_status::wedding.payment_status_enum, 'UNPAID'), p_notes)
  RETURNING id INTO v_id;
  RETURN wedding.sp_cost_get_by_id(v_id);
END; $$;

CREATE OR REPLACE FUNCTION wedding.sp_cost_update(
  p_id             UUID,
  p_category       TEXT    DEFAULT NULL,
  p_item_name      TEXT    DEFAULT NULL,
  p_estimated_cost NUMERIC DEFAULT NULL,
  p_actual_cost    NUMERIC DEFAULT NULL,
  p_vendor         TEXT    DEFAULT NULL,
  p_payment_status TEXT    DEFAULT NULL,
  p_notes          TEXT    DEFAULT NULL
) RETURNS JSONB LANGUAGE plpgsql AS $$
BEGIN
  UPDATE wedding.cost_items SET
    category       = COALESCE(p_category,        category),
    item_name      = COALESCE(p_item_name,       item_name),
    estimated_cost = COALESCE(p_estimated_cost,  estimated_cost),
    actual_cost    = COALESCE(p_actual_cost,     actual_cost),
    vendor         = COALESCE(p_vendor,          vendor),
    payment_status = COALESCE(p_payment_status::wedding.payment_status_enum, payment_status),
    notes          = COALESCE(p_notes,           notes),
    updated_at     = NOW()
  WHERE id = p_id AND deleted_at IS NULL;
  IF NOT FOUND THEN RAISE EXCEPTION 'COST_ITEM_NOT_FOUND: Cost item with id % not found', p_id; END IF;
  RETURN wedding.sp_cost_get_by_id(p_id);
END; $$;

CREATE OR REPLACE FUNCTION wedding.sp_cost_get_summary()
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
        (SELECT json_agg(cat_summary)
         FROM (
           SELECT category,
                  SUM(estimated_cost)           AS estimated,
                  SUM(COALESCE(actual_cost, 0)) AS actual,
                  COUNT(*)                      AS items
           FROM wedding.cost_items WHERE deleted_at IS NULL
           GROUP BY category ORDER BY category
         ) cat_summary),
        '[]'::json
      ) AS by_category
    FROM wedding.cost_items WHERE deleted_at IS NULL
  ) r;
  RETURN v_result;
END; $$;

CREATE OR REPLACE FUNCTION wedding.sp_cost_delete(p_id UUID)
RETURNS JSONB LANGUAGE plpgsql AS $$
BEGIN
  UPDATE wedding.cost_items SET deleted_at = NOW()
  WHERE id = p_id AND deleted_at IS NULL;
  IF NOT FOUND THEN RAISE EXCEPTION 'COST_ITEM_NOT_FOUND: Cost item with id % not found', p_id; END IF;
  RETURN jsonb_build_object('deleted', TRUE, 'id', p_id);
END; $$;
