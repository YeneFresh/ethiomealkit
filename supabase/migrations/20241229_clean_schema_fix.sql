-- Clean Schema Fix Migration
-- This migration cleans up all conflicting schemas and creates a consistent database

-- Drop all conflicting objects first
DROP SCHEMA IF EXISTS app CASCADE;
DROP TABLE IF EXISTS public.user_recipe_selections CASCADE;
DROP TABLE IF EXISTS public.recipes CASCADE;
DROP TABLE IF EXISTS public.weeks CASCADE;
DROP TABLE IF EXISTS public.user_onboarding_state CASCADE;
DROP TABLE IF EXISTS public.user_active_window CASCADE;
DROP TABLE IF EXISTS public.delivery_windows CASCADE;
DROP TABLE IF EXISTS public.weekly_menu CASCADE;

-- =============================================================================
-- 1. DELIVERY WINDOWS (Base Table + Seeds)
-- =============================================================================

-- Create delivery_windows table
CREATE TABLE public.delivery_windows (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  start_at timestamptz NOT NULL,
  end_at timestamptz NOT NULL,
  weekday int NOT NULL CHECK (weekday >= 0 AND weekday <= 6), -- 0=Sunday, 6=Saturday
  slot text NOT NULL, -- e.g., "14-16", "10-12"
  city text NOT NULL DEFAULT 'Addis Ababa',
  capacity int NOT NULL DEFAULT 20,
  booked_count int NOT NULL DEFAULT 0,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.delivery_windows ENABLE ROW LEVEL SECURITY;

-- Create policy for public read
DROP POLICY IF EXISTS "Public read delivery windows" ON public.delivery_windows;
CREATE POLICY "Public read delivery windows" ON public.delivery_windows
  FOR SELECT USING (is_active = true);

-- =============================================================================
-- 2. USER ACTIVE WINDOW
-- =============================================================================

-- Create user_active_window table
CREATE TABLE public.user_active_window (
  user_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  window_id uuid NOT NULL REFERENCES public.delivery_windows(id),
  location_label text NOT NULL CHECK (location_label IN ('Home - Addis Ababa', 'Office - Addis Ababa')),
  created_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.user_active_window ENABLE ROW LEVEL SECURITY;

-- Create policy for user-specific access
DROP POLICY IF EXISTS "Users can manage their own active window" ON public.user_active_window;
CREATE POLICY "Users can manage their own active window" ON public.user_active_window
  FOR ALL USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- =============================================================================
-- 3. USER ONBOARDING STATE
-- =============================================================================

-- Create user_onboarding_state table
CREATE TABLE public.user_onboarding_state (
  user_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  stage text NOT NULL CHECK (stage IN ('box', 'auth', 'delivery', 'recipes', 'checkout', 'done')),
  plan_box_size int NOT NULL CHECK (plan_box_size IN (2, 4)),
  meals_per_week int NOT NULL CHECK (meals_per_week >= 3 AND meals_per_week <= 5),
  draft_window_id uuid REFERENCES public.delivery_windows(id),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.user_onboarding_state ENABLE ROW LEVEL SECURITY;

-- Create policy for user-specific access
DROP POLICY IF EXISTS "Users can manage their own onboarding state" ON public.user_onboarding_state;
CREATE POLICY "Users can manage their own onboarding state" ON public.user_onboarding_state
  FOR ALL USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- =============================================================================
-- 4. WEEKS AND RECIPES
-- =============================================================================

-- Create weeks table
CREATE TABLE public.weeks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  week_start date NOT NULL UNIQUE,
  is_current boolean NOT NULL DEFAULT false,
  created_at timestamptz DEFAULT now()
);

-- Create recipes table
CREATE TABLE public.recipes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  week_id uuid NOT NULL REFERENCES public.weeks(id) ON DELETE CASCADE,
  title text NOT NULL,
  slug text NOT NULL UNIQUE,
  image_url text,
  tags text[] DEFAULT '{}',
  is_active boolean NOT NULL DEFAULT true,
  sort_order int DEFAULT 0,
  created_at timestamptz DEFAULT now()
);

-- Create user_recipe_selections table
CREATE TABLE public.user_recipe_selections (
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  recipe_id uuid NOT NULL REFERENCES public.recipes(id) ON DELETE CASCADE,
  week_start date NOT NULL,
  selected boolean NOT NULL DEFAULT false,
  created_at timestamptz DEFAULT now(),
  PRIMARY KEY (user_id, recipe_id, week_start)
);

-- Enable RLS on all tables
ALTER TABLE public.weeks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.recipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_recipe_selections ENABLE ROW LEVEL SECURITY;

-- Create policies
DROP POLICY IF EXISTS "Public read weeks" ON public.weeks;
CREATE POLICY "Public read weeks" ON public.weeks
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public read recipes" ON public.recipes;
CREATE POLICY "Public read recipes" ON public.recipes
  FOR SELECT USING (is_active = true);

DROP POLICY IF EXISTS "Users can manage their own recipe selections" ON public.user_recipe_selections;
CREATE POLICY "Users can manage their own recipe selections" ON public.user_recipe_selections
  FOR ALL USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- =============================================================================
-- 5. SEED DATA
-- =============================================================================

-- Seed current week
INSERT INTO public.weeks (id, week_start, is_current)
VALUES (
  gen_random_uuid(),
  date_trunc('week', now())::date,
  true
);

-- Seed delivery windows
INSERT INTO public.delivery_windows (id, start_at, end_at, weekday, slot, city, capacity, booked_count, is_active)
VALUES 
  (
    gen_random_uuid(),
    (date_trunc('week', now()) + interval '4 days' + interval '10 hours')::timestamptz,
    (date_trunc('week', now()) + interval '4 days' + interval '12 hours')::timestamptz,
    4, -- Thursday
    '10-12',
    'Addis Ababa',
    20,
    0,
    true
  ),
  (
    gen_random_uuid(),
    (date_trunc('week', now()) + interval '6 days' + interval '14 hours')::timestamptz,
    (date_trunc('week', now()) + interval '6 days' + interval '16 hours')::timestamptz,
    6, -- Saturday
    '14-16',
    'Addis Ababa',
    15,
    0,
    true
  ),
  (
    gen_random_uuid(),
    (date_trunc('week', now()) + interval '1 days' + interval '8 hours')::timestamptz,
    (date_trunc('week', now()) + interval '1 days' + interval '10 hours')::timestamptz,
    1, -- Monday
    '08-10',
    'Addis Ababa',
    15,
    0,
    true
  ),
  (
    gen_random_uuid(),
    (date_trunc('week', now()) + interval '3 days' + interval '18 hours')::timestamptz,
    (date_trunc('week', now()) + interval '3 days' + interval '20 hours')::timestamptz,
    3, -- Wednesday
    '18-20',
    'Addis Ababa',
    12,
    0,
    true
  );

-- Seed sample recipes for current week
WITH current_week AS (
  SELECT id FROM public.weeks WHERE is_current = true LIMIT 1
)
INSERT INTO public.recipes (id, week_id, title, slug, image_url, tags, sort_order, is_active)
SELECT 
  gen_random_uuid(),
  cw.id,
  'Injera with Beef Stew',
  'injera-beef-stew',
  '/images/injera-beef-stew.jpg',
  ARRAY['traditional', 'beef', 'spicy'],
  1,
  true
FROM current_week cw
UNION ALL
SELECT 
  gen_random_uuid(),
  cw.id,
  'Doro Wat',
  'doro-wat',
  '/images/doro-wat.jpg',
  ARRAY['traditional', 'chicken', 'spicy', 'eggs'],
  2,
  true
FROM current_week cw
UNION ALL
SELECT 
  gen_random_uuid(),
  cw.id,
  'Kitfo',
  'kitfo',
  '/images/kitfo.jpg',
  ARRAY['traditional', 'beef', 'raw', 'spicy'],
  3,
  true
FROM current_week cw
UNION ALL
SELECT 
  gen_random_uuid(),
  cw.id,
  'Shiro Wat',
  'shiro-wat',
  '/images/shiro-wat.jpg',
  ARRAY['vegetarian', 'chickpea', 'mild'],
  4,
  true
FROM current_week cw
UNION ALL
SELECT 
  gen_random_uuid(),
  cw.id,
  'Tibs',
  'tibs',
  '/images/tibs.jpg',
  ARRAY['traditional', 'beef', 'vegetables', 'mild'],
  5,
  true
FROM current_week cw;

-- =============================================================================
-- 6. APP SCHEMA
-- =============================================================================

-- Create app schema
CREATE SCHEMA app;

-- =============================================================================
-- 7. APP VIEWS
-- =============================================================================

-- 1. Available Delivery Windows View
CREATE VIEW app.available_delivery_windows AS
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
CREATE VIEW app.user_delivery_readiness AS
WITH current_user_data AS (
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
  FROM current_user_data cu
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
CREATE VIEW app.current_weekly_recipes AS
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

-- =============================================================================
-- 8. APP RPCs
-- =============================================================================

-- 1. Current Addis Week Function
CREATE FUNCTION app.current_addis_week()
RETURNS date
LANGUAGE sql
STABLE
AS $$
  SELECT date_trunc('week', now())::date;
$$;

-- 2. User Selections RPC
CREATE FUNCTION app.user_selections()
RETURNS TABLE(
  recipe_id uuid,
  week_start date,
  box_size int,
  selected boolean
)
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  WITH current_week AS (
    SELECT id, week_start FROM public.weeks WHERE is_current = true LIMIT 1
  ),
  user_onboarding AS (
    SELECT plan_box_size FROM public.user_onboarding_state WHERE user_id = auth.uid()
  ),
  weekly_recipes AS (
    SELECT r.id, cw.week_start
    FROM current_week cw
    JOIN public.recipes r ON r.week_id = cw.id AND r.is_active = true
  )
  SELECT 
    wr.id AS recipe_id,
    wr.week_start,
    COALESCE(uo.plan_box_size, 2) AS box_size,
    COALESCE(urs.selected, false) AS selected
  FROM weekly_recipes wr
  CROSS JOIN user_onboarding uo
  LEFT JOIN public.user_recipe_selections urs ON urs.recipe_id = wr.id 
    AND urs.user_id = auth.uid() AND urs.week_start = wr.week_start
  ORDER BY wr.id;
$$;

-- 3. Upsert User Active Window RPC
CREATE FUNCTION app.upsert_user_active_window(
  window_id uuid,
  location_label text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO public.user_active_window (user_id, window_id, location_label)
  VALUES (auth.uid(), window_id, location_label)
  ON CONFLICT (user_id) 
  DO UPDATE SET 
    window_id = EXCLUDED.window_id,
    location_label = EXCLUDED.location_label,
    created_at = now();
END;
$$;

-- 4. Set Onboarding Plan RPC
CREATE FUNCTION app.set_onboarding_plan(
  box_size int,
  meals_per_week int
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO public.user_onboarding_state (user_id, stage, plan_box_size, meals_per_week)
  VALUES (auth.uid(), 'box', box_size, meals_per_week)
  ON CONFLICT (user_id)
  DO UPDATE SET 
    plan_box_size = EXCLUDED.plan_box_size,
    meals_per_week = EXCLUDED.meals_per_week,
    stage = 'box',
    updated_at = now();
END;
$$;

-- 5. Toggle Recipe Selection RPC
CREATE FUNCTION app.toggle_recipe_selection(
  recipe_id uuid,
  select_recipe boolean
)
RETURNS TABLE(
  total_selected int,
  remaining int,
  allowed int,
  ok boolean
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  current_week_start date;
  user_plan int;
  current_selected int;
  new_selected int;
BEGIN
  -- Get current week
  SELECT week_start INTO current_week_start FROM public.weeks WHERE is_current = true LIMIT 1;
  
  -- Get user's plan (meals per week)
  SELECT meals_per_week INTO user_plan FROM public.user_onboarding_state WHERE user_id = auth.uid();
  
  -- Get current selection count
  SELECT COUNT(*) INTO current_selected 
  FROM public.user_recipe_selections 
  WHERE user_id = auth.uid() AND week_start = current_week_start AND selected = true;
  
  -- Calculate new selection count
  new_selected := current_selected + CASE WHEN select_recipe THEN 1 ELSE -1 END;
  
  -- Check if selection is valid
  IF new_selected < 0 OR new_selected > user_plan THEN
    -- Return current state with ok = false
    SELECT current_selected, (user_plan - current_selected), user_plan, false
    INTO total_selected, remaining, allowed, ok;
    RETURN;
  END IF;
  
  -- Update or insert selection
  INSERT INTO public.user_recipe_selections (user_id, recipe_id, week_start, selected)
  VALUES (auth.uid(), recipe_id, current_week_start, select_recipe)
  ON CONFLICT (user_id, recipe_id, week_start)
  DO UPDATE SET selected = select_recipe;
  
  -- Return new state
  SELECT new_selected, (user_plan - new_selected), user_plan, true
  INTO total_selected, remaining, allowed, ok;
  
  RETURN;
END;
$$;

-- =============================================================================
-- 9. PERMISSIONS
-- =============================================================================

-- Grant schema usage
GRANT USAGE ON SCHEMA app TO anon, authenticated;

-- Grant view permissions
GRANT SELECT ON app.available_delivery_windows TO anon, authenticated;
GRANT SELECT ON app.user_delivery_readiness TO anon, authenticated;
GRANT SELECT ON app.current_weekly_recipes TO anon, authenticated;

-- Grant function permissions
GRANT EXECUTE ON FUNCTION app.current_addis_week() TO anon, authenticated;
GRANT EXECUTE ON FUNCTION app.user_selections() TO anon, authenticated;
GRANT EXECUTE ON FUNCTION app.upsert_user_active_window(uuid, text) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION app.set_onboarding_plan(int, int) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION app.toggle_recipe_selection(uuid, boolean) TO anon, authenticated;

-- =============================================================================
-- 10. VERIFICATION
-- =============================================================================

-- Test all views and RPCs
DO $$
DECLARE
  window_count int;
  readiness_count int;
  recipe_count int;
  selection_count int;
  current_week_date date;
BEGIN
  -- Test views
  SELECT COUNT(*) INTO window_count FROM app.available_delivery_windows;
  RAISE NOTICE 'Available delivery windows: %', window_count;
  
  SELECT COUNT(*) INTO readiness_count FROM app.user_delivery_readiness;
  RAISE NOTICE 'User delivery readiness records: %', readiness_count;
  
  SELECT COUNT(*) INTO recipe_count FROM app.current_weekly_recipes;
  RAISE NOTICE 'Current weekly recipes: %', recipe_count;
  
  SELECT COUNT(*) INTO selection_count FROM app.user_selections();
  RAISE NOTICE 'User selections: %', selection_count;
  
  SELECT app.current_addis_week() INTO current_week_date;
  RAISE NOTICE 'Current week: %', current_week_date;
  
  RAISE NOTICE 'All migrations completed successfully!';
END $$;






