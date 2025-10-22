-- 010_views.sql
-- Create/replace all app.* views

-- Create app schema if not exists
CREATE SCHEMA IF NOT EXISTS app;

-- 1. Available Delivery Windows View
CREATE OR REPLACE VIEW app.available_delivery_windows AS
SELECT
  dw.id,
  dw.start_at,
  dw.end_at,
  dw.weekday,
  dw.slot,
  dw.city,
  dw.capacity,
  dw.booked_count,
  (dw.capacity - dw.booked_count > 0) AS has_capacity,
  dw.is_active,
  dw.created_at
FROM public.delivery_windows dw
WHERE dw.is_active = true
ORDER BY dw.start_at;

-- 2. User Delivery Readiness View
CREATE OR REPLACE VIEW app.user_delivery_readiness AS
WITH current_user AS (
  SELECT auth.uid() AS user_id
),
user_window AS (
  SELECT 
    uaw.user_id,
    uaw.window_id,
    uaw.location_label,
    dw.start_at,
    dw.end_at,
    dw.weekday,
    dw.slot,
    dw.city
  FROM current_user cu
  LEFT JOIN public.user_active_window uaw ON uaw.user_id = cu.user_id
  LEFT JOIN public.delivery_windows dw ON dw.id = uaw.window_id
)
SELECT
  uw.user_id,
  (uw.user_id IS NOT NULL) AS is_ready,
  CASE 
    WHEN uw.user_id IS NULL THEN ARRAY['NO_ACTIVE_WINDOW']::text[]
    ELSE ARRAY[]::text[]
  END AS reasons,
  uw.location_label AS active_city,
  uw.window_id AS active_window_id,
  uw.start_at AS window_start,
  uw.end_at AS window_end,
  uw.weekday,
  uw.slot
FROM user_window uw;

-- 3. Current Weekly Recipes View (Gated by Readiness)
CREATE OR REPLACE VIEW app.current_weekly_recipes AS
WITH gate_check AS (
  SELECT is_ready FROM app.user_delivery_readiness
),
current_week AS (
  SELECT id, week_start FROM public.weeks WHERE is_current = true LIMIT 1
)
SELECT 
  r.id,
  r.title,
  r.slug,
  r.image_url,
  r.tags,
  r.sort_order,
  cw.week_start
FROM current_week cw
JOIN public.recipes r ON r.week_id = cw.id AND r.is_active = true
CROSS JOIN gate_check gc
WHERE gc.is_ready = true
ORDER BY r.sort_order, r.title;

-- Grant permissions
GRANT USAGE ON SCHEMA app TO anon, authenticated;
GRANT SELECT ON app.available_delivery_windows TO anon, authenticated;
GRANT SELECT ON app.user_delivery_readiness TO anon, authenticated;
GRANT SELECT ON app.current_weekly_recipes TO anon, authenticated;






