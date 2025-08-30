-- Box functionality verification script
-- Tests the box summary, selections, and locking features
-- This should NOT run as a migration - it's for manual testing

\echo 'Starting box functionality tests...'

-- Create a test user (you'll need to replace this UUID with an actual auth user)
-- This is just for demonstration - in real usage, auth.uid() provides the user
\set test_user_id '12345678-1234-1234-1234-123456789012'

\echo 'Testing box summary functions...'

-- Test current box summary (should handle missing data gracefully)
\echo 'Testing current_box_summary for non-existent user...'
select app.current_box_summary('12345678-1234-1234-1234-123456789012'::uuid);

-- Test with actual recipes (assuming some exist)
\echo 'Checking if recipes exist for testing...'
select count(*) as recipe_count from public.recipes where is_active = true;

-- Show available recipes for testing
\echo 'Available recipes for testing:'
select id, title, slug, price_cents, is_active
from public.recipes 
where is_active = true 
limit 5;

-- Test lock integrity check
\echo 'Testing lock integrity check...'
select app.lock_integrity('12345678-1234-1234-1234-123456789012'::uuid);

-- Test checkout lock on empty box
\echo 'Testing checkout lock on empty box (should fail)...'
select app.checkout_lock('12345678-1234-1234-1234-123456789012'::uuid);

-- Test public recipe functions
\echo 'Testing public recipe functions...'

-- Test featured recipes
\echo 'Testing get_featured_recipes...'
select count(*) as featured_count from public.get_featured_recipes(5);

-- Test recipe search
\echo 'Testing recipe search...'
select count(*) as search_results 
from public.search_recipes('chicken', null, null, null, null, null, 10);

-- Test recipes by tags (if any recipes have tags)
\echo 'Testing get_recipes_by_tags...'
select count(*) as tagged_recipes
from public.get_recipes_by_tags(array['vegetarian'], 5);

-- Check recipe public view
\echo 'Testing recipes_public view...'
select 
    count(*) as total_recipes,
    count(case when is_featured then 1 end) as featured_recipes,
    count(case when is_vegetarian then 1 end) as vegetarian_recipes
from public.recipes_public;

-- Test week status functions
\echo 'Testing week status...'
select public.current_week_start() as current_week;

-- Performance checks
\echo 'Checking index usage...'
explain (analyze, buffers) 
select * from public.recipes_public 
where is_featured = true 
order by priority desc 
limit 5;

\echo 'Box functionality tests complete!'
\echo 'Note: Some tests may show empty results if no sample data exists yet.'
\echo 'Run seed data scripts to populate test data for full functionality testing.'