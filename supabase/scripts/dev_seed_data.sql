-- Development Seeding Script
-- Creates test users, sample recipes, and box selections for development/testing
-- Run manually after migrations - NOT part of migration process
--
-- ⚠️  DO NOT run in production - this creates test data only
-- 
-- Usage: psql -f supabase/scripts/dev_seed_data.sql

\echo '🌱 EthioMealKit Development Data Seeding'
\echo '======================================'
\echo ''
\echo '⚠️  This creates TEST DATA - do not run in production!'
\echo ''

-- Test user IDs (replace with actual auth.users IDs in real usage)
\set TEST_USER_ID_1 '11111111-1111-1111-1111-111111111111'
\set TEST_USER_ID_2 '22222222-2222-2222-2222-222222222222'

-- ========================================
-- SECTION 1: Test Users
-- ========================================

\echo '👤 1. CREATING TEST USERS'
\echo '----------------------'

-- Insert test users (these would normally be created by auth.users)
-- In development, you can create these manually or use Supabase auth
insert into public.users (id, name, phone, created_at) values
    (:'TEST_USER_ID_1', 'Test User One', '+251911123456', now() - interval '2 months'),
    (:'TEST_USER_ID_2', 'Test User Two', '+251922654321', now() - interval '1 month')
on conflict (id) do update set
    name = excluded.name,
    phone = excluded.phone;

\echo 'Created 2 test users'

-- ========================================
-- SECTION 2: Test Addresses
-- ========================================

\echo '🏠 2. CREATING TEST ADDRESSES'
\echo '---------------------------'

insert into public.addresses (user_id, label, line1, line2, city, region, is_default) values
    (:'TEST_USER_ID_1', 'Home', 'Kazanchis, Near Hilton Hotel', 'Building 123, Apt 4B', 'Addis Ababa', 'Addis Ababa', true),
    (:'TEST_USER_ID_1', 'Office', 'Bole, Atlas Hotel Area', 'Office Building 2nd Floor', 'Addis Ababa', 'Addis Ababa', false),
    (:'TEST_USER_ID_2', 'Home', 'Piassa, Churchill Avenue', 'Blue Building, Floor 3', 'Addis Ababa', 'Addis Ababa', true)
on conflict do nothing;

\echo 'Created test addresses'

-- ========================================
-- SECTION 3: Sample Recipes with Full Data
-- ========================================

\echo '🍛 3. CREATING SAMPLE RECIPES'
\echo '---------------------------'

-- Temporarily disable slug immutability for bulk seeding
select app.disable_slug_immutability();

insert into public.recipes (
    id, title, description, image_url, slug, price_cents, kcal, 
    prep_time_mins, cook_time_mins, serving_size, difficulty_level, 
    tags, chef_note, is_featured, is_active, priority
) values
    (
        gen_random_uuid(),
        'Doro Wat',
        'Ethiopia''s national dish - chicken stew in berbere sauce',
        'https://picsum.photos/seed/doro/600/400',
        'doro-wat',
        1200, 450, 30, 90, 4, 'medium',
        array['traditional', 'spicy', 'chicken', 'berbere'],
        'The key to great doro wat is slow-cooking the berbere base and using quality Ethiopian spices.',
        true, true, 100
    ),
    (
        gen_random_uuid(),
        'Shiro Tegamino',
        'Creamy chickpea flour stew, perfect for vegetarians',
        'https://picsum.photos/seed/shiro/600/400',
        'shiro-tegamino',
        900, 320, 15, 25, 3, 'easy',
        array['vegetarian', 'traditional', 'chickpea', 'comfort'],
        'Mix shiro powder gradually to avoid lumps. Serve with injera for best experience.',
        true, true, 90
    ),
    (
        gen_random_uuid(),
        'Beef Tibs',
        'Pan-seared beef cubes with awaze and vegetables',
        'https://picsum.photos/seed/tibs/600/400',
        'beef-tibs',
        1100, 380, 20, 15, 2, 'easy',
        array['beef', 'quick', 'awaze', 'vegetables'],
        'High heat and quick searing keeps the beef tender. Don''t overcook!',
        false, true, 80
    ),
    (
        gen_random_uuid(),
        'Gomen Besiga',
        'Collard greens with tender beef pieces',
        'https://picsum.photos/seed/gomen/600/400',
        'gomen-besiga',
        1000, 290, 25, 45, 4, 'medium',
        array['beef', 'greens', 'healthy', 'traditional'],
        'Slow cooking brings out the best flavors. Add ginger and garlic early.',
        false, true, 70
    ),
    (
        gen_random_uuid(),
        'Vegetarian Combination',
        'Mixed vegetarian dishes - perfect sampler',
        'https://picsum.photos/seed/veggie/600/400',
        'vegetarian-combination',
        950, 340, 40, 35, 3, 'medium',
        array['vegetarian', 'mixed', 'sampler', 'healthy'],
        'Great introduction to Ethiopian vegetarian cuisine. Each dish complements the others.',
        true, true, 85
    ),
    (
        gen_random_uuid(),
        'Kitfo Special',
        'Ethiopian-style steak tartare with mitmita and ayib',
        'https://picsum.photos/seed/kitfo/600/400',
        'kitfo-special',
        1300, 420, 15, 0, 2, 'easy',
        array['beef', 'raw', 'special', 'mitmita'],
        'Use the freshest, highest quality beef. Serve immediately after preparation.',
        true, true, 95
    )
on conflict (slug) do update set
    title = excluded.title,
    description = excluded.description,
    price_cents = excluded.price_cents,
    kcal = excluded.kcal,
    updated_at = now();

-- Re-enable slug immutability
select app.enable_slug_immutability();

\echo 'Created 6 sample recipes with full data'

-- ========================================
-- SECTION 4: Sample Delivery Windows
-- ========================================

\echo '🚚 4. CREATING DELIVERY WINDOWS'
\echo '-----------------------------'

insert into public.delivery_windows (start_time, end_time, weekdays) values
    ('09:00', '12:00', array[1,2,3,4,5]),  -- Mon-Fri morning
    ('14:00', '18:00', array[1,2,3,4,5]),  -- Mon-Fri afternoon
    ('10:00', '14:00', array[0,6]),        -- Weekend midday
    ('16:00', '20:00', array[0,6])         -- Weekend evening
on conflict do nothing;

\echo 'Created delivery window options'

-- ========================================
-- SECTION 5: Test User Week Status & Selections
-- ========================================

\echo '📅 5. CREATING TEST USER DATA'
\echo '---------------------------'

-- Create current week status for test users
insert into public.user_week_status (user_id, week_start_date, status, meals_selected) values
    (:'TEST_USER_ID_1', public.current_week_start(), 'active', 0),
    (:'TEST_USER_ID_2', public.current_week_start(), 'active', 0),
    -- Previous week data for testing
    (:'TEST_USER_ID_1', public.current_week_start() - interval '1 week', 'active', 3),
    (:'TEST_USER_ID_2', public.current_week_start() - interval '1 week', 'active', 2)
on conflict (user_id, week_start_date) do nothing;

\echo 'Created test user week status'

-- Create some sample box selections for test users
\echo 'Creating sample box selections...'

-- Get recipe IDs for selections (dynamic based on actual seeded recipes)
do $$
declare
    recipe_ids uuid[];
    test_user_1 uuid := '11111111-1111-1111-1111-111111111111';
    test_user_2 uuid := '22222222-2222-2222-2222-222222222222';
    current_week date;
    last_week date;
begin
    -- Get current and last week
    current_week := public.current_week_start();
    last_week := current_week - interval '1 week';
    
    -- Get some recipe IDs
    select array_agg(id) into recipe_ids
    from (select id from public.recipes where is_active = true limit 4) t;
    
    if array_length(recipe_ids, 1) >= 4 then
        -- Current week selections for user 1
        insert into public.box_selections (user_id, recipe_id, week_start_date, quantity) values
            (test_user_1, recipe_ids[1], current_week, 2),
            (test_user_1, recipe_ids[2], current_week, 1)
        on conflict (user_id, recipe_id, week_start_date) do nothing;
        
        -- Last week selections for user 1 (locked)
        insert into public.box_selections (user_id, recipe_id, week_start_date, quantity) values
            (test_user_1, recipe_ids[1], last_week, 1),
            (test_user_1, recipe_ids[3], last_week, 2),
            (test_user_1, recipe_ids[4], last_week, 1)
        on conflict (user_id, recipe_id, week_start_date) do nothing;
        
        -- Current week selections for user 2
        insert into public.box_selections (user_id, recipe_id, week_start_date, quantity) values
            (test_user_2, recipe_ids[2], current_week, 1),
            (test_user_2, recipe_ids[4], current_week, 1)
        on conflict (user_id, recipe_id, week_start_date) do nothing;
        
        -- Lock last week for user 1
        update public.user_week_status 
        set box_locked_at = last_week + interval '6 days', meals_selected = 3
        where user_id = test_user_1 and week_start_date = last_week;
        
        raise notice 'Created sample box selections for test users';
    else
        raise notice 'Not enough recipes found - skipping box selections';
    end if;
end $$;

-- ========================================
-- SECTION 6: Sample Orders (Historical)
-- ========================================

\echo '📦 6. CREATING SAMPLE ORDERS'
\echo '-------------------------'

-- Create a sample completed order for testing
do $$
declare
    test_user_1 uuid := '11111111-1111-1111-1111-111111111111';
    test_address_id uuid;
    test_delivery_window_id uuid;
    order_id uuid;
    kit_ids text[];
begin
    -- Get test data IDs
    select id into test_address_id 
    from public.addresses 
    where user_id = test_user_1 and is_default = true 
    limit 1;
    
    select id into test_delivery_window_id
    from public.delivery_windows
    limit 1;
    
    select array_agg(id) into kit_ids
    from (select id from public.meal_kits limit 3) t;
    
    if test_address_id is not null and test_delivery_window_id is not null and array_length(kit_ids, 1) >= 2 then
        -- Create sample order
        insert into public.orders (
            id, user_id, delivery_address_id, delivery_window_id, 
            total_cents, status, created_at
        ) values (
            gen_random_uuid(), test_user_1, test_address_id, test_delivery_window_id,
            2100, 'delivered', now() - interval '1 week'
        )
        returning id into order_id;
        
        -- Add order items
        insert into public.order_items (order_id, meal_kit_id, quantity, price_cents) values
            (order_id, kit_ids[1], 1, 1200),
            (order_id, kit_ids[2], 1, 900);
            
        raise notice 'Created sample order with 2 items';
    else
        raise notice 'Missing prerequisite data - skipping sample order';
    end if;
end $$;

-- ========================================
-- SECTION 7: Verification Summary
-- ========================================

\echo ''
\echo '📊 7. SEEDING SUMMARY'
\echo '------------------'

\echo 'Data counts after seeding:'
select 'users' as table_name, count(*) as row_count from public.users
union all
select 'addresses' as table_name, count(*) as row_count from public.addresses  
union all
select 'recipes' as table_name, count(*) as row_count from public.recipes
union all
select 'meal_kits' as table_name, count(*) as row_count from public.meal_kits
union all
select 'user_week_status' as table_name, count(*) as row_count from public.user_week_status
union all
select 'box_selections' as table_name, count(*) as row_count from public.box_selections
union all
select 'delivery_windows' as table_name, count(*) as row_count from public.delivery_windows
union all
select 'orders' as table_name, count(*) as row_count from public.orders
union all
select 'order_items' as table_name, count(*) as row_count from public.order_items;

-- Test box summary for test users
\echo ''
\echo 'Testing box summaries for test users:'
select 
    'Test User 1 Box Summary' as test_type,
    app.current_box_summary('11111111-1111-1111-1111-111111111111'::uuid) as summary;

\echo ''
\echo '✅ Development data seeding complete!'
\echo ''
\echo '💡 Test user credentials:'
\echo '   • Test User 1: 11111111-1111-1111-1111-111111111111'
\echo '   • Test User 2: 22222222-2222-2222-2222-222222222222'
\echo ''
\echo '🧪 Use these for testing:'
\echo '   • Box selection workflow'
\echo '   • Week status management'  
\echo '   • Order history'
\echo '   • Address management'
\echo ''
\echo '🔄 To reset test data, truncate tables and re-run this script'
\echo ''