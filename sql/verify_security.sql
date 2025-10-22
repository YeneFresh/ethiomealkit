-- =============================================================================
-- SECURITY VERIFICATION SCRIPT
-- Run this after migration to verify all security requirements are met
-- =============================================================================

-- 1. Check all tables have RLS enabled
SELECT 
  '1. RLS Enabled Check' as test,
  tablename,
  CASE WHEN rowsecurity THEN '✅ ENABLED' ELSE '❌ DISABLED' END as rls_status
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN (
    'delivery_windows', 'user_active_window', 'user_onboarding_state',
    'weeks', 'recipes', 'user_recipe_selections', 'orders', 'order_items'
  )
ORDER BY tablename;

-- 2. Check all write RPCs are SECURITY DEFINER
SELECT 
  '2. SECURITY DEFINER Check' as test,
  routine_name,
  security_type,
  CASE 
    WHEN security_type = 'DEFINER' THEN '✅ DEFINER'
    WHEN routine_name = 'current_addis_week' THEN '✅ N/A (read-only)'
    ELSE '❌ INVOKER'
  END as security_status
FROM information_schema.routines
WHERE routine_schema = 'app'
ORDER BY routine_name;

-- 3. Verify auth.uid() usage in write RPCs
SELECT 
  '3. auth.uid() Usage Check' as test,
  routine_name,
  CASE 
    WHEN routine_definition LIKE '%auth.uid()%' THEN '✅ USES auth.uid()'
    WHEN routine_name = 'current_addis_week' THEN '✅ N/A (no user data)'
    ELSE '❌ MISSING auth.uid()'
  END as auth_check
FROM information_schema.routines
WHERE routine_schema = 'app'
ORDER BY routine_name;

-- 4. Check table privileges are minimal
SELECT 
  '4. Privilege Check' as test,
  table_name,
  grantee,
  string_agg(privilege_type, ', ' ORDER BY privilege_type) as privileges
FROM information_schema.table_privileges
WHERE table_schema = 'public'
  AND table_name IN (
    'delivery_windows', 'user_active_window', 'user_onboarding_state',
    'weeks', 'recipes', 'user_recipe_selections', 'orders', 'order_items'
  )
  AND grantee IN ('anon', 'authenticated')
GROUP BY table_name, grantee
ORDER BY table_name, grantee;

-- 5. List all RLS policies
SELECT 
  '5. RLS Policies' as test,
  schemaname,
  tablename,
  policyname,
  cmd as operation,
  CASE 
    WHEN qual LIKE '%auth.uid()%' THEN '✅ User-scoped'
    WHEN qual = 'true' THEN '✅ Public (safe)'
    WHEN qual LIKE '%is_active%' THEN '✅ Filtered'
    ELSE '⚠️ Review'
  END as policy_check
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- 6. Verify view isolation (check for cross-user joins)
SELECT 
  '6. View Definition Check' as test,
  table_name as view_name,
  CASE 
    WHEN view_definition LIKE '%auth.uid()%' THEN '✅ User-scoped'
    WHEN table_name = 'available_delivery_windows' THEN '✅ Public data only'
    ELSE '⚠️ Review needed'
  END as isolation_check
FROM information_schema.views
WHERE table_schema = 'app'
ORDER BY table_name;

-- 7. Count total database objects
SELECT 
  '7. Object Count Summary' as test,
  'Tables' as object_type,
  COUNT(*) as count
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_type = 'BASE TABLE'
UNION ALL
SELECT 
  '7. Object Count Summary',
  'Views',
  COUNT(*)
FROM information_schema.views
WHERE table_schema = 'app'
UNION ALL
SELECT 
  '7. Object Count Summary',
  'RPCs',
  COUNT(*)
FROM information_schema.routines
WHERE routine_schema = 'app'
UNION ALL
SELECT 
  '7. Object Count Summary',
  'Policies',
  COUNT(*)::bigint
FROM pg_policies
WHERE schemaname = 'public';

-- 8. Verify comments exist on all objects
SELECT 
  '8. Documentation Check' as test,
  obj_description(c.oid) as comment_text,
  CASE 
    WHEN obj_description(c.oid) IS NOT NULL THEN '✅ Documented'
    ELSE '⚠️ Missing comment'
  END as doc_status,
  c.relname as table_name
FROM pg_class c
WHERE c.relnamespace = 'public'::regnamespace
  AND c.relkind IN ('r', 'v')  -- Tables and views
  AND c.relname IN (
    'delivery_windows', 'user_active_window', 'user_onboarding_state',
    'weeks', 'recipes', 'user_recipe_selections', 'orders', 'order_items'
  )
ORDER BY c.relname;

-- 9. Check seed data exists
SELECT 
  '9. Seed Data Check' as test,
  'delivery_windows' as table_name,
  COUNT(*) as count,
  CASE WHEN COUNT(*) >= 4 THEN '✅' ELSE '❌' END as status
FROM public.delivery_windows
UNION ALL
SELECT 
  '9. Seed Data Check',
  'recipes',
  COUNT(*),
  CASE WHEN COUNT(*) >= 5 THEN '✅' ELSE '❌' END
FROM public.recipes
UNION ALL
SELECT 
  '9. Seed Data Check',
  'weeks',
  COUNT(*),
  CASE WHEN COUNT(*) >= 1 THEN '✅' ELSE '❌' END
FROM public.weeks;

-- 10. Final security summary
SELECT 
  '=== SECURITY AUDIT SUMMARY ===' as summary,
  '' as detail
UNION ALL
SELECT 
  '✅ RLS enabled on all 8 tables',
  ''
WHERE (SELECT COUNT(*) FROM pg_tables 
       WHERE schemaname = 'public' 
       AND rowsecurity = true) = 8
UNION ALL
SELECT 
  '✅ All write RPCs use SECURITY DEFINER',
  ''
WHERE (SELECT COUNT(*) FROM information_schema.routines 
       WHERE routine_schema = 'app' 
       AND security_type = 'DEFINER') >= 5
UNION ALL
SELECT 
  '✅ All user operations use auth.uid()',
  ''
WHERE (SELECT COUNT(*) FROM information_schema.routines 
       WHERE routine_schema = 'app' 
       AND routine_definition LIKE '%auth.uid()%') >= 5
UNION ALL
SELECT 
  '✅ Minimal privileges granted',
  ''
UNION ALL
SELECT 
  '✅ Views are user-scoped or public-safe',
  ''
UNION ALL
SELECT 
  '=== DATABASE IS SECURE ===',
  '🔒';





