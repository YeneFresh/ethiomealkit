// Feature Flags - Grand Image Guardrails
// All experimental UI changes must be behind flags.
// Flags default OFF in release-like profiles to prevent surprise changes.

class Flags {
  // Gate & Delivery Flow
  static const bool newGateFlow = false; // New delivery readiness gate UI
  static const bool newDeliveryWindowSelector =
      false; // Enhanced delivery window picker

  // Menu & Recipe Selection
  static const bool newMenuGrid = false; // New recipe grid layout
  static const bool recipePreviews = false; // Recipe preview cards
  static const bool smartRecommendations = false; // AI-powered meal suggestions

  // Checkout & Payment
  static const bool newCheckoutFlow = false; // Streamlined checkout process
  static const bool paymentMethods = false; // Multiple payment options

  // Profile & Settings
  static const bool newProfileDesign = false; // Redesigned profile screens
  static const bool advancedSettings = false; // Additional user preferences

  // Navigation & Shell
  static const bool newBottomNav = false; // Updated navigation bar design
  static const bool quickActions = false; // Floating action buttons

  // Performance & UX
  static const bool lazyLoading = false; // Lazy load images and content
  static const bool animations = false; // Enhanced animations and transitions
  static const bool hapticFeedback = false; // Haptic feedback on interactions

  // Debug & Development
  static const bool debugOverlay = false; // Development debug information
  static const bool performanceMetrics = false; // Performance monitoring UI

  // Helper method to check if any experimental features are enabled
  static bool get hasExperimentalFeatures {
    return newGateFlow ||
        newDeliveryWindowSelector ||
        newMenuGrid ||
        recipePreviews ||
        smartRecommendations ||
        newCheckoutFlow ||
        paymentMethods ||
        newProfileDesign ||
        advancedSettings ||
        newBottomNav ||
        quickActions ||
        lazyLoading ||
        animations ||
        hapticFeedback ||
        debugOverlay ||
        performanceMetrics;
  }

  // Helper method to get all enabled flags for logging/debugging
  static List<String> get enabledFlags {
    final flags = <String>[];
    if (newGateFlow) flags.add('newGateFlow');
    if (newDeliveryWindowSelector) flags.add('newDeliveryWindowSelector');
    if (newMenuGrid) flags.add('newMenuGrid');
    if (recipePreviews) flags.add('recipePreviews');
    if (smartRecommendations) flags.add('smartRecommendations');
    if (newCheckoutFlow) flags.add('newCheckoutFlow');
    if (paymentMethods) flags.add('paymentMethods');
    if (newProfileDesign) flags.add('newProfileDesign');
    if (advancedSettings) flags.add('advancedSettings');
    if (newBottomNav) flags.add('newBottomNav');
    if (quickActions) flags.add('quickActions');
    if (lazyLoading) flags.add('lazyLoading');
    if (animations) flags.add('animations');
    if (hapticFeedback) flags.add('hapticFeedback');
    if (debugOverlay) flags.add('debugOverlay');
    if (performanceMetrics) flags.add('performanceMetrics');
    return flags;
  }
}
