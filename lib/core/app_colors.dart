import 'package:flutter/material.dart';

/// YeneFresh brand color palette - shared across all components
class AppColors {
  AppColors._(); // Private constructor

  // Primary brand colors (onboarding stepper)
  static const gold = Color(0xFFD4AF37); // YeneFresh Gold
  static const darkBrown = Color(0xFF4A2C00); // Dark Brown
  static const offWhite = Color(0xFFFFFAF3); // Soft off-white background

  // Browns (primary brand) - legacy compatibility
  static const brown900 = Color(0xFF3A2415);
  static const brown700 = Color(0xFF5A371F);
  static const brown600 = Color(0xFF8B4513);
  static const brown = brown600; // Legacy alias

  // Golds (accent) - legacy compatibility
  static const gold600 = Color(0xFFB8860B);

  // Peach (surfaces, warmth)
  static const peach50 = Color(0xFFFFF8F0);
  static const peach100 = Color(0xFFFFF4E6);
  static const cream = Color(0xFFFFF8E1);

  // Semantic colors
  static const success600 = Color(0xFF2E7D32);
  static const error600 = Color(0xFFD32F2F);
  static const warning600 = Color(0xFFF57C00);
  static const info600 = Color(0xFF1976D2);

  // Neutral
  static const ink900 = Color(0xFF1A1A1A);
  static const ink600 = Color(0xFF666666);
  static const grey = Color(0xFF90A4AE);

  // Typography
  static TextStyle get titleStyle =>
      const TextStyle(fontWeight: FontWeight.w700, fontSize: 18);

  static TextStyle get subtitleStyle =>
      const TextStyle(fontWeight: FontWeight.w500, fontSize: 13);
}
