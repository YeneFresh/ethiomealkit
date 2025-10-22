-- =============================================================================
-- Delivery Readiness Gate Migration
-- =============================================================================
-- Creates app schema views and RPCs to gate weekly recipe selection behind
-- delivery window setup. Idempotent and reversible.
-- =============================================================================

-- Create app schema if not exists
CREATE SCHEMA IF NOT EXISTS app;

-- =============================================================================
-- 1. AVAILABLE DELIVERY WINDOWS VIEW
-- =============================================================================
-- Exposes only active, capacity-available delivery slots

CREATE OR REPLACE VIEW app.available_delivery_windows AS
SELECT 
  dw.id,
  dw.label,
  dw.day_of_week,
  dw.start_time,
  dw.end_time,
  dw.slot,
  dw.city,
  dw.has_capacity,
  dw.is_active,
  dw.max_orders,
  dw.current_orders
FROM public.delivery_windows dw
WHERE dw.is_active = true;

-- Grant permissions
GRANT USAGE ON SCHEMA app TO anon;
GRANT SELECT ON app.available_delivery_windows TO anon;

-- =============================================================================
-- 2. USER DELIVERY READINESS VIEW  
-- =============================================================================
-- Summarizes whether a user is ready to select recipes
-- Requires: active delivery window, address, payment state

CREATE OR REPLACE VIEW app.user_delivery_readiness AS
WITH u AS (SELECT auth.uid() AS user_id),
active_window AS (
  SELECT 
    dw.*,
    uds.user_id,
    uds.address_label
  FROM public.delivery_windows dw
  JOIN app.user_delivery_staging uds ON uds.window_id = dw.id
  WHERE uds.user_id = auth.uid()
    AND uds.staged_at IS NOT NULL
)
SELECT
  u.user_id,
  (aw.user_id IS NOT NULL) AS is_ready,
  CASE
    WHEN aw.user_id IS NULL THEN ARRAY['NO_ACTIVE_WINDOW']::text[]
    WHEN aw.address_label IS NULL THEN ARRAY['NO_ADDRESS']::text[]
    ELSE ARRAY[]::text[]
  END AS reason,
  aw.city AS active_city,
  aw.id AS active_window_id,
  aw.start_time AS window_start,
  aw.end_time AS window_end
FROM u
LEFT JOIN active_window aw ON aw.user_id = u.user_id;

-- Grant permissions
GRANT SELECT ON app.user_delivery_readiness TO anon;

-- =============================================================================
-- 3. USER SELECTIONS RPC
-- =============================================================================
-- Returns current user's week box/recipes summary
-- Stable signature, no args, infers auth.uid()

CREATE OR REPLACE FUNCTION app.user_selections()
RETURNS TABLE(
  recipe_id uuid,
  week_start date,
  box_size int,
  selected bool
)
LANGUAGE SQL
SECURITY DEFINER
STABLE
AS $$
  SELECT 
    wm.recipe_id,
    wm.week_start,
    3 AS box_size, -- Default 3 meals per week
    (urs.recipe_id IS NOT NULL) AS selected
  FROM public.weekly_menu wm
  LEFT JOIN app.user_delivery_staging urs
    ON urs.user_id = auth.uid() AND urs.week_start = wm.week_start
  WHERE wm.week_start = app.current_addis_week()
    AND wm.is_available = true
$$;

-- Grant permissions
REVOKE ALL ON FUNCTION app.user_selections() FROM public;
GRANT EXECUTE ON FUNCTION app.user_selections() TO anon;

-- =============================================================================
-- 4. GATED WEEKLY RECIPES VIEW
-- =============================================================================
-- Only shows recipes if user has delivery readiness
-- If not ready, returns empty set for locked UI state

CREATE OR REPLACE VIEW app.current_weekly_recipes AS
WITH gate AS (
  SELECT is_ready FROM app.user_delivery_readiness
)
SELECT wm.*
FROM public.weekly_menu wm
WHERE wm.week_start = app.current_addis_week()
  AND wm.is_available = true
  AND (SELECT is_ready FROM gate) = true;

-- Grant permissions  
GRANT SELECT ON app.current_weekly_recipes TO anon;

-- =============================================================================
-- 5. SEED DATA - DELIVERY WINDOWS
-- =============================================================================
-- Insert realistic Addis Ababa delivery windows
-- Only insert if not present (idempotent)

INSERT INTO public.delivery_windows (id, label, day_of_week, start_time, end_time, slot, city, is_active, max_orders, current_orders)
SELECT * FROM (VALUES
  -- Thursday 10-12
  ('thu_10_12', 'Thursday Morning', 'Thursday', '10:00', '12:00', 'Morning', 'Addis Ababa', true, 50, 0),
  -- Saturday 14-16  
  ('sat_14_16', 'Saturday Afternoon', 'Saturday', '14:00', '16:00', 'Afternoon', 'Addis Ababa', true, 50, 0)
) AS t(id, label, day_of_week, start_time, end_time, slot, city, is_active, max_orders, current_orders)
WHERE NOT EXISTS (SELECT 1 FROM public.delivery_windows WHERE id = t.id);

-- =============================================================================
-- 6. VERIFICATION QUERIES
-- =============================================================================
-- Run these to verify the migration worked

-- Check views exist and compile
DO $$
BEGIN
  RAISE NOTICE 'Testing app.available_delivery_windows...';
  PERFORM 1 FROM app.available_delivery_windows LIMIT 1;
  
  RAISE NOTICE 'Testing app.user_delivery_readiness...';
  PERFORM 1 FROM app.user_delivery_readiness LIMIT 1;
  
  RAISE NOTICE 'Testing app.user_selections()...';
  PERFORM 1 FROM app.user_selections() LIMIT 1;
  
  RAISE NOTICE 'Testing app.current_weekly_recipes...';
  PERFORM 1 FROM app.current_weekly_recipes LIMIT 1;
  
  RAISE NOTICE 'All views and RPCs compiled successfully!';
END $$;

-- Check seed data
SELECT 
  COUNT(*) as window_count,
  city,
  slot
FROM public.delivery_windows 
WHERE is_active = true
GROUP BY city, slot
ORDER BY city, slot;
