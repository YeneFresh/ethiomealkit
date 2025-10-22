-- Update Database to Use All 15 Recipe Images
-- Run this in Supabase SQL Editor

-- Step 1: Clear existing data
DELETE FROM public.user_recipe_selections;
DELETE FROM public.recipes;

-- Step 2: Insert all 15 recipes
WITH current_week AS (
  SELECT id FROM public.weeks WHERE is_current = true LIMIT 1
)
INSERT INTO public.recipes (week_id, title, slug, image_url, tags, sort_order, is_active)
SELECT 
  cw.id,
  title,
  slug,
  image_url,
  tags,
  sort_order,
  true
FROM current_week cw
CROSS JOIN (VALUES
  (1,  'Alicha', 'alicha', 'assets/recipes/alicha.jpg', ARRAY['vegetarian', 'vegetables', 'mild']),
  (2,  'Atkilt', 'atkilt', 'assets/recipes/atkilt.jpg', ARRAY['vegetarian', 'cabbage', 'carrots', 'mild']),
  (3,  'Beyaynetu', 'beyaynetu', 'assets/recipes/beyaynetu.jpg', ARRAY['vegetarian', 'combo', 'variety']),
  (4,  'Doro Wat', 'doro-wat', 'assets/recipes/doro-wat.jpg', ARRAY['traditional', 'chicken', 'spicy', 'eggs']),
  (5,  'Dulet', 'dulet', 'assets/recipes/dulet.jpg', ARRAY['traditional', 'organ-meat', 'spicy']),
  (6,  'Firfir', 'firfir', 'assets/recipes/firfir.jpg', ARRAY['traditional', 'injera', 'spicy']),
  (7,  'Genfo', 'genfo', 'assets/recipes/genfo.jpg', ARRAY['vegetarian', 'porridge', 'breakfast']),
  (8,  'Gomen', 'gomen', 'assets/recipes/gomen.jpg', ARRAY['vegetarian', 'greens', 'mild']),
  (9,  'Injera with Beef Stew', 'injera-with-beef-stew', 'assets/recipes/injera-with-beef-stew.jpg', ARRAY['traditional', 'beef', 'spicy']),
  (10, 'Key Wat', 'key-wat', 'assets/recipes/key-wat.jpg', ARRAY['traditional', 'beef', 'spicy']),
  (11, 'Kitfo', 'kitfo', 'assets/recipes/kitfo.jpg', ARRAY['traditional', 'beef', 'raw', 'spicy']),
  (12, 'Misir Wat', 'misir-wat', 'assets/recipes/misir-wat.jpg', ARRAY['vegetarian', 'lentils', 'spicy']),
  (13, 'Shiro Wat', 'shiro-wat', 'assets/recipes/shiro-wat.jpg', ARRAY['vegetarian', 'chickpea', 'mild']),
  (14, 'Tibs', 'tibs', 'assets/recipes/tibs.jpg', ARRAY['traditional', 'beef', 'vegetables', 'mild']),
  (15, 'Zilzil Tibs', 'zilzil-tibs', 'assets/recipes/zilzil-tibs.jpg', ARRAY['traditional', 'beef', 'spicy'])
) AS r(sort_order, title, slug, image_url, tags);

-- Step 3: Verify
SELECT COUNT(*) as total_recipes FROM public.recipes;
