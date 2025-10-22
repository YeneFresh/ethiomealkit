import 'package:flutter/material.dart';
import 'package:ethiomealkit/core/app_colors.dart';
import 'package:ethiomealkit/core/layout.dart';

/// Builds the unified YeneFresh theme
/// All screens inherit these typography, colors, and component styles
ThemeData buildYeneFreshTheme() {
  final base = ThemeData.light();

  return base.copyWith(
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.gold,
      secondary: AppColors.darkBrown,
      surface: AppColors.offWhite,
      error: AppColors.error600,
    ),

    // Typography
    textTheme: base.textTheme.copyWith(
      // Headlines
      headlineLarge: const TextStyle(
        color: AppColors.darkBrown,
        fontWeight: FontWeight.w700,
        fontSize: 32,
        height: 1.2,
      ),
      headlineMedium: const TextStyle(
        color: AppColors.darkBrown,
        fontWeight: FontWeight.w700,
        fontSize: 24,
        height: 1.3,
      ),
      headlineSmall: const TextStyle(
        color: AppColors.darkBrown,
        fontWeight: FontWeight.w600,
        fontSize: 20,
      ),

      // Titles
      titleLarge: const TextStyle(
        color: AppColors.darkBrown,
        fontWeight: FontWeight.w700,
        fontSize: 18,
      ),
      titleMedium: const TextStyle(
        color: AppColors.darkBrown,
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
      titleSmall: const TextStyle(
        color: AppColors.darkBrown,
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),

      // Body
      bodyLarge: const TextStyle(
        color: AppColors.ink900,
        fontSize: 16,
        height: 1.5,
      ),
      bodyMedium: const TextStyle(
        color: AppColors.ink600,
        fontSize: 14,
        height: 1.4,
      ),
      bodySmall: const TextStyle(color: AppColors.ink600, fontSize: 12),

      // Labels
      labelLarge: const TextStyle(
        color: AppColors.darkBrown,
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
      labelMedium: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
    ),

    // AppBar theme
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.offWhite,
      foregroundColor: AppColors.darkBrown,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: AppColors.darkBrown,
        fontWeight: FontWeight.w600,
        fontSize: 18,
      ),
    ),

    // Button themes
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.gold,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.grey[300],
        disabledForegroundColor: Colors.grey[500],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Layout.buttonRadius),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
        elevation: 2,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.darkBrown,
        side: BorderSide(color: AppColors.darkBrown.withOpacity(0.2)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Layout.buttonRadius),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      ),
    ),

    // Card theme
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Layout.cardRadius),
      ),
      margin: const EdgeInsets.symmetric(
        horizontal: Layout.gutter,
        vertical: Layout.gutterSmall,
      ),
    ),

    // Input decoration theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Layout.cardRadius),
        borderSide: BorderSide(color: AppColors.darkBrown.withOpacity(0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Layout.cardRadius),
        borderSide: BorderSide(color: AppColors.darkBrown.withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Layout.cardRadius),
        borderSide: const BorderSide(color: AppColors.gold, width: 2),
      ),
      contentPadding: const EdgeInsets.all(16),
    ),

    // Scaffold
    scaffoldBackgroundColor: AppColors.offWhite,

    // Divider
    dividerColor: AppColors.darkBrown.withOpacity(0.1),
  );
}
