-- 002_user_active_window.sql
-- Upsert target for user's active delivery window

-- Create user_active_window table
CREATE TABLE IF NOT EXISTS public.user_active_window (
  user_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  window_id uuid NOT NULL REFERENCES public.delivery_windows(id),
  location_label text NOT NULL CHECK (location_label IN ('Home - Addis Ababa', 'Office - Addis Ababa')),
  created_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.user_active_window ENABLE ROW LEVEL SECURITY;

-- Create policy for user-specific access
CREATE POLICY "Users can manage their own active window" ON public.user_active_window
  FOR ALL USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());





