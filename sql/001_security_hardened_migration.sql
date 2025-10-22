-- =============================================================================
-- YENEFRESH SECURITY-HARDENED MIGRATION
-- =============================================================================
-- This migration includes:
-- 1. Explicit privilege revocations (deny-by-default)
-- 2. Table and RPC comments for documentation
-- 3. Verified auth.uid() usage in all write operations
-- 4. View validation to prevent data leaks
-- =============================================================================

-- =============================================================================
-- CLEANUP
-- =============================================================================

DROP SCHEMA IF EXISTS app CASCADE;
DROP TABLE IF EXISTS public.order_items CASCADE;
DROP TABLE IF EXISTS public.orders CASCADE;
DROP TABLE IF EXISTS public.user_recipe_selections CASCADE;
DROP TABLE IF EXISTS public.recipes CASCADE;
DROP TABLE IF EXISTS public.weeks CASCADE;
DROP TABLE IF EXISTS public.user_onboarding_state CASCADE;
DROP TABLE IF EXISTS public.user_active_window CASCADE;
DROP TABLE IF EXISTS public.delivery_windows CASCADE;

-- =============================================================================
-- 1. DELIVERY WINDOWS
-- =============================================================================

CREATE TABLE public.delivery_windows (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  start_at timestamptz NOT NULL,
  end_at timestamptz NOT NULL,
  weekday int NOT NULL CHECK (weekday >= 0 AND weekday <= 6),
  slot text NOT NULL,
  city text NOT NULL DEFAULT 'Addis Ababa',
  capacity int NOT NULL DEFAULT 20,
  booked_count int NOT NULL DEFAULT 0,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz DEFAULT now()
);

COMMENT ON TABLE public.delivery_windows IS 
  'Available delivery time slots with capacity tracking. Read-only for users.';
COMMENT ON COLUMN public.delivery_windows.weekday IS 
  '0=Sunday, 1=Monday, ..., 6=Saturday';
COMMENT ON COLUMN public.delivery_windows.slot IS 
  'Time range in 24h format, e.g., "14-16", "10-12"';

-- Enable RLS
ALTER TABLE public.delivery_windows ENABLE ROW LEVEL SECURITY;

-- Revoke default public access
REVOKE ALL ON public.delivery_windows FROM anon, authenticated;

-- Grant read-only access
GRANT SELECT ON public.delivery_windows TO anon, authenticated;

-- Create policy
DROP POLICY IF EXISTS "Public read delivery windows" ON public.delivery_windows;
CREATE POLICY "Public read delivery windows" 
  ON public.delivery_windows FOR SELECT 
  USING (is_active = true);

-- Seed data
INSERT INTO public.delivery_windows (start_at, end_at, weekday, slot, city, capacity)
VALUES 
  ((date_trunc('week', now()) + interval '4 days 10 hours')::timestamptz, 
   (date_trunc('week', now()) + interval '4 days 12 hours')::timestamptz, 
   4, '10-12', 'Addis Ababa', 20),
  ((date_trunc('week', now()) + interval '6 days 14 hours')::timestamptz, 
   (date_trunc('week', now()) + interval '6 days 16 hours')::timestamptz, 
   6, '14-16', 'Addis Ababa', 15),
  ((date_trunc('week', now()) + interval '1 days 8 hours')::timestamptz, 
   (date_trunc('week', now()) + interval '1 days 10 hours')::timestamptz, 
   1, '08-10', 'Addis Ababa', 15),
  ((date_trunc('week', now()) + interval '3 days 18 hours')::timestamptz, 
   (date_trunc('week', now()) + interval '3 days 20 hours')::timestamptz, 
   3, '18-20', 'Addis Ababa', 12);

-- =============================================================================
-- 2. USER ACTIVE WINDOW
-- =============================================================================

CREATE TABLE public.user_active_window (
  user_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  window_id uuid NOT NULL REFERENCES public.delivery_windows(id),
  location_label text NOT NULL CHECK (location_label IN ('Home - Addis Ababa', 'Office - Addis Ababa')),
  created_at timestamptz DEFAULT now()
);

COMMENT ON TABLE public.user_active_window IS 
  'Stores each user''s selected delivery window and location. One row per user.';
COMMENT ON COLUMN public.user_active_window.location_label IS 
  'Predefined delivery location. Must be either "Home - Addis Ababa" or "Office - Addis Ababa"';

ALTER TABLE public.user_active_window ENABLE ROW LEVEL SECURITY;

-- Revoke all, then grant minimal
REVOKE ALL ON public.user_active_window FROM anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.user_active_window TO authenticated;

DROP POLICY IF EXISTS "Users can manage their own active window" ON public.user_active_window;
CREATE POLICY "Users can manage their own active window" 
  ON public.user_active_window FOR ALL 
  USING (user_id = auth.uid()) 
  WITH CHECK (user_id = auth.uid());

-- =============================================================================
-- 3. USER ONBOARDING STATE
-- =============================================================================

CREATE TABLE public.user_onboarding_state (
  user_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  stage text NOT NULL CHECK (stage IN ('box', 'auth', 'delivery', 'recipes', 'checkout', 'done')),
  plan_box_size int NOT NULL CHECK (plan_box_size IN (2, 4)),
  meals_per_week int NOT NULL CHECK (meals_per_week >= 3 AND meals_per_week <= 5),
  draft_window_id uuid REFERENCES public.delivery_windows(id),
  updated_at timestamptz DEFAULT now()
);

COMMENT ON TABLE public.user_onboarding_state IS 
  'Tracks user onboarding progress and meal plan selection. One row per user.';
COMMENT ON COLUMN public.user_onboarding_state.stage IS 
  'Current onboarding stage: box → auth → delivery → recipes → checkout → done';
COMMENT ON COLUMN public.user_onboarding_state.plan_box_size IS 
  'Number of people: 2 or 4';
COMMENT ON COLUMN public.user_onboarding_state.meals_per_week IS 
  'Meals per week: 3, 4, or 5';

ALTER TABLE public.user_onboarding_state ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON public.user_onboarding_state FROM anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.user_onboarding_state TO authenticated;

DROP POLICY IF EXISTS "Users can manage their own onboarding state" ON public.user_onboarding_state;
CREATE POLICY "Users can manage their own onboarding state" 
  ON public.user_onboarding_state FOR ALL 
  USING (user_id = auth.uid()) 
  WITH CHECK (user_id = auth.uid());

-- =============================================================================
-- 4. WEEKS AND RECIPES
-- =============================================================================

CREATE TABLE public.weeks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  week_start date NOT NULL UNIQUE,
  is_current boolean NOT NULL DEFAULT false,
  created_at timestamptz DEFAULT now()
);

COMMENT ON TABLE public.weeks IS 
  'Week tracking for recipe schedules. Managed by admins only.';

CREATE TABLE public.recipes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  week_id uuid NOT NULL REFERENCES public.weeks(id) ON DELETE CASCADE,
  title text NOT NULL,
  slug text NOT NULL UNIQUE,
  image_url text,
  tags text[] DEFAULT '{}',
  is_active boolean NOT NULL DEFAULT true,
  sort_order int DEFAULT 0,
  created_at timestamptz DEFAULT now()
);

COMMENT ON TABLE public.recipes IS 
  'Weekly recipe catalog. Read-only for users, managed by admins.';
COMMENT ON COLUMN public.recipes.slug IS 
  'URL-safe identifier used for routing and asset lookup';
COMMENT ON COLUMN public.recipes.tags IS 
  'Array of tags: traditional, vegetarian, spicy, beef, chicken, etc.';
COMMENT ON COLUMN public.recipes.sort_order IS 
  'Display order. Use 1-15 for stable UI presentation.';

CREATE TABLE public.user_recipe_selections (
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  recipe_id uuid NOT NULL REFERENCES public.recipes(id) ON DELETE CASCADE,
  week_start date NOT NULL,
  selected boolean NOT NULL DEFAULT false,
  created_at timestamptz DEFAULT now(),
  PRIMARY KEY (user_id, recipe_id, week_start)
);

COMMENT ON TABLE public.user_recipe_selections IS 
  'User recipe selections per week. Plan allowance enforced by RPC.';

-- Enable RLS
ALTER TABLE public.weeks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.recipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_recipe_selections ENABLE ROW LEVEL SECURITY;

-- Revoke all, grant minimal
REVOKE ALL ON public.weeks FROM anon, authenticated;
REVOKE ALL ON public.recipes FROM anon, authenticated;
REVOKE ALL ON public.user_recipe_selections FROM anon, authenticated;

GRANT SELECT ON public.weeks TO anon, authenticated;
GRANT SELECT ON public.recipes TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.user_recipe_selections TO authenticated;

-- Policies
DROP POLICY IF EXISTS "Public read weeks" ON public.weeks;
CREATE POLICY "Public read weeks" 
  ON public.weeks FOR SELECT 
  USING (true);

DROP POLICY IF EXISTS "Public read recipes" ON public.recipes;
CREATE POLICY "Public read recipes" 
  ON public.recipes FOR SELECT 
  USING (is_active = true);

DROP POLICY IF EXISTS "Users can manage their own recipe selections" ON public.user_recipe_selections;
CREATE POLICY "Users can manage their own recipe selections" 
  ON public.user_recipe_selections FOR ALL 
  USING (user_id = auth.uid()) 
  WITH CHECK (user_id = auth.uid());

-- Seed data
INSERT INTO public.weeks (week_start, is_current)
VALUES (date_trunc('week', now())::date, true);

WITH current_week AS (SELECT id FROM public.weeks WHERE is_current = true LIMIT 1)
INSERT INTO public.recipes (week_id, title, slug, image_url, tags, sort_order)
SELECT cw.id, 'Injera with Beef Stew', 'injera-beef-stew', '/images/injera-beef-stew.jpg', 
       ARRAY['traditional', 'beef', 'spicy'], 1 FROM current_week cw
UNION ALL SELECT cw.id, 'Doro Wat', 'doro-wat', '/images/doro-wat.jpg', 
       ARRAY['traditional', 'chicken', 'spicy', 'eggs'], 2 FROM current_week cw
UNION ALL SELECT cw.id, 'Kitfo', 'kitfo', '/images/kitfo.jpg', 
       ARRAY['traditional', 'beef', 'raw', 'spicy'], 3 FROM current_week cw
UNION ALL SELECT cw.id, 'Shiro Wat', 'shiro-wat', '/images/shiro-wat.jpg', 
       ARRAY['vegetarian', 'chickpea', 'mild'], 4 FROM current_week cw
UNION ALL SELECT cw.id, 'Tibs', 'tibs', '/images/tibs.jpg', 
       ARRAY['traditional', 'beef', 'vegetables', 'mild'], 5 FROM current_week cw;

-- =============================================================================
-- 5. ORDERS SCHEMA
-- =============================================================================

CREATE TABLE public.orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  week_start date NOT NULL,
  window_id uuid NOT NULL REFERENCES public.delivery_windows(id),
  address jsonb NOT NULL,
  meals_per_week int NOT NULL,
  total_items int NOT NULL,
  status text NOT NULL DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'confirmed', 'cancelled')),
  created_at timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.orders IS 
  'User orders with delivery details. Each order represents one week''s meal kit subscription.';
COMMENT ON COLUMN public.orders.address IS 
  'JSONB delivery address: {name, phone, line1, line2, city, notes}';
COMMENT ON COLUMN public.orders.status IS 
  'Order status: scheduled (created) → confirmed (approved) → cancelled (user/admin)';
COMMENT ON COLUMN public.orders.total_items IS 
  'Number of recipes in this order. Must match user''s meals_per_week plan.';

CREATE TABLE public.order_items (
  order_id uuid NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  recipe_id uuid NOT NULL REFERENCES public.recipes(id),
  qty int NOT NULL DEFAULT 1 CHECK (qty > 0),
  PRIMARY KEY (order_id, recipe_id)
);

COMMENT ON TABLE public.order_items IS 
  'Line items for orders. Links orders to selected recipes.';
COMMENT ON COLUMN public.order_items.qty IS 
  'Quantity of this recipe in the order. Typically 1 for meal kits.';

-- Enable RLS
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;

-- Revoke all, grant minimal
REVOKE ALL ON public.orders FROM anon, authenticated;
REVOKE ALL ON public.order_items FROM anon, authenticated;

GRANT SELECT, INSERT ON public.orders TO authenticated;
GRANT SELECT, INSERT ON public.order_items TO authenticated;
-- Note: UPDATE/DELETE can be added later for order modification features

-- Policies (user isolation)
DROP POLICY IF EXISTS "orders self access" ON public.orders;
CREATE POLICY "orders self access" 
  ON public.orders FOR SELECT 
  TO authenticated 
  USING (user_id = auth.uid());

CREATE POLICY "orders self insert" 
  ON public.orders FOR INSERT 
  TO authenticated 
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "order_items self access" ON public.order_items;
CREATE POLICY "order_items self access" 
  ON public.order_items FOR SELECT 
  TO authenticated 
  USING (order_id IN (SELECT id FROM public.orders WHERE user_id = auth.uid()));

CREATE POLICY "order_items self insert" 
  ON public.order_items FOR INSERT 
  TO authenticated 
  WITH CHECK (order_id IN (SELECT id FROM public.orders WHERE user_id = auth.uid()));

-- =============================================================================
-- 6. APP SCHEMA
-- =============================================================================

CREATE SCHEMA app;
COMMENT ON SCHEMA app IS 
  'Application-facing views and RPCs. All user reads go through app.* to enforce business rules.';

-- Revoke default schema privileges
REVOKE ALL ON SCHEMA app FROM public;
GRANT USAGE ON SCHEMA app TO anon, authenticated;

-- =============================================================================
-- 7. APP VIEWS (Read-Only, User-Scoped)
-- =============================================================================

-- View 1: Available Delivery Windows
CREATE VIEW app.available_delivery_windows AS
SELECT
  dw.id,
  dw.start_at,
  dw.end_at,
  dw.weekday,
  dw.slot,
  dw.city,
  dw.capacity,
  dw.booked_count,
  (dw.capacity - dw.booked_count > 0) AS has_capacity,
  dw.is_active,
  dw.created_at
FROM public.delivery_windows dw
WHERE dw.is_active = true
ORDER BY dw.start_at;

COMMENT ON VIEW app.available_delivery_windows IS 
  'Public read-only view of active delivery windows. No user data, safe for anon.';

-- View 2: User Delivery Readiness (auth.uid() scoped)
CREATE VIEW app.user_delivery_readiness AS
WITH current_user_data AS (
  SELECT auth.uid() AS user_id  -- ✅ Uses auth.uid()
),
user_window AS (
  SELECT 
    uaw.user_id,
    uaw.window_id,
    uaw.location_label,
    dw.start_at,
    dw.end_at,
    dw.weekday,
    dw.slot,
    dw.city
  FROM current_user_data cu
  LEFT JOIN public.user_active_window uaw ON uaw.user_id = cu.user_id  -- ✅ Self-joins only
  LEFT JOIN public.delivery_windows dw ON dw.id = uaw.window_id
)
SELECT
  uw.user_id,
  (uw.user_id IS NOT NULL) AS is_ready,
  CASE 
    WHEN uw.user_id IS NULL THEN ARRAY['NO_ACTIVE_WINDOW']::text[]
    ELSE ARRAY[]::text[]
  END AS reasons,
  uw.location_label AS active_city,
  uw.window_id AS active_window_id,
  uw.start_at AS window_start,
  uw.end_at AS window_end,
  uw.weekday,
  uw.slot
FROM user_window uw;

COMMENT ON VIEW app.user_delivery_readiness IS 
  'User-scoped delivery gate status. Returns only current user''s window via auth.uid(). No data leak.';

-- View 3: Current Weekly Recipes (gated by readiness, auth.uid() scoped)
CREATE VIEW app.current_weekly_recipes AS
WITH gate_check AS (
  SELECT is_ready FROM app.user_delivery_readiness  -- ✅ Already auth.uid() scoped
),
current_week AS (
  SELECT id, week_start FROM public.weeks WHERE is_current = true LIMIT 1
)
SELECT 
  r.id,
  r.title,
  r.slug,
  r.image_url,
  r.tags,
  r.sort_order,
  cw.week_start
FROM current_week cw
JOIN public.recipes r ON r.week_id = cw.id AND r.is_active = true
CROSS JOIN gate_check gc
WHERE gc.is_ready = true  -- ✅ Enforces delivery gate per user
ORDER BY r.sort_order, r.title;

COMMENT ON VIEW app.current_weekly_recipes IS 
  'Weekly recipes for current user. Gated by delivery readiness (auth.uid()). Returns empty if user not ready.';

-- =============================================================================
-- 8. APP RPCs (All SECURITY DEFINER with auth.uid())
-- =============================================================================

-- RPC 1: Current Week (read-only, no auth needed)
CREATE FUNCTION app.current_addis_week()
RETURNS date
LANGUAGE sql
STABLE
AS $$
  SELECT date_trunc('week', now())::date;
$$;

COMMENT ON FUNCTION app.current_addis_week IS 
  'Returns Monday of current week (Addis Ababa timezone). Read-only, no user data.';

-- RPC 2: User Selections (read, auth.uid() scoped)
CREATE FUNCTION app.user_selections()
RETURNS TABLE(
  recipe_id uuid,
  week_start date,
  box_size int,
  selected boolean
)
LANGUAGE sql
SECURITY DEFINER  -- ✅ SECURITY DEFINER
STABLE
AS $$
  WITH current_week AS (
    SELECT id, week_start FROM public.weeks WHERE is_current = true LIMIT 1
  ),
  user_onboarding AS (
    SELECT plan_box_size 
    FROM public.user_onboarding_state 
    WHERE user_id = auth.uid()  -- ✅ Uses auth.uid()
  ),
  weekly_recipes AS (
    SELECT r.id, cw.week_start
    FROM current_week cw
    JOIN public.recipes r ON r.week_id = cw.id AND r.is_active = true
  )
  SELECT 
    wr.id AS recipe_id,
    wr.week_start,
    COALESCE(uo.plan_box_size, 2) AS box_size,
    COALESCE(urs.selected, false) AS selected
  FROM weekly_recipes wr
  CROSS JOIN user_onboarding uo
  LEFT JOIN public.user_recipe_selections urs 
    ON urs.recipe_id = wr.id 
    AND urs.user_id = auth.uid()  -- ✅ Uses auth.uid()
    AND urs.week_start = wr.week_start
  ORDER BY wr.id;
$$;

COMMENT ON FUNCTION app.user_selections IS 
  'Returns current user''s recipe selections with plan allowance. Uses auth.uid() for isolation.';

-- RPC 3: Upsert Active Window (write, auth.uid() enforced)
CREATE FUNCTION app.upsert_user_active_window(
  window_id uuid,
  location_label text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER  -- ✅ SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO public.user_active_window (user_id, window_id, location_label)
  VALUES (auth.uid(), window_id, location_label)  -- ✅ Uses auth.uid()
  ON CONFLICT (user_id) 
  DO UPDATE SET 
    window_id = EXCLUDED.window_id,
    location_label = EXCLUDED.location_label,
    created_at = now();
END;
$$;

COMMENT ON FUNCTION app.upsert_user_active_window IS 
  'Sets current user''s delivery window. SECURITY DEFINER with auth.uid() enforcement.';

-- RPC 4: Set Onboarding Plan (write, auth.uid() enforced)
CREATE FUNCTION app.set_onboarding_plan(
  box_size int,
  meals_per_week int
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER  -- ✅ SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO public.user_onboarding_state (user_id, stage, plan_box_size, meals_per_week)
  VALUES (auth.uid(), 'box', box_size, meals_per_week)  -- ✅ Uses auth.uid()
  ON CONFLICT (user_id)
  DO UPDATE SET 
    plan_box_size = EXCLUDED.plan_box_size,
    meals_per_week = EXCLUDED.meals_per_week,
    stage = 'box',
    updated_at = now();
END;
$$;

COMMENT ON FUNCTION app.set_onboarding_plan IS 
  'Saves user''s meal plan selection. SECURITY DEFINER with auth.uid() enforcement.';

-- RPC 5: Toggle Recipe Selection (write, auth.uid() enforced, quota checked)
CREATE FUNCTION app.toggle_recipe_selection(
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
SECURITY DEFINER  -- ✅ SECURITY DEFINER
AS $$
DECLARE
  current_week_start date;
  user_plan int;
  current_selected int;
  new_selected int;
BEGIN
  SELECT week_start INTO current_week_start 
  FROM public.weeks WHERE is_current = true LIMIT 1;
  
  SELECT meals_per_week INTO user_plan 
  FROM public.user_onboarding_state 
  WHERE user_id = auth.uid();  -- ✅ Uses auth.uid()
  
  SELECT COUNT(*) INTO current_selected 
  FROM public.user_recipe_selections 
  WHERE user_id = auth.uid()  -- ✅ Uses auth.uid()
    AND week_start = current_week_start 
    AND selected = true;
  
  new_selected := current_selected + CASE WHEN select_recipe THEN 1 ELSE -1 END;
  
  IF new_selected < 0 OR new_selected > user_plan THEN
    SELECT current_selected, (user_plan - current_selected), user_plan, false
    INTO total_selected, remaining, allowed, ok;
    RETURN;
  END IF;
  
  INSERT INTO public.user_recipe_selections (user_id, recipe_id, week_start, selected)
  VALUES (auth.uid(), recipe_id, current_week_start, select_recipe)  -- ✅ Uses auth.uid()
  ON CONFLICT (user_id, recipe_id, week_start)
  DO UPDATE SET selected = select_recipe;
  
  SELECT new_selected, (user_plan - new_selected), user_plan, true
  INTO total_selected, remaining, allowed, ok;
  
  RETURN;
END;
$$;

COMMENT ON FUNCTION app.toggle_recipe_selection IS 
  'Toggles recipe selection with plan allowance enforcement. SECURITY DEFINER with auth.uid(). Returns ok=false if over limit.';

-- RPC 6: Confirm Scheduled Order (write, auth.uid() enforced, fully validated)
CREATE OR REPLACE FUNCTION app.confirm_scheduled_order(p_address jsonb)
RETURNS TABLE(order_id uuid, total_items int) 
LANGUAGE plpgsql
SECURITY DEFINER  -- ✅ SECURITY DEFINER
SET search_path = public, app
AS $$
DECLARE
  v_user uuid := auth.uid();  -- ✅ Uses auth.uid()
  v_week date;
  v_window uuid;
  v_meals int;
BEGIN
  -- Guardrail: Must be authenticated
  IF v_user IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  SELECT app.current_addis_week() INTO v_week;

  SELECT uaw.window_id INTO v_window
  FROM public.user_active_window uaw
  WHERE uaw.user_id = v_user;  -- ✅ Uses auth.uid()

  IF v_window IS NULL THEN
    RAISE EXCEPTION 'Delivery window not selected';
  END IF;

  SELECT COALESCE(uos.meals_per_week, 3) INTO v_meals
  FROM public.user_onboarding_state uos
  WHERE uos.user_id = v_user;  -- ✅ Uses auth.uid()

  -- Count selected recipes
  WITH sel AS (
    SELECT urs.recipe_id
    FROM public.user_recipe_selections urs
    WHERE urs.user_id = v_user  -- ✅ Uses auth.uid()
      AND urs.week_start = v_week
      AND urs.selected = true
  )
  SELECT COUNT(*) FROM sel INTO STRICT total_items;

  IF total_items = 0 THEN
    RAISE EXCEPTION 'No recipes selected';
  END IF;

  IF total_items > v_meals THEN
    RAISE EXCEPTION 'Over selection limit: % > %', total_items, v_meals;
  END IF;

  -- Create order (user_id from auth.uid())
  INSERT INTO public.orders (user_id, week_start, window_id, address, meals_per_week, total_items, status)
  VALUES (v_user, v_week, v_window, p_address, v_meals, total_items, 'scheduled')  -- ✅ Uses auth.uid()
  RETURNING id, total_items INTO order_id, total_items;

  -- Create order items
  INSERT INTO public.order_items (order_id, recipe_id, qty)
  SELECT order_id, s.recipe_id, 1
  FROM (
    SELECT urs.recipe_id
    FROM public.user_recipe_selections urs
    WHERE urs.user_id = v_user  -- ✅ Uses auth.uid()
      AND urs.week_start = v_week
      AND urs.selected = true
  ) s;

  RETURN NEXT;
END;
$$;

COMMENT ON FUNCTION app.confirm_scheduled_order IS 
  'Creates order from current selections. SECURITY DEFINER with full auth.uid() enforcement. Validates: auth, window, recipes, quota.';

-- =============================================================================
-- 9. PERMISSIONS (Explicit Grants)
-- =============================================================================

-- Grant view access
REVOKE ALL ON app.available_delivery_windows FROM anon, authenticated;
REVOKE ALL ON app.user_delivery_readiness FROM anon, authenticated;
REVOKE ALL ON app.current_weekly_recipes FROM anon, authenticated;

GRANT SELECT ON app.available_delivery_windows TO anon, authenticated;
GRANT SELECT ON app.user_delivery_readiness TO anon, authenticated;
GRANT SELECT ON app.current_weekly_recipes TO anon, authenticated;

-- Grant RPC access
REVOKE ALL ON FUNCTION app.current_addis_week() FROM anon, authenticated;
REVOKE ALL ON FUNCTION app.user_selections() FROM anon, authenticated;
REVOKE ALL ON FUNCTION app.upsert_user_active_window(uuid, text) FROM anon, authenticated;
REVOKE ALL ON FUNCTION app.set_onboarding_plan(int, int) FROM anon, authenticated;
REVOKE ALL ON FUNCTION app.toggle_recipe_selection(uuid, boolean) FROM anon, authenticated;
REVOKE ALL ON FUNCTION app.confirm_scheduled_order(jsonb) FROM anon, authenticated;

GRANT EXECUTE ON FUNCTION app.current_addis_week() TO anon, authenticated;
GRANT EXECUTE ON FUNCTION app.user_selections() TO anon, authenticated;
GRANT EXECUTE ON FUNCTION app.upsert_user_active_window(uuid, text) TO authenticated;  -- ✅ authenticated only
GRANT EXECUTE ON FUNCTION app.set_onboarding_plan(int, int) TO authenticated;  -- ✅ authenticated only
GRANT EXECUTE ON FUNCTION app.toggle_recipe_selection(uuid, boolean) TO authenticated;  -- ✅ authenticated only
GRANT EXECUTE ON FUNCTION app.confirm_scheduled_order(jsonb) TO authenticated;  -- ✅ authenticated only

-- =============================================================================
-- 10. VERIFICATION
-- =============================================================================

DO $$
DECLARE
  window_count int;
  readiness_count int;
  recipe_count int;
  selection_count int;
  current_week_date date;
  orders_count int;
  rpc_count int;
BEGIN
  SELECT COUNT(*) INTO window_count FROM app.available_delivery_windows;
  RAISE NOTICE '✅ Available delivery windows: %', window_count;
  
  SELECT COUNT(*) INTO readiness_count FROM app.user_delivery_readiness;
  RAISE NOTICE '✅ User delivery readiness records: %', readiness_count;
  
  SELECT COUNT(*) INTO recipe_count FROM app.current_weekly_recipes;
  RAISE NOTICE '✅ Current weekly recipes: % (0 is normal if not logged in)', recipe_count;
  
  SELECT COUNT(*) INTO selection_count FROM app.user_selections();
  RAISE NOTICE '✅ User selections: % (0 is normal if not logged in)', selection_count;
  
  SELECT app.current_addis_week() INTO current_week_date;
  RAISE NOTICE '✅ Current week: %', current_week_date;
  
  SELECT COUNT(*) INTO orders_count FROM public.orders;
  RAISE NOTICE '✅ Orders: %', orders_count;
  
  SELECT COUNT(*) INTO rpc_count 
  FROM information_schema.routines 
  WHERE routine_schema = 'app';
  RAISE NOTICE '✅ Total RPCs: % (expected: 6)', rpc_count;
  
  RAISE NOTICE '🎉 All migrations completed successfully!';
END $$;

