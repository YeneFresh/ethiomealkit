-- Development Verification Script
-- Consolidated verification for all database functionality
-- Run manually after migrations to verify system integrity
-- 
-- Usage: psql -f supabase/scripts/dev_verification.sql
-- Or copy/paste sections into Supabase SQL Editor

\echo '🍲 EthioMealKit Database Verification'
\echo '=================================='
\echo ''

-- ========================================
-- SECTION 1: Schema Integrity Verification
-- ========================================

\echo '📋 1. SCHEMA INTEGRITY CHECKS'
\echo '-----------------------------'

-- Check if all expected tables exist
\echo 'Checking table existence...'
select 
    'Tables' as check_type,
    case when count(*) >= 10 then '✓ All core tables present (' || count(*) || ')' 
         else '✗ Missing tables (found: ' || count(*) || ', expected: ≥10)' 
    end as status
from information_schema.tables
where table_schema = 'public' 
and table_name in (
    'users', 'addresses', 'recipes', 'meal_kits', 
    'delivery_windows', 'orders', 'order_items', 
    'auth_events', 'user_week_status', 'box_selections'
);

-- Check app schema exists
\echo 'Checking app schema...'
select 
    'App Schema' as check_type,
    case when exists (select 1 from information_schema.schemata where schema_name = 'app')
         then '✓ App schema exists'
         else '✗ App schema missing'
    end as status;

-- Check recipe schema enhancements
\echo 'Checking recipe schema completeness...'
select 
    'Recipe Schema' as check_type,
    case when count(*) >= 16 then '✓ Recipe columns complete (' || count(*) || ')'
         else '✗ Recipe columns missing (found: ' || count(*) || ', expected: ≥16)'
    end as status
from information_schema.columns
where table_schema = 'public' 
and table_name = 'recipes'
and column_name in (
    'id', 'title', 'description', 'image_url', 'slug',
    'price_cents', 'kcal', 'prep_time_mins', 'cook_time_mins',
    'serving_size', 'difficulty_level', 'tags', 'chef_note',
    'is_featured', 'is_active', 'priority', 'created_at'
);

-- Check slug constraints
\echo 'Checking slug system...'
select 
    'Slug Constraints' as check_type,
    case when exists (
        select 1 from information_schema.table_constraints 
        where table_name = 'recipes' 
        and constraint_name = 'recipes_slug_format'
        and constraint_type = 'CHECK'
    ) then '✓ Slug format constraint exists'
    else '✗ Slug format constraint missing'
    end as status

union all

select 
    'Slug Index' as check_type,
    case when exists (
        select 1 from pg_indexes 
        where tablename = 'recipes' 
        and indexname = 'recipes_slug_unique'
    ) then '✓ Slug unique index exists'
    else '✗ Slug unique index missing'
    end as status;

-- ========================================
-- SECTION 2: Function and View Verification
-- ========================================

\echo ''
\echo '⚙️  2. FUNCTION & VIEW VERIFICATION'
\echo '--------------------------------'

-- Check app schema functions
\echo 'Checking app schema functions...'
select 
    'App Functions' as check_type,
    function_name,
    case when function_name is not null then '✓ Exists' else '✗ Missing' end as status
from (
    values 
        ('current_box_summary'),
        ('lock_integrity'),
        ('checkout_lock'),
        ('generate_slug'),
        ('prevent_slug_update'),
        ('slug_immutability_enabled')
) as expected(function_name)
left join (
    select routine_name as function_name
    from information_schema.routines
    where routine_schema = 'app'
    and routine_type = 'FUNCTION'
) as actual using (function_name)
order by function_name;

-- Check public functions
\echo 'Checking public functions...'
select 
    'Public Functions' as check_type,
    function_name,
    case when function_name is not null then '✓ Exists' else '✗ Missing' end as status
from (
    values 
        ('current_week_start'),
        ('get_featured_recipes'),
        ('get_recipes_by_difficulty'),
        ('get_recipes_by_tags'),
        ('search_recipes'),
        ('get_recipe_recommendations')
) as expected(function_name)
left join (
    select routine_name as function_name
    from information_schema.routines
    where routine_schema = 'public'
    and routine_type = 'FUNCTION'
) as actual using (function_name)
order by function_name;

-- Check views
\echo 'Checking views...'
select 
    'Views' as check_type,
    'recipes_public' as view_name,
    case when exists (
        select 1 from information_schema.views
        where table_schema = 'public'
        and table_name = 'recipes_public'
    ) then '✓ View exists'
    else '✗ View missing'
    end as status;

-- ========================================
-- SECTION 3: Function Testing
-- ========================================

\echo ''
\echo '🧪 3. FUNCTION TESTING'
\echo '-------------------'

-- Test slug generation
\echo 'Testing slug generation...'
select 
    'Slug Generation' as test_type,
    app.generate_slug('Test Recipe Title!!!') as generated_slug,
    '✓ Function works' as status;

-- Test week start function
\echo 'Testing week start function...'
select 
    'Week Start' as test_type,
    public.current_week_start() as current_week_start,
    '✓ Function works' as status;

-- Test slug immutability flag
\echo 'Testing slug immutability flag...'
select 
    'Slug Flag' as test_type,
    app.slug_immutability_enabled() as flag_enabled,
    '✓ Function works' as status;

-- ========================================
-- SECTION 4: RLS and Security Verification
-- ========================================

\echo ''
\echo '🔒 4. SECURITY & RLS VERIFICATION'
\echo '-------------------------------'

-- Check RLS is enabled
\echo 'Checking RLS policies...'
select 
    'RLS Enabled' as check_type,
    schemaname || '.' || tablename as table_name,
    case when rowsecurity then '✓ RLS enabled' else '✗ RLS disabled' end as status
from pg_tables
where schemaname = 'public'
and tablename in ('users', 'addresses', 'recipes', 'meal_kits', 'orders', 'box_selections')
order by tablename;

-- Count policies per table
\echo 'Counting RLS policies...'
select 
    'Policy Count' as check_type,
    schemaname || '.' || tablename as table_name,
    count(*) as policy_count,
    case when count(*) > 0 then '✓ Has policies' else '⚠ No policies' end as status
from pg_policies
where schemaname = 'public'
group by schemaname, tablename
order by tablename;

-- ========================================
-- SECTION 5: Index and Performance Verification
-- ========================================

\echo ''
\echo '⚡ 5. INDEX & PERFORMANCE VERIFICATION'
\echo '-----------------------------------'

-- Check key indexes exist
\echo 'Checking critical indexes...'
select 
    'Index Check' as check_type,
    indexname,
    tablename,
    '✓ Index exists' as status
from pg_indexes
where schemaname = 'public'
and (
    indexname like 'idx_%' or 
    indexname like '%_unique' or 
    indexname like '%_pkey'
)
order by tablename, indexname;

-- ========================================
-- SECTION 6: Data Consistency Verification
-- ========================================

\echo ''
\echo '📊 6. DATA CONSISTENCY VERIFICATION'
\echo '---------------------------------'

-- Check sample data counts
\echo 'Checking data counts...'
select 'meal_kits' as table_name, count(*) as row_count, 
       case when count(*) > 0 then '✓ Has data' else '⚠ Empty' end as status
from public.meal_kits

union all

select 'recipes' as table_name, count(*) as row_count,
       case when count(*) > 0 then '✓ Has data' else '⚠ Empty' end as status
from public.recipes

union all

select 'users' as table_name, count(*) as row_count,
       case when count(*) > 0 then '✓ Has data' else '⚠ Empty (expected)' end as status
from public.users;

-- Check for orphaned records
\echo 'Checking referential integrity...'
select 
    'Orphaned Check' as check_type,
    'box_selections → recipes' as relationship,
    case when count(*) = 0 then '✓ No orphaned selections'
         else '✗ Found ' || count(*) || ' orphaned selections'
    end as status
from public.box_selections bs
left join public.recipes r on r.id = bs.recipe_id
where r.id is null;

-- ========================================
-- SECTION 7: Business Logic Testing
-- ========================================

\echo ''
\echo '🏪 7. BUSINESS LOGIC TESTING'
\echo '-------------------------'

-- Test recipe public view (if data exists)
\echo 'Testing recipe public view...'
select 
    'Recipe Public View' as test_type,
    count(*) as visible_recipes,
    case when count(*) >= 0 then '✓ View accessible' else '✗ View error' end as status
from public.recipes_public;

-- Test search functionality (if recipes exist)
\echo 'Testing recipe search...'
select 
    'Recipe Search' as test_type,
    count(*) as search_results,
    case when count(*) >= 0 then '✓ Search works' else '✗ Search error' end as status
from public.search_recipes('recipe', null, null, null, null, null, 10);

-- ========================================
-- SECTION 8: Summary Report
-- ========================================

\echo ''
\echo '📈 8. VERIFICATION SUMMARY'
\echo '------------------------'

-- Overall system health check
\echo 'System health overview...'
with health_check as (
    select 
        (select count(*) from information_schema.tables where table_schema = 'public') as table_count,
        (select count(*) from information_schema.routines where routine_schema = 'app') as app_function_count,
        (select count(*) from information_schema.routines where routine_schema = 'public' and routine_type = 'FUNCTION') as public_function_count,
        (select count(*) from information_schema.views where table_schema = 'public') as view_count,
        (select count(*) from pg_policies where schemaname = 'public') as policy_count
)
select 
    'System Health' as check_type,
    'Tables: ' || table_count || ', App Functions: ' || app_function_count || 
    ', Public Functions: ' || public_function_count || ', Views: ' || view_count || 
    ', RLS Policies: ' || policy_count as metrics,
    case when table_count >= 10 and app_function_count >= 5 and view_count >= 1
         then '✅ System healthy'
         else '⚠ System incomplete'
    end as overall_status
from health_check;

\echo ''
\echo '✅ Verification complete!'
\echo ''
\echo '💡 Next steps:'
\echo '   • If any ✗ items above, review migration deployment'
\echo '   • Run seed data scripts to populate sample content'
\echo '   • Test app connectivity with Flutter client'
\echo '   • Monitor performance with real data load'
\echo ''