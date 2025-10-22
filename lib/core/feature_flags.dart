/// YeneFresh Feature Flags
/// Kill-switch and gradual rollout controls
class FeatureFlags {
  // =============================================================================
  // CRITICAL FLAGS (Kill-switch capability)
  // =============================================================================

  /// Master flag for order creation
  /// Set to false to disable all order placement (show friendly banner instead)
  static bool get ordersEnabled {
    // Can be controlled via remote config (Firebase, LaunchDarkly, etc.)
    // For now, can be overridden via environment variable
    const value =
        String.fromEnvironment('ORDERS_ENABLED', defaultValue: 'true');
    return value.toLowerCase() == 'true';
  }

  /// Enable/disable delivery window selection
  static bool get deliveryGateEnabled {
    const value =
        String.fromEnvironment('DELIVERY_GATE_ENABLED', defaultValue: 'true');
    return value.toLowerCase() == 'true';
  }

  /// Enable/disable recipe selection
  static bool get recipeSelectionEnabled {
    const value = String.fromEnvironment('RECIPE_SELECTION_ENABLED',
        defaultValue: 'true');
    return value.toLowerCase() == 'true';
  }

  // =============================================================================
  // FEATURE ROLLOUT FLAGS
  // =============================================================================

  /// Show order history feature
  static bool get showOrderHistory {
    const value =
        String.fromEnvironment('SHOW_ORDER_HISTORY', defaultValue: 'true');
    return value.toLowerCase() == 'true';
  }

  /// Enable payment integration (when ready)
  static bool get paymentsEnabled {
    const value =
        String.fromEnvironment('PAYMENTS_ENABLED', defaultValue: 'false');
    return value.toLowerCase() == 'true';
  }

  /// Show feedback/report buttons
  static bool get feedbackEnabled {
    const value =
        String.fromEnvironment('FEEDBACK_ENABLED', defaultValue: 'true');
    return value.toLowerCase() == 'true';
  }

  // =============================================================================
  // DEBUG/TESTING FLAGS
  // =============================================================================

  /// Showcase mode for investor demos
  static bool get showcaseMode {
    const value = String.fromEnvironment('SHOWCASE', defaultValue: 'false');
    return value.toLowerCase() == 'true';
  }

  /// Enable verbose logging
  static bool get verboseLogging {
    const value = String.fromEnvironment('VERBOSE_LOGS', defaultValue: 'false');
    return value.toLowerCase() == 'true';
  }

  // =============================================================================
  // HELPERS
  // =============================================================================

  /// Get all flag states (for debug screen)
  static Map<String, bool> getAllFlags() {
    return {
      'ordersEnabled': ordersEnabled,
      'deliveryGateEnabled': deliveryGateEnabled,
      'recipeSelectionEnabled': recipeSelectionEnabled,
      'showOrderHistory': showOrderHistory,
      'paymentsEnabled': paymentsEnabled,
      'feedbackEnabled': feedbackEnabled,
      'showcaseMode': showcaseMode,
      'verboseLogging': verboseLogging,
    };
  }
}




