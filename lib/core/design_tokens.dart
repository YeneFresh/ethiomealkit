import 'package:flutter/material.dart';

/// YeneFresh Design Tokens - 2025 Edition
/// Ethiopian-modern premium meal kit design system
/// Complete token set for investor-grade UI/UX
class Yf {
  // =============================================================================
  // COLORS - Ethiopian-modern palette
  // =============================================================================

  // Browns (primary brand)
  /// Deep brown - primary brand color, CTA backgrounds
  static const brown900 = Color(0xFF3A2415);

  /// Rich brown - hover states, emphasis
  static const brown700 = Color(0xFF5A371F);

  /// Medium brown - secondary brand elements
  static const brown600 = Color(0xFF8B4513);

  /// Legacy brown (now brown600)
  static const brown = brown600;

  // Golds (accent)
  /// Primary gold - accents, highlights, success moments
  static const gold600 = Color(0xFFB8860B);

  /// Legacy gold
  static const gold = gold600;

  /// Warm brown-orange (CTAs and highlights) - legacy
  static const warmBrown = Color(0xFFD2691E);

  // Peach (surfaces, warmth)
  /// Lightest peach - primary backgrounds
  static const peach50 = Color(0xFFFFF8F0);

  /// Light peach - elevated surfaces, cards
  static const peach100 = Color(0xFFFFF4E6);

  /// Legacy surface colors
  static const surfacePeach = peach100;
  static const surfacePeachAlt = peach50;

  // Ink (text, content)
  /// Primary text - headings, body
  static const ink900 = Color(0xFF141414);

  /// Secondary text - meta, labels, captions
  static const ink600 = Color(0xFF5E5E5E);

  /// Legacy text colors
  static const textDark = ink900;
  static const textMedium = ink600;

  // Semantic colors
  /// Success green - confirmations, positive states
  static const success600 = Color(0xFF1F9D55);

  /// Error red - alerts, destructive actions
  static const error600 = Color(0xFFD64545);

  // =============================================================================
  // BORDER RADIUS - Soft, premium feel (16–20px sweet spot)
  // =============================================================================

  /// Small radius (12px) - inputs, chips, small elements
  static const r12 = 12.0;

  /// Standard radius (16px) - cards, buttons, containers
  static const r16 = 16.0;

  /// Large radius (20px) - hero elements, recipe images
  static const r20 = 20.0;

  /// Border radius helpers
  static BorderRadius get borderRadius12 => BorderRadius.circular(r12);
  static BorderRadius get borderRadius16 => BorderRadius.circular(r16);
  static BorderRadius get borderRadius20 => BorderRadius.circular(r20);

  // =============================================================================
  // ELEVATION - Material 3 shadow system
  // =============================================================================

  /// No elevation (flat)
  static List<BoxShadow> get e0 => [];

  /// Level 1 elevation - subtle hover
  static List<BoxShadow> get e1 => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  /// Level 2 elevation - cards, standard elements
  static List<BoxShadow> get e2 => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  /// Level 4 elevation - modals, popovers
  static List<BoxShadow> get e4 => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  /// Legacy shadows (mapped to new system)
  static List<BoxShadow> get softShadow => e2;
  static List<BoxShadow> get brownShadow => [
    BoxShadow(
      color: brown.withValues(alpha: 0.15),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  // =============================================================================
  // SPACING - 4/8pt grid system
  // =============================================================================

  /// 4px - micro spacing
  static const s4 = 4.0;

  /// 8px - small spacing
  static const s8 = 8.0;

  /// 12px - medium-small spacing
  static const s12 = 12.0;

  /// 16px - standard spacing
  static const s16 = 16.0;

  /// 20px - medium-large spacing
  static const s20 = 20.0;

  /// 24px - large spacing
  static const s24 = 24.0;

  /// 32px - extra large spacing
  static const s32 = 32.0;

  /// Legacy spacing (mapped to new system)
  static const g4 = s4;
  static const g8 = s8;
  static const g12 = s12;
  static const g16 = s16;
  static const g24 = s24;
  static const g32 = s32;

  // Standard padding presets
  /// Screen edge padding - horizontal s24, vertical s20
  static const screenPadding = EdgeInsets.symmetric(
    horizontal: s24,
    vertical: s20,
  );

  /// Card internal padding
  static const cardPadding = EdgeInsets.all(s16);

  /// Button padding - min 48dp height compliance
  static const buttonPadding = EdgeInsets.symmetric(
    horizontal: s24,
    vertical: s16,
  );

  // =============================================================================
  // MOTION - Material 3 motion system
  // =============================================================================

  // Durations
  /// Quick transitions - 100ms (micro-interactions)
  static const d100 = Duration(milliseconds: 100);

  /// Standard transitions - 180ms (most UI changes)
  static const d200 = Duration(milliseconds: 180);

  /// Emphasized transitions - 240ms (hero moments)
  static const d300 = Duration(milliseconds: 240);

  // Curves
  /// Standard easing - most transitions
  static const standard = Curves.easeInOut;

  /// Emphasized easing - important moments
  static const emphasized = Curves.easeInOutCubicEmphasized;

  // Animation constants
  /// Stagger delay between list items
  static const stagger = Duration(milliseconds: 60);

  /// Legacy animation durations (mapped to new system)
  static const animationDuration = d300;
  static const animationDurationFast = d100;
  static const animationDurationSlow = Duration(milliseconds: 500);

  // =============================================================================
  // TYPOGRAPHY - Material 3 aligned
  // =============================================================================

  /// Minimum body font size
  static const bodyMinSize = 15.0;

  /// Minimum meta/caption font size
  static const metaMinSize = 12.0;

  /// Standard line height multiplier
  static const lineHeight = 1.4;

  // =============================================================================
  // INTERACTION - Accessibility & UX
  // =============================================================================

  /// Minimum tap target size (accessibility)
  static const minTapTarget = 44.0;

  /// Focus ring thickness
  static const focusRingWidth = 2.0;

  /// Focus ring color (gold at 24% alpha)
  static Color get focusRingColor => gold600.withValues(alpha: 0.24);

  // =============================================================================
  // HELPERS - Pre-composed styles
  // =============================================================================

  /// Standard card decoration
  static BoxDecoration cardDecoration(BuildContext context) {
    return BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: borderRadius16,
      boxShadow: e2,
    );
  }

  /// Info card decoration (with border)
  static BoxDecoration infoCardDecoration(BuildContext context) {
    return BoxDecoration(
      color: Theme.of(
        context,
      ).colorScheme.primaryContainer.withValues(alpha: 0.3),
      borderRadius: borderRadius16,
      border: Border.all(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
      ),
    );
  }

  /// Recipe card decoration
  static BoxDecoration recipeCardDecoration(BuildContext context) {
    return BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: borderRadius20,
      boxShadow: e1,
    );
  }

  /// Hero image decoration (rounded with subtle shadow)
  static BoxDecoration heroImageDecoration() {
    return BoxDecoration(borderRadius: borderRadius20, boxShadow: e2);
  }
}
