-- Analytics events table
CREATE TABLE IF NOT EXISTS analytics_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_name TEXT NOT NULL,
  user_id UUID,
  properties JSONB DEFAULT '{}',
  timestamp TIMESTAMPTZ DEFAULT NOW(),
  session_id TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for fast queries
CREATE INDEX IF NOT EXISTS idx_analytics_events_name ON analytics_events(event_name);
CREATE INDEX IF NOT EXISTS idx_analytics_events_user ON analytics_events(user_id);
CREATE INDEX IF NOT EXISTS idx_analytics_events_timestamp ON analytics_events(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_analytics_events_session ON analytics_events(session_id);

-- Funnel analysis view
CREATE OR REPLACE VIEW analytics_funnel AS
SELECT
  COUNT(DISTINCT CASE WHEN event_name = 'welcome_get_started' THEN session_id END) as step_1_welcome,
  COUNT(DISTINCT CASE WHEN event_name = 'box_selection_complete' THEN session_id END) as step_2_box,
  COUNT(DISTINCT CASE WHEN event_name = 'signup_complete' THEN session_id END) as step_3_signup,
  COUNT(DISTINCT CASE WHEN event_name = 'delivery_confirmed' THEN session_id END) as step_4_delivery,
  COUNT(DISTINCT CASE WHEN event_name = 'checkout_start' THEN session_id END) as step_5_checkout_start,
  COUNT(DISTINCT CASE WHEN event_name = 'checkout_success' THEN session_id END) as step_6_checkout_success
FROM analytics_events
WHERE timestamp >= NOW() - INTERVAL '7 days';

-- Drop-off report (shows where users leave)
CREATE OR REPLACE VIEW analytics_dropoff AS
SELECT
  'Welcome → Box' as step,
  COALESCE(ROUND(100.0 * step_2_box / NULLIF(step_1_welcome, 0), 1), 0) as conversion_pct,
  step_1_welcome - step_2_box as dropped
FROM analytics_funnel
UNION ALL
SELECT
  'Box → SignUp',
  COALESCE(ROUND(100.0 * step_3_signup / NULLIF(step_2_box, 0), 1), 0),
  step_2_box - step_3_signup
FROM analytics_funnel
UNION ALL
SELECT
  'SignUp → Delivery',
  COALESCE(ROUND(100.0 * step_4_delivery / NULLIF(step_3_signup, 0), 1), 0),
  step_3_signup - step_4_delivery
FROM analytics_funnel
UNION ALL
SELECT
  'Delivery → Checkout',
  COALESCE(ROUND(100.0 * step_5_checkout_start / NULLIF(step_4_delivery, 0), 1), 0),
  step_4_delivery - step_5_checkout_start
FROM analytics_funnel
UNION ALL
SELECT
  'Checkout → Success',
  COALESCE(ROUND(100.0 * step_6_checkout_success / NULLIF(step_5_checkout_start, 0), 1), 0),
  step_5_checkout_start - step_6_checkout_success
FROM analytics_funnel;

-- Most viewed recipes (past 7 days)
CREATE OR REPLACE VIEW analytics_popular_recipes AS
SELECT
  properties->>'recipe_id' as recipe_id,
  properties->>'recipe_title' as recipe_title,
  COUNT(*) as view_count,
  COUNT(DISTINCT user_id) as unique_users
FROM analytics_events
WHERE event_name = 'recipe_viewed'
  AND timestamp >= NOW() - INTERVAL '7 days'
GROUP BY properties->>'recipe_id', properties->>'recipe_title'
ORDER BY view_count DESC
LIMIT 20;

-- Swap analysis (which recipes get swapped out?)
CREATE OR REPLACE VIEW analytics_swap_patterns AS
SELECT
  properties->>'removed_recipe_id' as removed_recipe_id,
  properties->>'added_recipe_id' as added_recipe_id,
  COUNT(*) as swap_count
FROM analytics_events
WHERE event_name = 'swap'
  AND timestamp >= NOW() - INTERVAL '7 days'
GROUP BY properties->>'removed_recipe_id', properties->>'added_recipe_id'
ORDER BY swap_count DESC
LIMIT 20;

-- Comment: Run this in Supabase SQL Editor to set up analytics
-- Query analytics_dropoff for funnel insights
-- Query analytics_popular_recipes for content strategy
-- Query analytics_swap_patterns for recipe improvement opportunities





