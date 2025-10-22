import 'package:flutter/foundation.dart';

/// Analytics abstraction layer
/// Currently logs to console, ready for PostHog/Firebase/Amplitude integration
class Analytics {
  static bool _enabled = true;

  /// Disable analytics (for testing or user preference)
  static void disable() => _enabled = false;

  /// Enable analytics
  static void enable() => _enabled = true;

  /// Track event
  static void track(String event, [Map<String, dynamic>? properties]) {
    if (!_enabled) return;

    if (kDebugMode) {
      debugPrint('📊 Analytics: $event ${properties ?? ""}');
    }

    // TODO: Add PostHog integration
    // posthog.capture(event: event, properties: properties);

    // TODO: Add Firebase Analytics
    // FirebaseAnalytics.instance.logEvent(name: event, parameters: properties);
  }

  // =============================================================================
  // Onboarding Events
  // =============================================================================

  static void welcomeGetStarted() {
    track('welcome_get_started');
  }

  static void gateOpened({String? location}) {
    track('gate_opened', {'location': location});
  }

  static void windowConfirmed({
    required String windowId,
    required String location,
    required String slot,
  }) {
    track('window_confirmed', {
      'window_id': windowId,
      'location': location,
      'slot': slot,
    });
  }

  static void recipeSelected({
    required String recipeId,
    required String recipeTitle,
    required int totalSelected,
    required int allowed,
  }) {
    track('recipe_selected', {
      'recipe_id': recipeId,
      'recipe_title': recipeTitle,
      'total_selected': totalSelected,
      'allowed': allowed,
    });
  }

  static void recipeDeselected({
    required String recipeId,
    required int totalSelected,
  }) {
    track('recipe_deselected', {
      'recipe_id': recipeId,
      'total_selected': totalSelected,
    });
  }

  static void recipesAutoSelected({required int count}) {
    track('recipes_auto_selected', {'count': count});
  }

  static void filterToggled({
    required List<String> filters,
    required int resultCount,
  }) {
    track('filter_toggled', {
      'active_filters': filters,
      'result_count': resultCount,
    });
  }

  static void orderScheduled({
    required String orderId,
    required int totalItems,
    required int mealsPerWeek,
  }) {
    track('order_scheduled', {
      'order_id': orderId,
      'total_items': totalItems,
      'meals_per_week': mealsPerWeek,
    });
  }

  static void orderConfirmed({required String orderId}) {
    track('order_confirmed', {'order_id': orderId});
  }

  // =============================================================================
  // User Events
  // =============================================================================

  static void userSignedUp({required String method}) {
    track('user_signed_up', {'method': method});
  }

  static void userSignedIn({required String method}) {
    track('user_signed_in', {'method': method});
  }

  static void planSelected({required int boxSize, required int mealsPerWeek}) {
    track('plan_selected', {
      'box_size': boxSize,
      'meals_per_week': mealsPerWeek,
    });
  }

  // =============================================================================
  // Error Events
  // =============================================================================

  static void error({
    required String error,
    String? screen,
    Map<String, dynamic>? context,
  }) {
    track('error', {'error': error, 'screen': screen, ...?context});
  }
}
