-- 15 Ethiopian Recipes Seed Data
-- Run this AFTER the main migration
-- Images should be placed in assets/recipes/ matching the slug names

WITH current_week AS (
  SELECT id FROM public.weeks WHERE is_current = true LIMIT 1
)
INSERT INTO public.recipes (week_id, title, slug, image_url, tags, sort_order, is_active)
SELECT cw.id, title, slug, image_url, tags, sort_order, true
FROM current_week cw
CROSS JOIN (VALUES
  -- Sort order 1-15 for stable UI presentation
  (1, 'Doro Wat', 'doro-wat', 'assets/recipes/doro-wat.jpg', 
   ARRAY['traditional', 'chicken', 'spicy', 'eggs']),
  (2, 'Kitfo', 'kitfo', 'assets/recipes/kitfo.jpg', 
   ARRAY['traditional', 'beef', 'raw', 'spicy']),
  (3, 'Shiro Wat', 'shiro-wat', 'assets/recipes/shiro-wat.jpg', 
   ARRAY['vegetarian', 'chickpea', 'mild']),
  (4, 'Tibs', 'tibs', 'assets/recipes/tibs.jpg', 
   ARRAY['traditional', 'beef', 'vegetables', 'mild']),
  (5, 'Injera with Beef Stew', 'injera-with-beef-stew', 'assets/recipes/injera-with-beef-stew.jpg', 
   ARRAY['traditional', 'beef', 'spicy']),
  (6, 'Gomen', 'gomen', 'assets/recipes/gomen.jpg', 
   ARRAY['vegetarian', 'greens', 'mild']),
  (7, 'Misir Wat', 'misir-wat', 'assets/recipes/misir-wat.jpg', 
   ARRAY['vegetarian', 'lentils', 'spicy']),
  (8, 'Alicha', 'alicha', 'assets/recipes/alicha.jpg', 
   ARRAY['vegetarian', 'vegetables', 'mild']),
  (9, 'Firfir', 'firfir', 'assets/recipes/firfir.jpg', 
   ARRAY['traditional', 'injera', 'spicy']),
  (10, 'Genfo', 'genfo', 'assets/recipes/genfo.jpg', 
   ARRAY['vegetarian', 'porridge', 'breakfast']),
  (11, 'Dulet', 'dulet', 'assets/recipes/dulet.jpg', 
   ARRAY['traditional', 'organ-meat', 'spicy']),
  (12, 'Zilzil Tibs', 'zilzil-tibs', 'assets/recipes/zilzil-tibs.jpg', 
   ARRAY['traditional', 'beef', 'spicy']),
  (13, 'Key Wat', 'key-wat', 'assets/recipes/key-wat.jpg', 
   ARRAY['traditional', 'beef', 'spicy']),
  (14, 'Atkilt', 'atkilt', 'assets/recipes/atkilt.jpg', 
   ARRAY['vegetarian', 'vegetables', 'mild']),
  (15, 'Beyaynetu', 'beyaynetu', 'assets/recipes/beyaynetu.jpg', 
   ARRAY['vegetarian', 'combo', 'variety'])
) AS recipes(sort_order, title, slug, image_url, tags)
ON CONFLICT (slug) DO NOTHING;

-- Verify count
DO $$
DECLARE
  recipe_count int;
BEGIN
  SELECT COUNT(*) INTO recipe_count FROM public.recipes;
  RAISE NOTICE '✅ Total recipes: % (expected: 15)', recipe_count;
  
  IF recipe_count != 15 THEN
    RAISE WARNING 'Expected 15 recipes, found %', recipe_count;
  END IF;
END $$;

