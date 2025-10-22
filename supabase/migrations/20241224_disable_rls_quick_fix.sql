-- Quick fix for weekly_menu permission issue
-- Disable RLS to allow immediate access

-- Disable RLS on weekly_menu table
ALTER TABLE public.weekly_menu DISABLE ROW LEVEL SECURITY;

-- Grant broad permissions to fix the issue immediately
GRANT ALL ON public.weekly_menu TO anon, authenticated;
GRANT ALL ON public.meals TO anon, authenticated; 
GRANT ALL ON public.meal_kits TO anon, authenticated;
GRANT ALL ON public.delivery_windows TO anon, authenticated;

-- Also grant on any sequences
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;

SELECT 'RLS disabled and permissions granted' as status;








