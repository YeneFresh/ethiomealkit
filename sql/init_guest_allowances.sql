-- Initialize Guest User Onboarding State
-- Fixes "0/0 selected" by creating onboarding state with meals_per_week

-- Create default onboarding state for users who don't have one
-- This provides the "allowed" count for recipe selection
INSERT INTO public.user_onboarding_state (user_id, stage, plan_box_size, meals_per_week)
SELECT 
  auth.users.id,
  'recipes',  -- Set to recipes stage since they're selecting now
  4,  -- Default 4-person box
  4   -- Default 4 meals per week
FROM auth.users
WHERE auth.users.id NOT IN (
  SELECT user_id FROM public.user_onboarding_state
)
ON CONFLICT (user_id) DO NOTHING;

-- Verify
DO $$
DECLARE
  total_users int;
  users_with_onboarding int;
BEGIN
  SELECT COUNT(*) INTO total_users FROM auth.users;
  SELECT COUNT(*) INTO users_with_onboarding 
  FROM public.user_onboarding_state;
  
  RAISE NOTICE '👥 Total users: %', total_users;
  RAISE NOTICE '✅ Users with onboarding state: %', users_with_onboarding;
  
  IF users_with_onboarding < total_users THEN
    RAISE WARNING '⚠️ % users still missing onboarding state!', 
      total_users - users_with_onboarding;
  ELSE
    RAISE NOTICE '✅ All users initialized!';
  END IF;
END $$;

-- Show sample with meals_per_week (the "allowed" count)
SELECT u.id, u.email, o.stage, o.plan_box_size, o.meals_per_week as allowed
FROM auth.users u
LEFT JOIN public.user_onboarding_state o ON u.id = o.user_id
LIMIT 5;
