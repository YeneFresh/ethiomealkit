-- 003_user_onboarding_state.sql
-- Track user onboarding flow progress

-- Create user_onboarding_state table
CREATE TABLE IF NOT EXISTS public.user_onboarding_state (
  user_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  stage text NOT NULL CHECK (stage IN ('box', 'auth', 'delivery', 'recipes', 'checkout', 'done')),
  plan_box_size int NOT NULL CHECK (plan_box_size IN (2, 4)),
  meals_per_week int NOT NULL CHECK (meals_per_week >= 3 AND meals_per_week <= 5),
  draft_window_id uuid REFERENCES public.delivery_windows(id),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.user_onboarding_state ENABLE ROW LEVEL SECURITY;

-- Create policy for user-specific access
CREATE POLICY "Users can manage their own onboarding state" ON public.user_onboarding_state
  FOR ALL USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());






