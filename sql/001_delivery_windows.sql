-- 001_delivery_windows.sql
-- Base table + seeds for Addis Ababa delivery slots

-- Create delivery_windows table
CREATE TABLE IF NOT EXISTS public.delivery_windows (
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

-- Create policy for public read (will be accessed via app.* views only)
CREATE POLICY "Public read delivery windows" ON public.delivery_windows
  FOR SELECT USING (is_active = true);

-- Seed Addis Ababa delivery slots
INSERT INTO public.delivery_windows (id, start_at, end_at, weekday, slot, city, capacity, booked_count, is_active)
SELECT 
  gen_random_uuid(),
  (date_trunc('week', now()) + interval '4 days' + interval '10 hours')::timestamptz,
  (date_trunc('week', now()) + interval '4 days' + interval '12 hours')::timestamptz,
  4, -- Thursday
  '10-12',
  'Addis Ababa',
  20,
  0,
  true
WHERE NOT EXISTS (
  SELECT 1 FROM public.delivery_windows 
  WHERE weekday = 4 AND slot = '10-12' AND city = 'Addis Ababa'
);

INSERT INTO public.delivery_windows (id, start_at, end_at, weekday, slot, city, capacity, booked_count, is_active)
SELECT 
  gen_random_uuid(),
  (date_trunc('week', now()) + interval '6 days' + interval '14 hours')::timestamptz,
  (date_trunc('week', now()) + interval '6 days' + interval '16 hours')::timestamptz,
  6, -- Saturday
  '14-16',
  'Addis Ababa',
  15,
  0,
  true
WHERE NOT EXISTS (
  SELECT 1 FROM public.delivery_windows 
  WHERE weekday = 6 AND slot = '14-16' AND city = 'Addis Ababa'
);

INSERT INTO public.delivery_windows (id, start_at, end_at, weekday, slot, city, capacity, booked_count, is_active)
SELECT 
  gen_random_uuid(),
  (date_trunc('week', now()) + interval '1 days' + interval '8 hours')::timestamptz,
  (date_trunc('week', now()) + interval '1 days' + interval '10 hours')::timestamptz,
  1, -- Monday
  '08-10',
  'Addis Ababa',
  15,
  0,
  true
WHERE NOT EXISTS (
  SELECT 1 FROM public.delivery_windows 
  WHERE weekday = 1 AND slot = '08-10' AND city = 'Addis Ababa'
);

INSERT INTO public.delivery_windows (id, start_at, end_at, weekday, slot, city, capacity, booked_count, is_active)
SELECT 
  gen_random_uuid(),
  (date_trunc('week', now()) + interval '3 days' + interval '18 hours')::timestamptz,
  (date_trunc('week', now()) + interval '3 days' + interval '20 hours')::timestamptz,
  3, -- Wednesday
  '18-20',
  'Addis Ababa',
  12,
  0,
  true
WHERE NOT EXISTS (
  SELECT 1 FROM public.delivery_windows 
  WHERE weekday = 3 AND slot = '18-20' AND city = 'Addis Ababa'
);






