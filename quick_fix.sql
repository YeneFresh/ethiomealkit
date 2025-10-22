-- Quick fix for weekly_menu permission issue
-- Disable RLS temporarily to allow access

ALTER TABLE public.weekly_menu DISABLE ROW LEVEL SECURITY;

-- Grant all necessary permissions
GRANT ALL ON public.weekly_menu TO anon, authenticated;
GRANT ALL ON public.meals TO anon, authenticated;
GRANT ALL ON public.meal_kits TO anon, authenticated;
GRANT ALL ON public.delivery_windows TO anon, authenticated;

-- Grant usage on schema
GRANT USAGE ON SCHEMA public TO anon, authenticated;

SELECT 'Quick permissions fix applied' as status;







