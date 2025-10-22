-- Complete Delivery Gate Migration (Final Fix)
-- Run this in Supabase SQL Editor to restore full delivery gate functionality

-- Step 1: Identify and drop the conflicting user_profile object
-- We'll use a more aggressive approach to handle the naming conflict

-- Drop views first
DROP VIEW IF EXISTS app.user_delivery_gate_readiness CASCADE;
DROP VIEW IF EXISTS app.user_delivery_readiness CASCADE;

-- Try to drop user_profile as both view and table
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

-- Drop any other conflicting objects
DROP VIEW IF EXISTS app.user_selections CASCADE;
DROP TABLE IF EXISTS app.user_profiles CASCADE;
DROP TABLE IF EXISTS app.user_delivery_staging CASCADE;
DROP TABLE IF EXISTS app.user_week_status CASCADE;
DROP TABLE IF EXISTS app.user_selections CASCADE;
DROP TABLE IF EXISTS app.user_delivery_selections CASCADE;
DROP TABLE IF EXISTS public.delivery_windows CASCADE;

-- Drop functions
DROP FUNCTION IF EXISTS app.stage_delivery_choice CASCADE;
DROP FUNCTION IF EXISTS app.confirm_delivery_choice CASCADE;
DROP FUNCTION IF EXISTS public.get_delivery_windows CASCADE;
DROP FUNCTION IF EXISTS app.current_addis_week CASCADE;

-- Create app schema if not exists
CREATE SCHEMA IF NOT EXISTS app;

-- Create app.current_addis_week function
CREATE OR REPLACE FUNCTION app.current_addis_week()
RETURNS date
LANGUAGE plpgsql
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

-- Create delivery_windows table
CREATE TABLE public.delivery_windows (
  id text PRIMARY KEY,
  day_of_week text NOT NULL,
  start_time text NOT NULL,
  end_time text NOT NULL,
  start_at timestamptz,
  end_at timestamptz,
  city text DEFAULT 'Addis Ababa',
  is_active boolean DEFAULT true,
  max_orders integer DEFAULT 50,
  current_orders integer DEFAULT 0,
  has_capacity boolean DEFAULT true,
  slot text NOT NULL
);

-- Create app tables with completely unique names
CREATE TABLE app.delivery_user_profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name text,
  phone text,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE app.delivery_staging (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  staged_address_label text,
  staged_window_id text,
  staged_at timestamptz DEFAULT now()
);

CREATE TABLE app.delivery_week_status (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  week_start date DEFAULT app.current_addis_week(),
  is_delivery_confirmed boolean DEFAULT false,
  confirmed_at timestamptz,
  updated_at timestamptz DEFAULT now()
);

CREATE TABLE app.delivery_user_selections (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  selected_address_label text,
  selected_window_id text,
  week_start date DEFAULT app.current_addis_week(),
  confirmed_at timestamptz DEFAULT now()
);

-- Insert comprehensive delivery windows data (19 windows)
INSERT INTO public.delivery_windows (id, day_of_week, start_time, end_time, city, is_active, max_orders, current_orders, slot) VALUES
-- Monday
('mon_morning', 'Monday', '07:00', '09:30', 'Addis Ababa', true, 50, 0, 'Morning'),
('mon_noon', 'Monday', '12:00', '14:30', 'Addis Ababa', true, 50, 0, 'Noon'),
('mon_afternoon', 'Monday', '15:00', '18:30', 'Addis Ababa', true, 50, 0, 'Afternoon'),
-- Tuesday
('tue_morning', 'Tuesday', '07:00', '09:30', 'Addis Ababa', true, 50, 0, 'Morning'),
('tue_noon', 'Tuesday', '12:00', '14:30', 'Addis Ababa', true, 50, 0, 'Noon'),
('tue_afternoon', 'Tuesday', '15:00', '18:30', 'Addis Ababa', true, 50, 0, 'Afternoon'),
-- Wednesday
('wed_morning', 'Wednesday', '07:00', '09:30', 'Addis Ababa', true, 50, 0, 'Morning'),
('wed_noon', 'Wednesday', '12:00', '14:30', 'Addis Ababa', true, 50, 0, 'Noon'),
('wed_afternoon', 'Wednesday', '15:00', '18:30', 'Addis Ababa', true, 50, 0, 'Afternoon'),
-- Thursday
('thu_morning', 'Thursday', '07:00', '09:30', 'Addis Ababa', true, 50, 0, 'Morning'),
('thu_noon', 'Thursday', '12:00', '14:30', 'Addis Ababa', true, 50, 0, 'Noon'),
('thu_afternoon', 'Thursday', '15:00', '18:30', 'Addis Ababa', true, 50, 0, 'Afternoon'),
-- Friday
('fri_morning', 'Friday', '07:00', '09:30', 'Addis Ababa', true, 50, 0, 'Morning'),
('fri_noon', 'Friday', '12:00', '14:30', 'Addis Ababa', true, 50, 0, 'Noon'),
('fri_afternoon', 'Friday', '15:00', '18:30', 'Addis Ababa', true, 50, 0, 'Afternoon'),
-- Saturday (Morning & Noon only)
('sat_morning', 'Saturday', '07:00', '09:30', 'Addis Ababa', true, 50, 0, 'Morning'),
('sat_noon', 'Saturday', '12:00', '14:30', 'Addis Ababa', true, 50, 0, 'Noon'),
-- Sunday (Morning & Noon only)
('sun_morning', 'Sunday', '07:00', '09:30', 'Addis Ababa', true, 50, 0, 'Morning'),
('sun_noon', 'Sunday', '12:00', '14:30', 'Addis Ababa', true, 50, 0, 'Noon');

-- Create get_delivery_windows RPC function
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

-- Create stage_delivery_choice RPC function
CREATE OR REPLACE FUNCTION app.stage_delivery_choice(
  p_address_label text,
  p_window_id text
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, app
AS $$
DECLARE
  current_user_id uuid := auth.uid();
  result json;
BEGIN
  IF current_user_id IS NULL THEN
    RAISE EXCEPTION 'User not authenticated';
  END IF;

  -- Upsert staging record
  INSERT INTO app.delivery_staging (id, staged_address_label, staged_window_id, staged_at)
  VALUES (current_user_id, p_address_label, p_window_id, now())
  ON CONFLICT (id) 
  DO UPDATE SET 
    staged_address_label = p_address_label,
    staged_window_id = p_window_id,
    staged_at = now();

  result := json_build_object(
    'success', true,
    'address_label', p_address_label,
    'window_id', p_window_id,
    'staged_at', now()
  );

  RETURN result;
END;
$$;

-- Create confirm_delivery_choice RPC function
CREATE OR REPLACE FUNCTION app.confirm_delivery_choice()
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, app
AS $$
DECLARE
  current_user_id uuid := auth.uid();
  staging_record record;
  current_week date := app.current_addis_week();
  result json;
BEGIN
  IF current_user_id IS NULL THEN
    RAISE EXCEPTION 'User not authenticated';
  END IF;

  -- Get staging data
  SELECT * INTO staging_record
  FROM app.delivery_staging 
  WHERE id = current_user_id;

  IF staging_record IS NULL THEN
    RAISE EXCEPTION 'No staged delivery choice found';
  END IF;

  -- Upsert delivery_user_selections
  INSERT INTO app.delivery_user_selections (id, selected_address_label, selected_window_id, week_start, confirmed_at)
  VALUES (current_user_id, staging_record.staged_address_label, staging_record.staged_window_id, current_week, now())
  ON CONFLICT (id) 
  DO UPDATE SET 
    selected_address_label = staging_record.staged_address_label,
    selected_window_id = staging_record.staged_window_id,
    week_start = current_week,
    confirmed_at = now();

  -- Upsert delivery_week_status
  INSERT INTO app.delivery_week_status (id, week_start, is_delivery_confirmed, confirmed_at, updated_at)
  VALUES (current_user_id, current_week, true, now(), now())
  ON CONFLICT (id) 
  DO UPDATE SET 
    week_start = current_week,
    is_delivery_confirmed = true,
    confirmed_at = now(),
    updated_at = now();

  result := json_build_object(
    'success', true,
    'address_label', staging_record.staged_address_label,
    'window_id', staging_record.staged_window_id,
    'week_start', current_week,
    'confirmed_at', now()
  );

  RETURN result;
END;
$$;

-- Create views with completely unique names
CREATE VIEW app.user_profile AS
SELECT 
  u.id,
  COALESCE(up.name, u.email) as name,
  up.phone,
  u.created_at
FROM auth.users u
LEFT JOIN app.delivery_user_profiles up ON u.id = up.id;

CREATE VIEW app.user_delivery_readiness AS
SELECT 
  up.id,
  up.name,
  us.selected_address_label,
  us.selected_window_id,
  us.week_start,
  us.confirmed_at,
  uws.is_delivery_confirmed,
  COALESCE(us.selected_address_label IS NOT NULL AND us.selected_window_id IS NOT NULL, false) as has_delivery_selection,
  COALESCE(uws.is_delivery_confirmed, false) as is_confirmed
FROM app.user_profile up
LEFT JOIN app.delivery_user_selections us ON up.id = us.id
LEFT JOIN app.delivery_week_status uws ON up.id = uws.id;

CREATE VIEW app.user_delivery_gate_readiness AS
SELECT 
  up.id,
  up.name,
  COALESCE(uds.staged_address_label IS NOT NULL, false) as has_staged_address,
  COALESCE(uds.staged_window_id IS NOT NULL, false) as has_staged_window,
  COALESCE(uws.is_delivery_confirmed, false) as is_delivery_confirmed,
  uds.staged_address_label,
  uds.staged_window_id,
  us.selected_address_label,
  us.selected_window_id,
  us.week_start as selection_week_start,
  uws.week_start as status_week_start
FROM app.user_profile up
LEFT JOIN app.delivery_staging uds ON up.id = uds.id
LEFT JOIN app.delivery_user_selections us ON up.id = us.id
LEFT JOIN app.delivery_week_status uws ON up.id = uws.id;

-- Set up RLS policies
ALTER TABLE app.delivery_user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.delivery_staging ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.delivery_week_status ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.delivery_user_selections ENABLE ROW LEVEL SECURITY;

-- RLS policies
CREATE POLICY "Users can view own profile" ON app.delivery_user_profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON app.delivery_user_profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile" ON app.delivery_user_profiles FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can manage own staging" ON app.delivery_staging FOR ALL USING (auth.uid() = id);
CREATE POLICY "Users can manage own week status" ON app.delivery_week_status FOR ALL USING (auth.uid() = id);
CREATE POLICY "Users can manage own selections" ON app.delivery_user_selections FOR ALL USING (auth.uid() = id);

-- Grant permissions
GRANT EXECUTE ON FUNCTION public.get_delivery_windows(text, boolean, integer) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION app.stage_delivery_choice(text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION app.confirm_delivery_choice() TO authenticated;
GRANT EXECUTE ON FUNCTION app.current_addis_week() TO anon, authenticated;

GRANT USAGE ON SCHEMA app TO anon, authenticated;
GRANT SELECT ON app.user_profile TO anon, authenticated;
GRANT SELECT ON app.user_delivery_readiness TO anon, authenticated;
GRANT SELECT ON app.user_delivery_gate_readiness TO anon, authenticated;

-- Refresh PostgREST schema cache
NOTIFY pgrst, 'reload schema';




