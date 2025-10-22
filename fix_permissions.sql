-- Fix permissions for weekly_menu table
-- Grant necessary permissions to anon and authenticated roles

-- Grant SELECT permissions on weekly_menu table
GRANT SELECT ON public.weekly_menu TO anon, authenticated;

-- Enable RLS on weekly_menu if not already enabled
ALTER TABLE public.weekly_menu ENABLE ROW LEVEL SECURITY;

-- Create a policy to allow public read access to weekly_menu
DROP POLICY IF EXISTS "Allow public read access to weekly menu" ON public.weekly_menu;
CREATE POLICY "Allow public read access to weekly menu" 
ON public.weekly_menu FOR SELECT 
TO anon, authenticated 
USING (true);

-- Also grant permissions on related tables that might be needed
GRANT SELECT ON public.recipes TO anon, authenticated;
GRANT SELECT ON public.meal_kits TO anon, authenticated;

-- Enable RLS and create policies for recipes
ALTER TABLE public.recipes ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow public read access to recipes" ON public.recipes;
CREATE POLICY "Allow public read access to recipes" 
ON public.recipes FOR SELECT 
TO anon, authenticated 
USING (true);

-- Check if meal_kits table exists and grant permissions
DO $$
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'meal_kits' AND table_schema = 'public') THEN
        EXECUTE 'ALTER TABLE public.meal_kits ENABLE ROW LEVEL SECURITY';
        EXECUTE 'DROP POLICY IF EXISTS "Allow public read access to meal_kits" ON public.meal_kits';
        EXECUTE 'CREATE POLICY "Allow public read access to meal_kits" ON public.meal_kits FOR SELECT TO anon, authenticated USING (true)';
    END IF;
END $$;

SELECT 'Permissions fixed for weekly_menu and related tables' as status;







