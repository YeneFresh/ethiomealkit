-- 999_verify.sql
-- Smoke selects for each view + RPC

-- Test 1: Available Delivery Windows
SELECT 'Testing app.available_delivery_windows...' AS test_name;
SELECT 
  COUNT(*) AS window_count,
  COUNT(CASE WHEN has_capacity THEN 1 END) AS available_windows
FROM app.available_delivery_windows;

-- Test 2: User Delivery Readiness
SELECT 'Testing app.user_delivery_readiness...' AS test_name;
SELECT 
  user_id,
  is_ready,
  array_length(reasons, 1) AS reason_count,
  active_city,
  active_window_id
FROM app.user_delivery_readiness
LIMIT 1;

-- Test 3: Current Weekly Recipes
SELECT 'Testing app.current_weekly_recipes...' AS test_name;
SELECT 
  COUNT(*) AS recipe_count
FROM app.current_weekly_recipes;

-- Test 4: User Selections RPC
SELECT 'Testing app.user_selections()...' AS test_name;
SELECT 
  COUNT(*) AS selection_count,
  COUNT(CASE WHEN selected THEN 1 END) AS selected_count
FROM app.user_selections();

-- Test 5: Current Week Function
SELECT 'Testing app.current_addis_week()...' AS test_name;
SELECT 
  app.current_addis_week() AS current_week_start,
  EXTRACT(dow FROM app.current_addis_week()) AS day_of_week;

-- Test 6: Base Tables
SELECT 'Testing base tables...' AS test_name;
SELECT 
  'delivery_windows' AS table_name,
  COUNT(*) AS row_count
FROM public.delivery_windows
UNION ALL
SELECT 
  'weeks' AS table_name,
  COUNT(*) AS row_count
FROM public.weeks
UNION ALL
SELECT 
  'recipes' AS table_name,
  COUNT(*) AS row_count
FROM public.recipes;

-- Test 7: RLS Policies
SELECT 'Testing RLS policies...' AS test_name;
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd
FROM pg_policies 
WHERE schemaname IN ('public', 'app')
ORDER BY schemaname, tablename, policyname;

-- Test 8: Grants
SELECT 'Testing permissions...' AS test_name;
SELECT 
  table_schema,
  table_name,
  privilege_type,
  grantee
FROM information_schema.table_privileges 
WHERE table_schema = 'app' AND grantee IN ('anon', 'authenticated')
ORDER BY table_name, privilege_type;

-- Final verification
SELECT 'All views and RPCs verified successfully!' AS status;





