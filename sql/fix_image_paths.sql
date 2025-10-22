-- Fix Image Paths in Recipes Table
-- Removes double-slash issue: assets//images/... → assets/recipes/...

-- 1. Update any paths with /images/ to recipes/
UPDATE public.recipes
SET image_url = 'assets/recipes/' || slug || '.jpg'
WHERE image_url LIKE '%/images/%' OR image_url NOT LIKE 'assets/recipes/%';

-- 2. Verify the fix
DO $$
DECLARE
  bad_paths int;
  good_paths int;
BEGIN
  SELECT COUNT(*) INTO bad_paths FROM public.recipes 
  WHERE image_url LIKE '%//%' OR image_url LIKE '/images/%';
  
  SELECT COUNT(*) INTO good_paths FROM public.recipes 
  WHERE image_url LIKE 'assets/recipes/%' AND image_url NOT LIKE '%//%';
  
  RAISE NOTICE '🔧 Fixed image paths: % recipes with correct paths, % with issues',
    good_paths, bad_paths;
  
  IF bad_paths > 0 THEN
    RAISE WARNING 'Still have % recipes with bad paths!', bad_paths;
  ELSE
    RAISE NOTICE '✅ All image paths correct!';
  END IF;
END $$;

-- 3. Show sample
SELECT id, title, slug, image_url 
FROM public.recipes 
ORDER BY sort_order 
LIMIT 5;




