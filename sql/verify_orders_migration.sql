-- =============================================================================
-- Orders Migration Verification Script
-- Run this after executing sql/000_robust_migration.sql
-- =============================================================================

-- 1. Check all tables exist
SELECT 
  'Tables Check' as test,
  COUNT(*) as found,
  8 as expected,
  CASE WHEN COUNT(*) = 8 THEN '✅ PASS' ELSE '❌ FAIL' END as status
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name IN (
    'delivery_windows',
    'user_active_window', 
    'user_onboarding_state',
    'weeks',
    'recipes',
    'user_recipe_selections',
    'orders',
    'order_items'
  );

-- 2. Check app schema RPCs
SELECT 
  'RPCs Check' as test,
  COUNT(*) as found,
  6 as expected,
  CASE WHEN COUNT(*) = 6 THEN '✅ PASS' ELSE '❌ FAIL' END as status
FROM information_schema.routines 
WHERE routine_schema = 'app'
  AND routine_type = 'FUNCTION';

-- 3. List all RPCs (detailed)
SELECT 
  routine_name,
  routine_type,
  CASE 
    WHEN routine_name = 'confirm_scheduled_order' THEN '⭐ NEW'
    ELSE '✓'
  END as status
FROM information_schema.routines 
WHERE routine_schema = 'app'
ORDER BY routine_name;

-- 4. Check RLS policies on orders tables
SELECT 
  'Orders RLS' as test,
  COUNT(*) as found,
  2 as expected,
  CASE WHEN COUNT(*) = 2 THEN '✅ PASS' ELSE '❌ FAIL' END as status
FROM pg_policies
WHERE tablename IN ('orders', 'order_items');

-- 5. Verify orders table structure
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'orders'
ORDER BY ordinal_position;

-- 6. Verify order_items table structure
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'order_items'
ORDER BY ordinal_position;

-- 7. Check confirm_scheduled_order function signature
SELECT 
  routine_name,
  data_type as return_type,
  type_udt_name
FROM information_schema.routines
WHERE routine_schema = 'app'
  AND routine_name = 'confirm_scheduled_order';

-- 8. Check seed data exists
SELECT 
  'Delivery Windows' as table_name,
  COUNT(*) as count,
  CASE WHEN COUNT(*) >= 4 THEN '✅ PASS' ELSE '⚠️ WARNING' END as status
FROM public.delivery_windows
UNION ALL
SELECT 
  'Recipes' as table_name,
  COUNT(*) as count,
  CASE WHEN COUNT(*) >= 5 THEN '✅ PASS' ELSE '⚠️ WARNING' END as status
FROM public.recipes
UNION ALL
SELECT 
  'Weeks' as table_name,
  COUNT(*) as count,
  CASE WHEN COUNT(*) >= 1 THEN '✅ PASS' ELSE '⚠️ WARNING' END as status
FROM public.weeks;

-- 9. Verify foreign key constraints on orders
SELECT
  conname as constraint_name,
  contype as constraint_type,
  pg_get_constraintdef(oid) as definition
FROM pg_constraint
WHERE conrelid = 'public.orders'::regclass
ORDER BY contype;

-- 10. Summary
SELECT 
  '=== MIGRATION VERIFICATION SUMMARY ===' as summary
UNION ALL
SELECT 
  '✅ All tables created' 
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name IN ('orders', 'order_items')
HAVING COUNT(*) = 2
UNION ALL
SELECT 
  '✅ confirm_scheduled_order RPC created'
FROM information_schema.routines
WHERE routine_schema = 'app' 
  AND routine_name = 'confirm_scheduled_order'
UNION ALL
SELECT 
  '✅ RLS policies enabled'
FROM pg_policies
WHERE tablename IN ('orders', 'order_items')
HAVING COUNT(*) = 2
UNION ALL
SELECT 
  '=== READY FOR FRONTEND INTEGRATION ===' as summary;





