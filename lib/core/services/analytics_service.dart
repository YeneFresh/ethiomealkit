import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Analytics service for tracking user behavior
/// Acts on events: deliveryConfirmed, recipeViewed, addToBox, swap, checkoutStart, checkoutSuccess, streakGained
class AnalyticsService {
  final SupabaseClient _sb;

  AnalyticsService(this._sb);

  /// Track any event with optional properties
  Future<void> track(String eventName, [Map<String, dynamic>? properties]) async {
    try {
      final user = _sb.auth.currentUser;
      
      await _sb.from('analytics_events').insert({
        'event_name': eventName,
        'user_id': user?.id ?? 'guest',
        'properties': properties ?? {},
        'timestamp': DateTime.now().toUtc().toIso8601String(),
        'session_id': _getSessionId(),
      });

      if (kDebugMode) {
        print('📊 Analytics: $eventName ${properties != null ? properties : ''}');
      }
    } catch (e) {
      // Analytics should never block user flow
      if (kDebugMode) {
        print('⚠️ Analytics error (non-critical): $e');
      }
    }
  }

  // ===== Convenience methods =====

  Future<void> deliveryConfirmed({
    required String windowId,
    required String addressType,
    required String city,
  }) async {
    await track('delivery_confirmed', {
      'window_id': windowId,
      'address_type': addressType,
      'city': city,
    });
  }

  Future<void> recipeViewed({
    required String recipeId,
    required String recipeTitle,
  }) async {
    await track('recipe_viewed', {
      'recipe_id': recipeId,
      'recipe_title': recipeTitle,
    });
  }

  Future<void> addToBox({
    required String recipeId,
    required int totalSelected,
    required int quota,
  }) async {
    await track('add_to_box', {
      'recipe_id': recipeId,
      'total_selected': totalSelected,
      'quota': quota,
      'is_complete': totalSelected >= quota,
    });
  }

  Future<void> swapRecipe({
    required String removedId,
    required String addedId,
  }) async {
    await track('swap', {
      'removed_recipe_id': removedId,
      'added_recipe_id': addedId,
    });
  }

  Future<void> checkoutStart({
    required int recipeCount,
    required double total,
  }) async {
    await track('checkout_start', {
      'recipe_count': recipeCount,
      'total': total,
    });
  }

  Future<void> checkoutSuccess({
    required String orderId,
    required int recipeCount,
    required double total,
    required String paymentMethod,
  }) async {
    await track('checkout_success', {
      'order_id': orderId,
      'recipe_count': recipeCount,
      'total': total,
      'payment_method': paymentMethod,
    });
  }

  Future<void> streakGained({
    required int streakWeeks,
  }) async {
    await track('streak_gained', {
      'streak_weeks': streakWeeks,
    });
  }

  Future<void> welcomeGetStarted() async {
    await track('welcome_get_started');
  }

  Future<void> boxSelectionComplete({
    required int people,
    required int meals,
  }) async {
    await track('box_selection_complete', {
      'people': people,
      'meals': meals,
    });
  }

  Future<void> signUpComplete({
    required String email,
    required String method, // 'email' | 'google'
  }) async {
    await track('signup_complete', {
      'email': email,
      'method': method,
    });
  }

  // ===== Session management =====

  static String? _sessionId;

  String _getSessionId() {
    _sessionId ??= DateTime.now().millisecondsSinceEpoch.toString();
    return _sessionId!;
  }

  static void resetSession() {
    _sessionId = null;
  }
}

/// SQL for analytics table (run in Supabase SQL editor)
const analyticsTableSql = '''
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

-- Drop-off report
CREATE OR REPLACE VIEW analytics_dropoff AS
SELECT
  'Welcome → Box' as step,
  ROUND(100.0 * step_2_box / NULLIF(step_1_welcome, 0), 1) as conversion_pct,
  step_1_welcome - step_2_box as dropped
FROM analytics_funnel
UNION ALL
SELECT
  'Box → SignUp',
  ROUND(100.0 * step_3_signup / NULLIF(step_2_box, 0), 1),
  step_2_box - step_3_signup
FROM analytics_funnel
UNION ALL
SELECT
  'SignUp → Delivery',
  ROUND(100.0 * step_4_delivery / NULLIF(step_3_signup, 0), 1),
  step_3_signup - step_4_delivery
FROM analytics_funnel
UNION ALL
SELECT
  'Delivery → Checkout',
  ROUND(100.0 * step_5_checkout_start / NULLIF(step_4_delivery, 0), 1),
  step_4_delivery - step_5_checkout_start
FROM analytics_funnel
UNION ALL
SELECT
  'Checkout → Success',
  ROUND(100.0 * step_6_checkout_success / NULLIF(step_5_checkout_start, 0), 1),
  step_5_checkout_start - step_6_checkout_success
FROM analytics_funnel;
''';




