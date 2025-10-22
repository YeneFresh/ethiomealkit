import 'package:flutter/material.dart';
import 'design_tokens.dart';

/// YeneFresh Theme - 2025 Edition
/// Material 3 aligned, investor-grade visual polish
/// Ethiopian-modern premium meal kit aesthetic

/// Build light theme (default)
ThemeData buildTheme() => buildLightTheme();

/// Light theme with Ethiopian brown/gold accents
ThemeData buildLightTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: Yf.brown900,
    brightness: Brightness.light,
    primary: Yf.brown900,
    secondary: Yf.gold600,
    surface: Colors.white,
    surfaceContainer: Yf.peach50,
    surfaceContainerHigh: Yf.peach100,
    error: Yf.error600,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,

    // ==========================================================================
    // TYPOGRAPHY - Material 3 type scale with accessibility
    // ==========================================================================
    textTheme: TextTheme(
      // Display
      displaySmall: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        color: Yf.ink900,
        height: 1.2,
        letterSpacing: -0.5,
      ),

      // Headlines
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: Yf.ink900,
        height: 1.3,
      ),

      // Titles
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: Yf.ink900,
        height: 1.3,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Yf.ink900,
        height: Yf.lineHeight,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Yf.ink900,
        height: Yf.lineHeight,
      ),

      // Body
      bodyLarge: TextStyle(
        fontSize: Yf.bodyMinSize,
        fontWeight: FontWeight.w400,
        color: Yf.ink900,
        height: Yf.lineHeight,
      ),
      bodyMedium: TextStyle(
        fontSize: Yf.bodyMinSize,
        fontWeight: FontWeight.w400,
        color: Yf.ink900,
        height: Yf.lineHeight,
      ),

      // Labels
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Yf.ink900,
        height: 1.2,
      ),
      labelMedium: TextStyle(
        fontSize: Yf.metaMinSize,
        fontWeight: FontWeight.w500,
        color: Yf.ink600,
        height: 1.3,
      ),
      labelSmall: TextStyle(
        fontSize: Yf.metaMinSize,
        fontWeight: FontWeight.w400,
        color: Yf.ink600,
        height: 1.3,
      ),
    ),

    // ==========================================================================
    // APP BAR - Flat, clean
    // ==========================================================================
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Yf.ink900,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Yf.ink900,
      ),
    ),

    // ==========================================================================
    // CARDS - Elevated surfaces with subtle shadows
    // ==========================================================================
    cardTheme: CardThemeData(
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: Yf.borderRadius16,
      ),
      margin: EdgeInsets.symmetric(horizontal: Yf.s16, vertical: Yf.s8),
      color: Colors.white,
    ),

    // ==========================================================================
    // BUTTONS - Material 3 with 48dp min height
    // ==========================================================================
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(88, 48),
        shape: RoundedRectangleBorder(
          borderRadius: Yf.borderRadius16,
        ),
        padding: Yf.buttonPadding,
        elevation: 0,
        backgroundColor: Yf.brown900,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(88, 48),
        shape: RoundedRectangleBorder(
          borderRadius: Yf.borderRadius16,
        ),
        padding: Yf.buttonPadding,
        backgroundColor: Yf.brown900,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(88, 48),
        shape: RoundedRectangleBorder(
          borderRadius: Yf.borderRadius16,
        ),
        padding: Yf.buttonPadding,
        side: BorderSide(color: Yf.brown900, width: 1.5),
        foregroundColor: Yf.brown900,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(64, 48),
        shape: RoundedRectangleBorder(
          borderRadius: Yf.borderRadius12,
        ),
        foregroundColor: Yf.brown900,
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // ==========================================================================
    // INPUTS - Rounded with focus ring
    // ==========================================================================
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Yf.peach50,
      border: OutlineInputBorder(
        borderRadius: Yf.borderRadius12,
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: Yf.borderRadius12,
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: Yf.borderRadius12,
        borderSide: BorderSide(
          color: Yf.focusRingColor,
          width: Yf.focusRingWidth,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: Yf.borderRadius12,
        borderSide: BorderSide(color: Yf.error600, width: 1),
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: Yf.s16,
        vertical: Yf.s16,
      ),
    ),

    // ==========================================================================
    // CHIPS - Rounded, comfortable density
    // ==========================================================================
    chipTheme: ChipThemeData(
      backgroundColor: Yf.peach100,
      selectedColor: Yf.brown900,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(
        borderRadius: Yf.borderRadius12,
      ),
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: Yf.ink900,
      ),
      padding: EdgeInsets.symmetric(horizontal: Yf.s12, vertical: Yf.s8),
    ),

    // ==========================================================================
    // ICONS - Material Symbols Rounded
    // ==========================================================================
    iconTheme: IconThemeData(
      size: 24,
      color: Yf.ink900,
    ),

    // ==========================================================================
    // DIVIDERS - Subtle separation
    // ==========================================================================
    dividerTheme: DividerThemeData(
      color: Yf.ink600.withValues(alpha: 0.1),
      thickness: 1,
      space: Yf.s24,
    ),
  );
}

/// Dark theme with Ethiopian brown/gold accents
ThemeData buildDarkTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: Yf.brown900,
    brightness: Brightness.dark,
    primary: Yf.gold600,
    secondary: Yf.brown700,
    surface: const Color(0xFF1C1B1E),
    surfaceContainer: const Color(0xFF2B2930),
    surfaceContainerHigh: const Color(0xFF36343B),
    error: Yf.error600,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,

    // ==========================================================================
    // TYPOGRAPHY - Ensure contrast ≥ 4.5:1
    // ==========================================================================
    textTheme: TextTheme(
      displaySmall: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        height: 1.2,
        letterSpacing: -0.5,
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        height: 1.3,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        height: 1.3,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        height: Yf.lineHeight,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        height: Yf.lineHeight,
      ),
      bodyLarge: TextStyle(
        fontSize: Yf.bodyMinSize,
        fontWeight: FontWeight.w400,
        color: Colors.white.withValues(alpha: 0.87),
        height: Yf.lineHeight,
      ),
      bodyMedium: TextStyle(
        fontSize: Yf.bodyMinSize,
        fontWeight: FontWeight.w400,
        color: Colors.white.withValues(alpha: 0.87),
        height: Yf.lineHeight,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        height: 1.2,
      ),
      labelMedium: TextStyle(
        fontSize: Yf.metaMinSize,
        fontWeight: FontWeight.w500,
        color: Colors.white.withValues(alpha: 0.6),
        height: 1.3,
      ),
      labelSmall: TextStyle(
        fontSize: Yf.metaMinSize,
        fontWeight: FontWeight.w400,
        color: Colors.white.withValues(alpha: 0.6),
        height: 1.3,
      ),
    ),

    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: const Color(0xFF1C1B1E),
      foregroundColor: Colors.white,
      centerTitle: true,
      titleTextStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),

    cardTheme: CardThemeData(
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: Yf.borderRadius16,
      ),
      margin: EdgeInsets.symmetric(horizontal: Yf.s16, vertical: Yf.s8),
      color: const Color(0xFF2B2930),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(88, 48),
        shape: RoundedRectangleBorder(
          borderRadius: Yf.borderRadius16,
        ),
        padding: Yf.buttonPadding,
        elevation: 0,
        backgroundColor: Yf.gold600,
        foregroundColor: Yf.brown900,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(88, 48),
        shape: RoundedRectangleBorder(
          borderRadius: Yf.borderRadius16,
        ),
        padding: Yf.buttonPadding,
        backgroundColor: Yf.gold600,
        foregroundColor: Yf.brown900,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(88, 48),
        shape: RoundedRectangleBorder(
          borderRadius: Yf.borderRadius16,
        ),
        padding: Yf.buttonPadding,
        side: BorderSide(color: Yf.gold600, width: 1.5),
        foregroundColor: Yf.gold600,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(64, 48),
        shape: RoundedRectangleBorder(
          borderRadius: Yf.borderRadius12,
        ),
        foregroundColor: Yf.gold600,
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF36343B),
      border: OutlineInputBorder(
        borderRadius: Yf.borderRadius12,
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: Yf.borderRadius12,
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: Yf.borderRadius12,
        borderSide: BorderSide(
          color: Yf.gold600.withValues(alpha: 0.4),
          width: Yf.focusRingWidth,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: Yf.borderRadius12,
        borderSide: BorderSide(color: Yf.error600, width: 1),
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: Yf.s16,
        vertical: Yf.s16,
      ),
    ),

    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFF36343B),
      selectedColor: Yf.gold600,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(
        borderRadius: Yf.borderRadius12,
      ),
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: Colors.white.withValues(alpha: 0.87),
      ),
      padding: EdgeInsets.symmetric(horizontal: Yf.s12, vertical: Yf.s8),
    ),

    iconTheme: const IconThemeData(
      size: 24,
      color: Colors.white,
    ),

    dividerTheme: DividerThemeData(
      color: Colors.white.withValues(alpha: 0.1),
      thickness: 1,
      space: Yf.s24,
    ),
  );
}
