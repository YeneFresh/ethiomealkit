-- 004_user_recipe_selections.sql
-- Track user recipe selections with plan allowance

-- Create weeks table first
CREATE TABLE IF NOT EXISTS public.weeks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  week_start date NOT NULL UNIQUE,
  is_current boolean NOT NULL DEFAULT false,
  created_at timestamptz DEFAULT now()
);

-- Create recipes table
CREATE TABLE IF NOT EXISTS public.recipes (
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
CREATE TABLE IF NOT EXISTS public.user_recipe_selections (
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
CREATE POLICY "Public read weeks" ON public.weeks
  FOR SELECT USING (true);

CREATE POLICY "Public read recipes" ON public.recipes
  FOR SELECT USING (is_active = true);

CREATE POLICY "Users can manage their own recipe selections" ON public.user_recipe_selections
  FOR ALL USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- Seed current week
INSERT INTO public.weeks (id, week_start, is_current)
SELECT 
  gen_random_uuid(),
  date_trunc('week', now())::date,
  true
WHERE NOT EXISTS (
  SELECT 1 FROM public.weeks WHERE is_current = true
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
WHERE NOT EXISTS (
  SELECT 1 FROM public.recipes WHERE slug = 'injera-beef-stew'
);

WITH current_week AS (
  SELECT id FROM public.weeks WHERE is_current = true LIMIT 1
)
INSERT INTO public.recipes (id, week_id, title, slug, image_url, tags, sort_order, is_active)
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
WHERE NOT EXISTS (
  SELECT 1 FROM public.recipes WHERE slug = 'doro-wat'
);

WITH current_week AS (
  SELECT id FROM public.weeks WHERE is_current = true LIMIT 1
)
INSERT INTO public.recipes (id, week_id, title, slug, image_url, tags, sort_order, is_active)
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
WHERE NOT EXISTS (
  SELECT 1 FROM public.recipes WHERE slug = 'kitfo'
);

WITH current_week AS (
  SELECT id FROM public.weeks WHERE is_current = true LIMIT 1
)
INSERT INTO public.recipes (id, week_id, title, slug, image_url, tags, sort_order, is_active)
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
WHERE NOT EXISTS (
  SELECT 1 FROM public.recipes WHERE slug = 'shiro-wat'
);

WITH current_week AS (
  SELECT id FROM public.weeks WHERE is_current = true LIMIT 1
)
INSERT INTO public.recipes (id, week_id, title, slug, image_url, tags, sort_order, is_active)
SELECT 
  gen_random_uuid(),
  cw.id,
  'Tibs',
  'tibs',
  '/images/tibs.jpg',
  ARRAY['traditional', 'beef', 'vegetables', 'mild'],
  5,
  true
FROM current_week cw
WHERE NOT EXISTS (
  SELECT 1 FROM public.recipes WHERE slug = 'tibs'
);






