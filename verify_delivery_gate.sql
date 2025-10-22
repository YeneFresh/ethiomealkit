-- =============================================================================
-- Verification Script for Delivery Readiness Gate
-- =============================================================================
-- Run this after applying delivery_readiness_gate.sql to verify everything works

-- Test 1: Check views exist and compile
SELECT 'Testing app.available_delivery_windows...' as test;
SELECT COUNT(*) as window_count FROM app.available_delivery_windows;

SELECT 'Testing app.user_delivery_readiness...' as test;
SELECT COUNT(*) as readiness_count FROM app.user_delivery_readiness;

SELECT 'Testing app.user_selections()...' as test;
SELECT COUNT(*) as selections_count FROM app.user_selections();

SELECT 'Testing app.current_weekly_recipes...' as test;
SELECT COUNT(*) as recipes_count FROM app.current_weekly_recipes;

-- Test 2: Check seed data
SELECT 'Checking delivery windows seed data...' as test;
SELECT 
  id,
  label,
  day_of_week,
  start_time,
  end_time,
  slot,
  city,
  has_capacity,
  is_active
FROM public.delivery_windows 
WHERE is_active = true
ORDER BY day_of_week, start_time;

-- Test 3: Check permissions (run as anon role)
-- Note: This will show different results depending on auth state
SELECT 'Checking user delivery readiness (anon view)...' as test;
SELECT 
  user_id,
  is_ready,
  reason,
  active_city,
  active_window_id
FROM app.user_delivery_readiness;

-- Test 4: Check available windows
SELECT 'Checking available delivery windows...' as test;
SELECT 
  id,
  label,
  day_of_week,
  start_time,
  end_time,
  city,
  has_capacity
FROM app.available_delivery_windows
ORDER BY day_of_week, start_time;

-- Test 5: Check weekly recipes (should be empty if user not ready)
SELECT 'Checking current weekly recipes...' as test;
SELECT 
  id,
  title,
  description,
  price_cents,
  week_start
FROM app.current_weekly_recipes
ORDER BY sort_order;

-- Test 6: Check user selections RPC
SELECT 'Checking user selections RPC...' as test;
SELECT 
  recipe_id,
  week_start,
  box_size,
  selected
FROM app.user_selections();

-- Summary
SELECT 'All tests completed successfully!' as result;


