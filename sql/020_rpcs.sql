-- 020_rpcs.sql
-- Create/replace all RPCs (onboarding, upsert window, toggle recipe, user_selections)

-- 1. Current Addis Week Function
CREATE OR REPLACE FUNCTION app.current_addis_week()
RETURNS date
LANGUAGE sql
STABLE
AS $$
  SELECT date_trunc('week', now())::date;
$$;

-- 2. User Selections RPC
CREATE OR REPLACE FUNCTION app.user_selections()
RETURNS TABLE(
  recipe_id uuid,
  week_start date,
  box_size int,
  selected boolean
)
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  WITH current_week AS (
    SELECT id, week_start FROM public.weeks WHERE is_current = true LIMIT 1
  ),
  user_onboarding AS (
    SELECT plan_box_size FROM public.user_onboarding_state WHERE user_id = auth.uid()
  ),
  weekly_recipes AS (
    SELECT r.id, cw.week_start
    FROM current_week cw
    JOIN public.recipes r ON r.week_id = cw.id AND r.is_active = true
  )
  SELECT 
    wr.recipe_id,
    wr.week_start,
    COALESCE(uo.plan_box_size, 2) AS box_size,
    COALESCE(urs.selected, false) AS selected
  FROM weekly_recipes wr
  CROSS JOIN user_onboarding uo
  LEFT JOIN public.user_recipe_selections urs ON urs.recipe_id = wr.recipe_id 
    AND urs.user_id = auth.uid() AND urs.week_start = wr.week_start
  ORDER BY wr.recipe_id;
$$;

-- 3. Upsert User Active Window RPC
CREATE OR REPLACE FUNCTION app.upsert_user_active_window(
  window_id uuid,
  location_label text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO public.user_active_window (user_id, window_id, location_label)
  VALUES (auth.uid(), window_id, location_label)
  ON CONFLICT (user_id) 
  DO UPDATE SET 
    window_id = EXCLUDED.window_id,
    location_label = EXCLUDED.location_label,
    created_at = now();
END;
$$;

-- 4. Set Onboarding Plan RPC
CREATE OR REPLACE FUNCTION app.set_onboarding_plan(
  box_size int,
  meals_per_week int
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO public.user_onboarding_state (user_id, stage, plan_box_size, meals_per_week)
  VALUES (auth.uid(), 'box', box_size, meals_per_week)
  ON CONFLICT (user_id)
  DO UPDATE SET 
    plan_box_size = EXCLUDED.plan_box_size,
    meals_per_week = EXCLUDED.meals_per_week,
    stage = 'box',
    updated_at = now();
END;
$$;

-- 5. Toggle Recipe Selection RPC
CREATE OR REPLACE FUNCTION app.toggle_recipe_selection(
  recipe_id uuid,
  select_recipe boolean
)
RETURNS TABLE(
  total_selected int,
  remaining int,
  allowed int,
  ok boolean
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  current_week_start date;
  user_plan int;
  current_selected int;
  new_selected int;
BEGIN
  -- Get current week
  SELECT week_start INTO current_week_start FROM public.weeks WHERE is_current = true LIMIT 1;
  
  -- Get user's plan (meals per week)
  SELECT meals_per_week INTO user_plan FROM public.user_onboarding_state WHERE user_id = auth.uid();
  
  -- Get current selection count
  SELECT COUNT(*) INTO current_selected 
  FROM public.user_recipe_selections 
  WHERE user_id = auth.uid() AND week_start = current_week_start AND selected = true;
  
  -- Calculate new selection count
  new_selected := current_selected + CASE WHEN select_recipe THEN 1 ELSE -1 END;
  
  -- Check if selection is valid
  IF new_selected < 0 OR new_selected > user_plan THEN
    -- Return current state with ok = false
    SELECT current_selected, (user_plan - current_selected), user_plan, false
    INTO total_selected, remaining, allowed, ok;
    RETURN;
  END IF;
  
  -- Update or insert selection
  INSERT INTO public.user_recipe_selections (user_id, recipe_id, week_start, selected)
  VALUES (auth.uid(), recipe_id, current_week_start, select_recipe)
  ON CONFLICT (user_id, recipe_id, week_start)
  DO UPDATE SET selected = select_recipe;
  
  -- Return new state
  SELECT new_selected, (user_plan - new_selected), user_plan, true
  INTO total_selected, remaining, allowed, ok;
  
  RETURN;
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION app.current_addis_week() TO anon, authenticated;
GRANT EXECUTE ON FUNCTION app.user_selections() TO anon, authenticated;
GRANT EXECUTE ON FUNCTION app.upsert_user_active_window(uuid, text) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION app.set_onboarding_plan(int, int) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION app.toggle_recipe_selection(uuid, boolean) TO anon, authenticated;






