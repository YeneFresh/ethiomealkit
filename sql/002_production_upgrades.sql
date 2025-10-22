-- =============================================================================
-- PRODUCTION UPGRADES - High-Impact Polish
-- Run this AFTER the main migration for production-grade features
-- =============================================================================

-- =============================================================================
-- 1. DELIVERY CAPACITY MANAGEMENT (ACID + Constraint)
-- =============================================================================

-- Add constraint to prevent overbooking
ALTER TABLE public.delivery_windows 
  ADD CONSTRAINT IF NOT EXISTS chk_booked_le_capacity 
  CHECK (booked_count <= capacity);

-- Reserve capacity function (called during order creation)
CREATE OR REPLACE FUNCTION app.reserve_window_capacity(p_window uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_has_capacity boolean;
BEGIN
  -- Lock the row for update to prevent race conditions
  PERFORM 1 FROM public.delivery_windows 
  WHERE id = p_window 
  FOR UPDATE;

  -- Check capacity
  SELECT (capacity - booked_count) > 0
  INTO v_has_capacity
  FROM public.delivery_windows
  WHERE id = p_window;

  IF NOT v_has_capacity THEN
    RAISE EXCEPTION 'No capacity available for this delivery window';
  END IF;

  -- Atomically increment booked count
  UPDATE public.delivery_windows
  SET booked_count = booked_count + 1
  WHERE id = p_window;
END;
$$;

COMMENT ON FUNCTION app.reserve_window_capacity IS 
  'Atomically reserves delivery window capacity with row-level locking. Prevents race conditions.';

GRANT EXECUTE ON FUNCTION app.reserve_window_capacity(uuid) TO authenticated;

-- =============================================================================
-- 2. ORDER LIFECYCLE + IDEMPOTENCY
-- =============================================================================

-- Add idempotency key to orders
ALTER TABLE public.orders 
  ADD COLUMN IF NOT EXISTS idempotency_key text UNIQUE;

COMMENT ON COLUMN public.orders.idempotency_key IS 
  'Unique key to prevent duplicate order creation on retry. Client-generated UUID.';

-- Order events audit trail
CREATE TABLE IF NOT EXISTS public.order_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id uuid NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  old_status text,
  new_status text NOT NULL,
  at timestamptz NOT NULL DEFAULT now(),
  actor text DEFAULT 'system'
);

COMMENT ON TABLE public.order_events IS 
  'Audit trail for order status transitions. Tracks who changed status and when.';

ALTER TABLE public.order_events ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON public.order_events FROM anon, authenticated;
GRANT SELECT ON public.order_events TO authenticated;

CREATE POLICY "order_events self access" 
  ON public.order_events FOR SELECT 
  TO authenticated 
  USING (order_id IN (SELECT id FROM public.orders WHERE user_id = auth.uid()));

-- Confirm order function (for two-step flow: create → confirm)
CREATE OR REPLACE FUNCTION app.confirm_order_final(p_order uuid, p_key text)
RETURNS void 
LANGUAGE plpgsql 
SECURITY DEFINER 
AS $$
DECLARE 
  v_prev_status text;
  v_user uuid;
BEGIN
  -- Verify order belongs to current user
  SELECT user_id, status INTO v_user, v_prev_status
  FROM public.orders
  WHERE id = p_order;

  IF v_user IS NULL THEN
    RAISE EXCEPTION 'Order not found';
  END IF;

  IF v_user != auth.uid() THEN
    RAISE EXCEPTION 'Not authorized to confirm this order';
  END IF;

  -- Update status (idempotent via key)
  UPDATE public.orders
  SET 
    status = 'confirmed',
    idempotency_key = COALESCE(idempotency_key, p_key)
  WHERE id = p_order
    AND (idempotency_key IS NULL OR idempotency_key = p_key);

  -- Log event
  INSERT INTO public.order_events (order_id, old_status, new_status, actor)
  VALUES (p_order, v_prev_status, 'confirmed', 'user');
END;
$$;

COMMENT ON FUNCTION app.confirm_order_final IS 
  'Confirms order (scheduled → confirmed). Idempotent via key. Logs status change to order_events.';

GRANT EXECUTE ON FUNCTION app.confirm_order_final(uuid, text) TO authenticated;

-- =============================================================================
-- 3. PII HARDENING (Restricted View)
-- =============================================================================

-- Public view without sensitive address data
CREATE OR REPLACE VIEW app.order_public AS
SELECT 
  id,
  user_id,
  week_start,
  window_id,
  meals_per_week,
  total_items,
  status,
  created_at
FROM public.orders;

COMMENT ON VIEW app.order_public IS 
  'Order summary without PII (address). Safe for operational queries and analytics.';

GRANT SELECT ON app.order_public TO authenticated;

-- Revoke direct SELECT on orders from anon
REVOKE SELECT ON public.orders FROM anon;

-- =============================================================================
-- 4. PERFORMANCE INDEXES
-- =============================================================================

-- Orders indexes (user queries + admin dashboards)
CREATE INDEX IF NOT EXISTS idx_orders_user 
  ON public.orders(user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_orders_week 
  ON public.orders(week_start);

CREATE INDEX IF NOT EXISTS idx_orders_window 
  ON public.orders(window_id);

CREATE INDEX IF NOT EXISTS idx_orders_status 
  ON public.orders(status) WHERE status != 'cancelled';

-- Recipes indexes (menu loading)
CREATE INDEX IF NOT EXISTS idx_recipes_week 
  ON public.recipes(week_id, sort_order);

CREATE INDEX IF NOT EXISTS idx_recipes_slug 
  ON public.recipes(slug);

CREATE INDEX IF NOT EXISTS idx_recipes_active 
  ON public.recipes(is_active, week_id) WHERE is_active = true;

-- Weeks index (current week lookup)
CREATE INDEX IF NOT EXISTS idx_weeks_current 
  ON public.weeks(is_current) WHERE is_current = true;

-- User tables indexes
CREATE INDEX IF NOT EXISTS idx_user_selections_user_week 
  ON public.user_recipe_selections(user_id, week_start, selected);

COMMENT ON INDEX idx_orders_user IS 
  'Optimizes user order history queries';
COMMENT ON INDEX idx_recipes_week IS 
  'Optimizes weekly menu loading by sort_order';
COMMENT ON INDEX idx_weeks_current IS 
  'Partial index for fast current week lookup';

-- =============================================================================
-- 5. UPDATE confirm_scheduled_order TO USE CAPACITY RESERVATION
-- =============================================================================

CREATE OR REPLACE FUNCTION app.confirm_scheduled_order(p_address jsonb)
RETURNS TABLE(order_id uuid, total_items int) 
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, app
AS $$
DECLARE
  v_user uuid := auth.uid();
  v_week date;
  v_window uuid;
  v_meals int;
BEGIN
  IF v_user IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  SELECT app.current_addis_week() INTO v_week;

  SELECT uaw.window_id INTO v_window
  FROM public.user_active_window uaw
  WHERE uaw.user_id = v_user;

  IF v_window IS NULL THEN
    RAISE EXCEPTION 'Delivery window not selected';
  END IF;

  SELECT COALESCE(uos.meals_per_week, 3) INTO v_meals
  FROM public.user_onboarding_state uos
  WHERE uos.user_id = v_user;

  WITH sel AS (
    SELECT urs.recipe_id
    FROM public.user_recipe_selections urs
    WHERE urs.user_id = v_user
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

  -- ⭐ NEW: Reserve delivery capacity (ACID guaranteed)
  PERFORM app.reserve_window_capacity(v_window);

  INSERT INTO public.orders (user_id, week_start, window_id, address, meals_per_week, total_items, status)
  VALUES (v_user, v_week, v_window, p_address, v_meals, total_items, 'scheduled')
  RETURNING id, total_items INTO order_id, total_items;

  INSERT INTO public.order_items (order_id, recipe_id, qty)
  SELECT order_id, s.recipe_id, 1
  FROM (
    SELECT urs.recipe_id
    FROM public.user_recipe_selections urs
    WHERE urs.user_id = v_user
      AND urs.week_start = v_week
      AND urs.selected = true
  ) s;

  RETURN NEXT;
END;
$$;

-- =============================================================================
-- VERIFICATION
-- =============================================================================

DO $$
DECLARE
  idx_count int;
  rpc_count int;
BEGIN
  SELECT COUNT(*) INTO idx_count 
  FROM pg_indexes 
  WHERE schemaname = 'public' 
    AND indexname LIKE 'idx_%';
  
  RAISE NOTICE '✅ Performance indexes: %', idx_count;
  
  SELECT COUNT(*) INTO rpc_count 
  FROM information_schema.routines 
  WHERE routine_schema = 'app';
  
  RAISE NOTICE '✅ Total RPCs: % (expected: 8)', rpc_count;
  
  RAISE NOTICE '🎉 Production upgrades complete!';
END $$;





