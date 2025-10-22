-- Create weekly_menu table that the app expects
-- This table links recipes to specific weeks

-- Create weekly_menu table
CREATE TABLE IF NOT EXISTS public.weekly_menu (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  week_start date NOT NULL,
  recipe_id uuid NOT NULL REFERENCES public.meals(id) ON DELETE CASCADE,
  is_available boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  UNIQUE(week_start, recipe_id)
);

-- Enable RLS
ALTER TABLE public.weekly_menu ENABLE ROW LEVEL SECURITY;

-- Create policy for public read access
DROP POLICY IF EXISTS "public read weekly menu" ON public.weekly_menu;
CREATE POLICY "public read weekly menu" ON public.weekly_menu 
FOR SELECT TO anon, authenticated 
USING (true);

-- Grant permissions
GRANT SELECT ON public.weekly_menu TO anon, authenticated;

-- Insert sample weekly menu data for current week
INSERT INTO public.weekly_menu (week_start, recipe_id) 
SELECT 
  date_trunc('week', CURRENT_DATE)::date as week_start,
  id as recipe_id
FROM public.meals
ON CONFLICT (week_start, recipe_id) DO NOTHING;

-- Create the RPC function that the app expects
CREATE OR REPLACE FUNCTION public.get_weekly_menu_current()
RETURNS TABLE (
  week_start date,
  recipes json
)
LANGUAGE sql
STABLE
AS $$
  SELECT 
    wm.week_start,
    json_build_object(
      'id', m.id,
      'slug', m.slug,
      'name', m.title,
      'categories', ARRAY[]::text[],
      'cook_minutes', 30,
      'hero_image', m.image_url
    ) as recipes
  FROM public.weekly_menu wm
  JOIN public.meals m ON wm.recipe_id = m.id
  WHERE wm.week_start = date_trunc('week', CURRENT_DATE)::date
    AND wm.is_available = true;
$$;

GRANT EXECUTE ON FUNCTION public.get_weekly_menu_current() TO anon, authenticated;

SELECT 'Weekly menu table and RPC created successfully' as status;







