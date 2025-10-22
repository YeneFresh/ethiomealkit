-- Complete Delivery Gate Migration (Robust Version)
-- Run this in Supabase SQL Editor to restore full delivery gate functionality
-- This version handles all edge cases and conflicts

-- ============================================================================
-- STEP 1: Clean up all existing objects safely
-- ============================================================================

-- Drop all views first (they depend on tables/functions)
DROP VIEW IF EXISTS app.user_delivery_gate_readiness CASCADE;
DROP VIEW IF EXISTS app.user_delivery_readiness CASCADE;

-- Handle user_profile as both view and table safely
DO $$
BEGIN
    -- Try to drop as view first
    BEGIN
        EXECUTE 'DROP VIEW IF EXISTS app.user_profile CASCADE';
    EXCEPTION WHEN OTHERS THEN
        NULL; -- Ignore if it's not a view
    END;
    
    -- Then try to drop as table
    BEGIN
        EXECUTE 'DROP TABLE IF EXISTS app.user_profile CASCADE';
    EXCEPTION WHEN OTHERS THEN
        NULL; -- Ignore if it's not a table
    END;
END $$;

-- Drop all functions that might reference tables
DROP FUNCTION IF EXISTS app.stage_delivery_choice(text, text) CASCADE;
DROP FUNCTION IF EXISTS app.confirm_delivery_choice() CASCADE;
DROP FUNCTION IF EXISTS public.get_delivery_windows(text, boolean, integer) CASCADE;
DROP FUNCTION IF EXISTS app.current_addis_week() CASCADE;

-- Drop all tables in correct order (respecting foreign key constraints)
DROP TABLE IF EXISTS app.user_delivery_staging CASCADE;
DROP TABLE IF EXISTS app.user_week_status CASCADE;
DROP TABLE IF EXISTS app.user_delivery_selections CASCADE;
DROP TABLE IF EXISTS app.user_selections CASCADE;
DROP TABLE IF EXISTS app.user_profiles CASCADE;
DROP TABLE IF EXISTS app.delivery_user_profiles CASCADE;
DROP TABLE IF EXISTS app.delivery_staging CASCADE;
DROP TABLE IF EXISTS app.delivery_week_status CASCADE;
DROP TABLE IF EXISTS app.delivery_user_selections CASCADE;
DROP TABLE IF EXISTS public.delivery_windows CASCADE;
DROP TABLE IF EXISTS public.weekly_menu CASCADE;

-- ============================================================================
-- STEP 2: Create app schema and core function
-- ============================================================================

CREATE SCHEMA IF NOT EXISTS app;

-- Create the core week function with proper Ethiopian timezone handling
CREATE OR REPLACE FUNCTION app.current_addis_week()
RETURNS date
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  current_utc_date date := (now() at time zone 'UTC')::date;
  addis_offset interval := '3 hours';
  addis_date date := (current_utc_date + addis_offset)::date;
  monday_date date;
BEGIN
  -- Find the Monday of the current week in Addis time
  monday_date := addis_date - (EXTRACT(DOW FROM addis_date) - 1) * INTERVAL '1 day';
  RETURN monday_date;
END;
$$;

GRANT EXECUTE ON FUNCTION app.current_addis_week() TO anon, authenticated;

-- ============================================================================
-- STEP 3: Create delivery windows table
-- ============================================================================

CREATE TABLE public.delivery_windows (
  id text PRIMARY KEY,
  label text NOT NULL,
  day_of_week text NOT NULL,
  start_time text NOT NULL,
  end_time text NOT NULL,
  city text DEFAULT 'Addis Ababa',
  is_active boolean DEFAULT true,
  max_orders integer DEFAULT 50,
  current_orders integer DEFAULT 0,
  has_capacity boolean GENERATED ALWAYS AS (current_orders < max_orders) STORED,
  slot text NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- ============================================================================
-- STEP 4: Create user delivery staging table
-- ============================================================================

CREATE TABLE app.user_delivery_staging (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  week_start date NOT NULL DEFAULT app.current_addis_week(),
  address_label text DEFAULT 'Home',
  window_id text REFERENCES public.delivery_windows(id),
  staged_at timestamptz DEFAULT now(),
  UNIQUE(user_id, week_start)
);

-- ============================================================================
-- STEP 5: Create user week status table
-- ============================================================================

CREATE TABLE app.user_week_status (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  week_start date NOT NULL DEFAULT app.current_addis_week(),
  delivery_confirmed boolean DEFAULT false,
  confirmed_at timestamptz,
  address_label text DEFAULT 'Home',
  window_id text REFERENCES public.delivery_windows(id),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(user_id, week_start)
);

-- ============================================================================
-- STEP 6: Create weekly menu table
-- ============================================================================

CREATE TABLE public.weekly_menu (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  week_start date NOT NULL DEFAULT app.current_addis_week(),
  recipe_id uuid,
  title text NOT NULL,
  description text,
  price_cents integer NOT NULL,
  image_url text,
  is_available boolean DEFAULT true,
  sort_order integer DEFAULT 1,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- ============================================================================
-- STEP 7: Enable Row Level Security
-- ============================================================================

ALTER TABLE app.user_delivery_staging ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.user_week_status ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.delivery_windows ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.weekly_menu ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- STEP 8: Create RLS Policies
-- ============================================================================

-- User staging policies
DROP POLICY IF EXISTS "Users can manage their own staging" ON app.user_delivery_staging;
CREATE POLICY "Users can manage their own staging" ON app.user_delivery_staging
  FOR ALL USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- User week status policies  
DROP POLICY IF EXISTS "Users can manage their own week status" ON app.user_week_status;
CREATE POLICY "Users can manage their own week status" ON app.user_week_status
  FOR ALL USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- Public read for delivery windows
DROP POLICY IF EXISTS "Public read delivery windows" ON public.delivery_windows;
CREATE POLICY "Public read delivery windows" ON public.delivery_windows
  FOR SELECT TO anon, authenticated USING (is_active = true);

-- Public read for weekly menu
DROP POLICY IF EXISTS "Public read weekly menu" ON public.weekly_menu;
CREATE POLICY "Public read weekly menu" ON public.weekly_menu
  FOR SELECT TO anon, authenticated USING (is_available = true);

-- ============================================================================
-- STEP 9: Grant permissions
-- ============================================================================

GRANT USAGE ON SCHEMA app TO anon, authenticated;
GRANT ALL ON app.user_delivery_staging TO authenticated;
GRANT ALL ON app.user_week_status TO authenticated;
GRANT SELECT ON public.delivery_windows TO anon, authenticated;
GRANT SELECT ON public.weekly_menu TO anon, authenticated;

-- ============================================================================
-- STEP 10: Create views
-- ============================================================================

-- User profile view
CREATE OR REPLACE VIEW app.user_profile AS
SELECT 
  u.id,
  COALESCE(u.raw_user_meta_data->>'name', u.email) as name,
  u.raw_user_meta_data->>'phone' as phone,
  u.created_at
FROM auth.users u;

-- User delivery readiness view
CREATE OR REPLACE VIEW app.user_delivery_readiness AS
SELECT 
  COALESCE(uws.user_id, uds.user_id) as user_id,
  COALESCE(uws.week_start, uds.week_start) as week_start,
  COALESCE(uws.delivery_confirmed, false) as is_delivery_confirmed,
  uds.address_label as staged_address_label,
  uds.window_id as staged_window_id,
  uds.staged_at,
  uws.address_label as confirmed_address_label,
  uws.window_id as confirmed_window_id,
  uws.confirmed_at
FROM app.user_week_status uws
FULL OUTER JOIN app.user_delivery_staging uds 
  ON uws.user_id = uds.user_id AND uws.week_start = uds.week_start
WHERE (uws.user_id = auth.uid() OR uds.user_id = auth.uid())
  AND (uws.week_start = app.current_addis_week() OR uds.week_start = app.current_addis_week());

-- User delivery gate readiness view
CREATE OR REPLACE VIEW app.user_delivery_gate_readiness AS
SELECT 
  up.id,
  up.name,
  COALESCE(uds.address_label IS NOT NULL, false) as has_staged_address,
  COALESCE(uds.window_id IS NOT NULL, false) as has_staged_window,
  COALESCE(uws.delivery_confirmed, false) as is_delivery_confirmed,
  uds.address_label as staged_address_label,
  uds.window_id as staged_window_id,
  uds.staged_at,
  uws.address_label as confirmed_address_label,
  uws.window_id as confirmed_window_id,
  uws.confirmed_at
FROM app.user_profile up
LEFT JOIN app.user_delivery_staging uds ON up.id = uds.user_id AND uds.week_start = app.current_addis_week()
LEFT JOIN app.user_week_status uws ON up.id = uws.user_id AND uws.week_start = app.current_addis_week();

-- Grant permissions on views
GRANT SELECT ON app.user_profile TO anon, authenticated;
GRANT SELECT ON app.user_delivery_readiness TO authenticated;
GRANT SELECT ON app.user_delivery_gate_readiness TO authenticated;

-- ============================================================================
-- STEP 11: Create delivery functions
-- ============================================================================

-- Stage delivery choice function
CREATE OR REPLACE FUNCTION app.stage_delivery_choice(
  address_label text,
  window_id text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, app
AS $$
DECLARE
  current_user_id uuid := auth.uid();
  current_week date := app.current_addis_week();
BEGIN
  IF current_user_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'User not authenticated');
  END IF;

  -- Validate window exists and is active
  IF NOT EXISTS (SELECT 1 FROM public.delivery_windows WHERE id = window_id AND is_active = true) THEN
    RETURN jsonb_build_object('success', false, 'error', 'Invalid delivery window');
  END IF;

  INSERT INTO app.user_delivery_staging (user_id, week_start, address_label, window_id, staged_at)
  VALUES (current_user_id, current_week, address_label, window_id, now())
  ON CONFLICT (user_id, week_start) 
  DO UPDATE SET 
    address_label = EXCLUDED.address_label, 
    window_id = EXCLUDED.window_id, 
    staged_at = now();
  
  RETURN jsonb_build_object(
    'success', true, 
    'message', 'Choice staged successfully',
    'week_start', current_week,
    'address_label', address_label,
    'window_id', window_id
  );
END;
$$;

-- Confirm delivery choice function
CREATE OR REPLACE FUNCTION app.confirm_delivery_choice()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, app
AS $$
DECLARE
  current_user_id uuid := auth.uid();
  current_week date := app.current_addis_week();
  staging_record record;
BEGIN
  IF current_user_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'User not authenticated');
  END IF;

  -- Get staging data
  SELECT * INTO staging_record
  FROM app.user_delivery_staging
  WHERE user_id = current_user_id AND week_start = current_week;

  IF staging_record IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'No staged delivery choice found');
  END IF;

  -- Insert/update week status
  INSERT INTO app.user_week_status (user_id, week_start, delivery_confirmed, confirmed_at, address_label, window_id)
  VALUES (current_user_id, current_week, true, now(), staging_record.address_label, staging_record.window_id)
  ON CONFLICT (user_id, week_start) 
  DO UPDATE SET 
    delivery_confirmed = true, 
    confirmed_at = now(),
    address_label = EXCLUDED.address_label,
    window_id = EXCLUDED.window_id,
    updated_at = now();
  
  RETURN jsonb_build_object(
    'success', true, 
    'message', 'Delivery confirmed!',
    'week_start', current_week,
    'address_label', staging_record.address_label,
    'window_id', staging_record.window_id,
    'confirmed_at', now()
  );
END;
$$;

-- Get delivery windows function
CREATE OR REPLACE FUNCTION public.get_delivery_windows(
  p_city text DEFAULT 'Addis Ababa',
  p_include_past boolean DEFAULT false,
  p_limit integer DEFAULT 50
)
RETURNS TABLE (
  id text,
  label text,
  day_of_week text,
  start_time text,
  end_time text,
  has_capacity boolean,
  is_active boolean,
  max_orders integer,
  current_orders integer,
  city text,
  slot text,
  start_at timestamptz,
  end_at timestamptz,
  weekday text,
  week_start date,
  week_type text,
  has_available_capacity boolean,
  is_future_window boolean
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  current_week_date date := app.current_addis_week();
  next_week_date date := current_week_date + interval '7 days';
  now_utc timestamptz := now();
BEGIN
  RETURN QUERY
  WITH week_windows AS (
    SELECT 
      dw.id,
      (dw.day_of_week || ' ' || dw.start_time || '-' || dw.end_time) as label,
      dw.day_of_week,
      dw.start_time,
      dw.end_time,
      dw.has_capacity,
      dw.is_active,
      dw.max_orders,
      dw.current_orders,
      dw.city,
      dw.slot,
      (current_week_date + 
       CASE dw.day_of_week 
         WHEN 'Monday' THEN 0
         WHEN 'Tuesday' THEN 1
         WHEN 'Wednesday' THEN 2
         WHEN 'Thursday' THEN 3
         WHEN 'Friday' THEN 4
         WHEN 'Saturday' THEN 5
         WHEN 'Sunday' THEN 6
       END * interval '1 day' + 
       dw.start_time::time) as start_at,
      (current_week_date + 
       CASE dw.day_of_week 
         WHEN 'Monday' THEN 0
         WHEN 'Tuesday' THEN 1
         WHEN 'Wednesday' THEN 2
         WHEN 'Thursday' THEN 3
         WHEN 'Friday' THEN 4
         WHEN 'Saturday' THEN 5
         WHEN 'Sunday' THEN 6
       END * interval '1 day' + 
       dw.end_time::time) as end_at,
      current_week_date as week_start,
      'current' as week_type
    FROM public.delivery_windows dw
    WHERE dw.is_active = true 
      AND (p_city IS NULL OR dw.city = p_city)
    
    UNION ALL
    
    SELECT 
      dw.id || '_next',
      (dw.day_of_week || ' ' || dw.start_time || '-' || dw.end_time || ' (Next Week)') as label,
      dw.day_of_week,
      dw.start_time,
      dw.end_time,
      dw.has_capacity,
      dw.is_active,
      dw.max_orders,
      dw.current_orders,
      dw.city,
      dw.slot,
      (next_week_date + 
       CASE dw.day_of_week 
         WHEN 'Monday' THEN 0
         WHEN 'Tuesday' THEN 1
         WHEN 'Wednesday' THEN 2
         WHEN 'Thursday' THEN 3
         WHEN 'Friday' THEN 4
         WHEN 'Saturday' THEN 5
         WHEN 'Sunday' THEN 6
       END * interval '1 day' + 
       dw.start_time::time),
      (next_week_date + 
       CASE dw.day_of_week 
         WHEN 'Monday' THEN 0
         WHEN 'Tuesday' THEN 1
         WHEN 'Wednesday' THEN 2
         WHEN 'Thursday' THEN 3
         WHEN 'Friday' THEN 4
         WHEN 'Saturday' THEN 5
         WHEN 'Sunday' THEN 6
       END * interval '1 day' + 
       dw.end_time::time),
      next_week_date,
      'next'
    FROM public.delivery_windows dw
    WHERE dw.is_active = true 
      AND (p_city IS NULL OR dw.city = p_city)
  )
  SELECT 
    ww.id,
    ww.label,
    ww.day_of_week,
    ww.start_time,
    ww.end_time,
    ww.has_capacity,
    ww.is_active,
    ww.max_orders,
    ww.current_orders,
    ww.city,
    ww.slot,
    ww.start_at,
    ww.end_at,
    ww.day_of_week as weekday,
    ww.week_start,
    ww.week_type,
    (ww.current_orders < ww.max_orders) as has_available_capacity,
    (ww.start_at > now_utc) as is_future_window
  FROM week_windows ww
  WHERE ww.is_active = true
    AND (p_include_past OR ww.start_at > now_utc - interval '2 hours')
    AND (ww.current_orders < ww.max_orders)
  ORDER BY 
    ww.week_start, 
    CASE ww.day_of_week 
      WHEN 'Monday' THEN 1
      WHEN 'Tuesday' THEN 2
      WHEN 'Wednesday' THEN 3
      WHEN 'Thursday' THEN 4
      WHEN 'Friday' THEN 5
      WHEN 'Saturday' THEN 6
      WHEN 'Sunday' THEN 7
    END,
    ww.start_time
  LIMIT p_limit;
END;
$$;

-- Grant execute permissions on functions
GRANT EXECUTE ON FUNCTION app.stage_delivery_choice(text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION app.confirm_delivery_choice() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_delivery_windows(text, boolean, integer) TO anon, authenticated;

-- ============================================================================
-- STEP 12: Seed data
-- ============================================================================

-- Seed comprehensive delivery windows
INSERT INTO public.delivery_windows (id, label, day_of_week, start_time, end_time, city, is_active, max_orders, current_orders, slot) VALUES
-- Monday
('mon_morning', 'Monday Morning', 'Monday', '07:00', '09:30', 'Addis Ababa', true, 50, 0, 'Morning'),
('mon_noon', 'Monday Noon', 'Monday', '12:00', '14:30', 'Addis Ababa', true, 50, 0, 'Noon'),
('mon_afternoon', 'Monday Afternoon', 'Monday', '15:00', '18:30', 'Addis Ababa', true, 50, 0, 'Afternoon'),
-- Tuesday
('tue_morning', 'Tuesday Morning', 'Tuesday', '07:00', '09:30', 'Addis Ababa', true, 50, 0, 'Morning'),
('tue_noon', 'Tuesday Noon', 'Tuesday', '12:00', '14:30', 'Addis Ababa', true, 50, 0, 'Noon'),
('tue_afternoon', 'Tuesday Afternoon', 'Tuesday', '15:00', '18:30', 'Addis Ababa', true, 50, 0, 'Afternoon'),
-- Wednesday
('wed_morning', 'Wednesday Morning', 'Wednesday', '07:00', '09:30', 'Addis Ababa', true, 50, 0, 'Morning'),
('wed_noon', 'Wednesday Noon', 'Wednesday', '12:00', '14:30', 'Addis Ababa', true, 50, 0, 'Noon'),
('wed_afternoon', 'Wednesday Afternoon', 'Wednesday', '15:00', '18:30', 'Addis Ababa', true, 50, 0, 'Afternoon'),
-- Thursday
('thu_morning', 'Thursday Morning', 'Thursday', '07:00', '09:30', 'Addis Ababa', true, 50, 0, 'Morning'),
('thu_noon', 'Thursday Noon', 'Thursday', '12:00', '14:30', 'Addis Ababa', true, 50, 0, 'Noon'),
('thu_afternoon', 'Thursday Afternoon', 'Thursday', '15:00', '18:30', 'Addis Ababa', true, 50, 0, 'Afternoon'),
-- Friday
('fri_morning', 'Friday Morning', 'Friday', '07:00', '09:30', 'Addis Ababa', true, 50, 0, 'Morning'),
('fri_noon', 'Friday Noon', 'Friday', '12:00', '14:30', 'Addis Ababa', true, 50, 0, 'Noon'),
('fri_afternoon', 'Friday Afternoon', 'Friday', '15:00', '18:30', 'Addis Ababa', true, 50, 0, 'Afternoon'),
-- Saturday (Morning & Noon only)
('sat_morning', 'Saturday Morning', 'Saturday', '07:00', '09:30', 'Addis Ababa', true, 50, 0, 'Morning'),
('sat_noon', 'Saturday Noon', 'Saturday', '12:00', '14:30', 'Addis Ababa', true, 50, 0, 'Noon'),
-- Sunday (Morning & Noon only)
('sun_morning', 'Sunday Morning', 'Sunday', '07:00', '09:30', 'Addis Ababa', true, 50, 0, 'Morning'),
('sun_noon', 'Sunday Noon', 'Sunday', '12:00', '14:30', 'Addis Ababa', true, 50, 0, 'Noon')
ON CONFLICT (id) DO UPDATE SET
  label = EXCLUDED.label,
  day_of_week = EXCLUDED.day_of_week,
  start_time = EXCLUDED.start_time,
  end_time = EXCLUDED.end_time,
  city = EXCLUDED.city,
  is_active = EXCLUDED.is_active,
  max_orders = EXCLUDED.max_orders,
  slot = EXCLUDED.slot,
  updated_at = now();

-- Seed weekly menu data
INSERT INTO public.weekly_menu (title, description, price_cents, image_url, sort_order) VALUES
('Doro Wat', 'Traditional Ethiopian chicken stew with berbere spice', 1200, 'assets/images/doro-wat.jpg', 1),
('Injera Combo', 'Fresh injera with assorted vegetarian dishes', 800, 'assets/images/injera-combo.jpg', 2),
('Tibs Special', 'Sautéed beef with onions and peppers', 1500, 'assets/images/tibs-special.jpg', 3),
('Misir Wat', 'Red lentil stew with Ethiopian spices', 900, 'assets/images/misir-wat.jpg', 4),
('Kitfo', 'Minced raw beef with mitmita and niter kibbeh', 1800, 'assets/images/kitfo.jpg', 5),
('Shiro', 'Chickpea flour stew with berbere', 700, 'assets/images/shiro.jpg', 6),
('Gomen', 'Collard greens cooked with garlic and ginger', 600, 'assets/images/gomen.jpg', 7),
('Ayib', 'Fresh Ethiopian cottage cheese', 400, 'assets/images/ayib.jpg', 8)
ON CONFLICT DO NOTHING;

-- ============================================================================
-- STEP 13: Refresh PostgREST schema cache
-- ============================================================================

NOTIFY pgrst, 'reload schema';

-- ============================================================================
-- STEP 14: Verification queries
-- ============================================================================

SELECT 'SUCCESS: Delivery gate migration completed successfully' as status;
SELECT 'Delivery windows created: ' || COUNT(*) FROM public.delivery_windows;
SELECT 'Weekly menu items created: ' || COUNT(*) FROM public.weekly_menu;
SELECT 'Functions created: ' || 
  (SELECT COUNT(*) FROM pg_proc WHERE pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'app')) ||
  ' app functions, ' ||
  (SELECT COUNT(*) FROM pg_proc WHERE proname LIKE '%delivery%' AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')) ||
  ' public delivery functions';
SELECT 'Views created: ' || COUNT(*) FROM pg_views WHERE schemaname = 'app';

-- Show sample delivery windows
SELECT id, label, day_of_week, start_time, end_time, slot, has_capacity 
FROM public.delivery_windows 
WHERE is_active = true 
ORDER BY 
  CASE day_of_week 
    WHEN 'Monday' THEN 1
    WHEN 'Tuesday' THEN 2
    WHEN 'Wednesday' THEN 3
    WHEN 'Thursday' THEN 4
    WHEN 'Friday' THEN 5
    WHEN 'Saturday' THEN 6
    WHEN 'Sunday' THEN 7
  END,
  start_time
LIMIT 10;
