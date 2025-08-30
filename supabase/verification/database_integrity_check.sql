-- Database integrity verification script
-- This should NOT run as a migration
-- Run manually to verify database state after migrations

\echo 'Starting database integrity verification...'

-- Check if all expected tables exist
\echo 'Checking table existence...'
select 
    case when count(*) = 12 then '✓ All tables present' 
         else '✗ Missing tables: ' || (12 - count(*)::int)::text 
    end as table_check
from information_schema.tables
where table_schema = 'public' 
and table_name in (
    'users', 'addresses', 'recipes', 'meal_kits', 
    'delivery_windows', 'orders', 'order_items', 
    'auth_events', 'user_week_status', 'box_selections'
);

-- Check recipe schema enhancements
\echo 'Checking recipe schema...'
select 
    case when count(*) >= 15 then '✓ Recipe columns complete'
         else '✗ Recipe columns missing: ' || (15 - count(*)::int)::text
    end as recipe_schema_check
from information_schema.columns
where table_schema = 'public' 
and table_name = 'recipes'
and column_name in (
    'id', 'title', 'description', 'image_url', 'slug',
    'price_cents', 'kcal', 'prep_time_mins', 'cook_time_mins',
    'serving_size', 'difficulty_level', 'tags', 'chef_note',
    'is_featured', 'is_active', 'priority'
);

-- Check slug constraints
\echo 'Checking slug constraints...'
select 
    case when exists (
        select 1 from information_schema.table_constraints tc
        join information_schema.constraint_column_usage ccu using (constraint_name)
        where tc.table_name = 'recipes' 
        and tc.constraint_type = 'CHECK'
        and tc.constraint_name = 'recipes_slug_format'
    ) then '✓ Slug format constraint exists'
    else '✗ Slug format constraint missing'
    end as slug_constraint_check;

-- Check app schema and functions
\echo 'Checking app schema functions...'
select 
    function_name,
    case when function_name is not null then '✓ Exists' else '✗ Missing' end as status
from (
    values 
        ('current_box_summary'),
        ('lock_integrity'),
        ('checkout_lock'),
        ('generate_slug'),
        ('slug_immutability_enabled')
) as expected(function_name)
left join (
    select routine_name as function_name
    from information_schema.routines
    where routine_schema = 'app'
    and routine_type = 'FUNCTION'
) as actual using (function_name);

-- Check public functions
\echo 'Checking public functions...'
select 
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
) as actual using (function_name);

-- Check views
\echo 'Checking views...'
select 
    case when exists (
        select 1 from information_schema.views
        where table_schema = 'public'
        and table_name = 'recipes_public'
    ) then '✓ recipes_public view exists'
    else '✗ recipes_public view missing'
    end as view_check;

-- Check RLS policies
\echo 'Checking RLS policies...'
select 
    schemaname,
    tablename,
    policyname,
    '✓ Policy exists' as status
from pg_policies
where schemaname = 'public'
order by tablename, policyname;

-- Check indexes
\echo 'Checking key indexes...'
select 
    indexname,
    tablename,
    '✓ Index exists' as status
from pg_indexes
where schemaname = 'public'
and indexname like any(array['idx_%', '%_unique', '%_pkey'])
order by tablename, indexname;

-- Sample data verification
\echo 'Checking sample data...'
select 'meal_kits' as table_name, count(*) as row_count from public.meal_kits
union all
select 'recipes' as table_name, count(*) as row_count from public.recipes
union all
select 'users' as table_name, count(*) as row_count from public.users;

-- Test slug generation
\echo 'Testing slug generation...'
select app.generate_slug('Test Recipe Title') as generated_slug;

-- Test week start function
\echo 'Testing week start function...'
select public.current_week_start() as current_week_start;

\echo 'Database integrity verification complete!'
\echo 'Review the output above for any ✗ (missing) items that need attention.'