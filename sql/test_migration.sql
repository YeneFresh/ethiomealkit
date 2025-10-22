-- Test Migration Script
-- Run this after the main migration to verify everything works

-- Test 1: Check all tables exist
SELECT 
  schemaname,
  tablename,
  'Table exists' as status
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename IN ('delivery_windows', 'user_active_window', 'user_onboarding_state', 'weeks', 'recipes', 'user_recipe_selections')
ORDER BY tablename;

-- Test 2: Check app schema exists
SELECT 
  schema_name,
  'Schema exists' as status
FROM information_schema.schemata 
WHERE schema_name = 'app';

-- Test 3: Check views exist
SELECT 
  table_schema,
  table_name,
  'View exists' as status
FROM information_schema.views 
WHERE table_schema = 'app'
ORDER BY table_name;

-- Test 4: Check functions exist
SELECT 
  routine_schema,
  routine_name,
  'Function exists' as status
FROM information_schema.routines 
WHERE routine_schema = 'app'
ORDER BY routine_name;

-- Test 5: Check RLS is enabled
SELECT 
  schemaname,
  tablename,
  rowsecurity as rls_enabled
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename IN ('delivery_windows', 'user_active_window', 'user_onboarding_state', 'weeks', 'recipes', 'user_recipe_selections')
ORDER BY tablename;

-- Test 6: Check policies exist
SELECT 
  schemaname,
  tablename,
  policyname,
  'Policy exists' as status
FROM pg_policies 
WHERE schemaname IN ('public', 'app')
ORDER BY schemaname, tablename, policyname;

-- Test 7: Check grants exist
SELECT 
  table_schema,
  table_name,
  privilege_type,
  grantee,
  'Grant exists' as status
FROM information_schema.table_privileges 
WHERE table_schema = 'app' AND grantee IN ('anon', 'authenticated')
ORDER BY table_name, privilege_type;

-- Test 8: Test data exists
SELECT 'Delivery windows' as table_name, COUNT(*) as count FROM public.delivery_windows
UNION ALL
SELECT 'Weeks' as table_name, COUNT(*) as count FROM public.weeks
UNION ALL
SELECT 'Recipes' as table_name, COUNT(*) as count FROM public.recipes;

-- Test 9: Test views return data
SELECT 'Available delivery windows' as view_name, COUNT(*) as count FROM app.available_delivery_windows
UNION ALL
SELECT 'User delivery readiness' as view_name, COUNT(*) as count FROM app.user_delivery_readiness
UNION ALL
SELECT 'Current weekly recipes' as view_name, COUNT(*) as count FROM app.current_weekly_recipes;

-- Test 10: Test functions work
SELECT 'User selections' as function_name, COUNT(*) as count FROM app.user_selections()
UNION ALL
SELECT 'Current week' as function_name, 1 as count WHERE app.current_addis_week() IS NOT NULL;

-- Final success message
SELECT 'Migration test completed successfully!' as status;





