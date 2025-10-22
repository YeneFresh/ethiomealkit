import 'package:flutter/material.dart';
import 'package:ethiomealkit/core/app_colors.dart';

/// Ethiopian-inspired tag color tokens for recipe categories
class TagTokens {
  TagTokens._(); // Private constructor

  static const Map<String, Color> bg = {
    "Chef's Choice": Color(0xFFFFF3D6),
    "Gourmet": Color(0xFFEDE7F6),
    "Express": Color(0xFFE3F2FD),
    "Spicy": Color(0xFFFFEBEE),
    "Vegan": Color(0xFFE8F5E9),
    "Veggie": Color(0xFFEAF6ED),
    "Family Friendly": Color(0xFFF1F8E9),
    "Calorie Smart": Color(0xFFE0F7FA),
    "Breakfast": Color(0xFFFFF8E1),
    "Popular": Color(0xFFFFF3E0),
    "Quick Dinner": Color(0xFFE3F2FD),
    "High Protein": Color(0xFFE8EAF6),
    "Protein Rich": Color(0xFFE8EAF6),
    "Healthy": Color(0xFFE8F5E9),
    "Light": Color(0xFFE8F5E9),
    "Classic": Color(0xFFFFF3E0),
    "Everyday": Color(0xFFF5F5F5),
    "Low Calorie": Color(0xFFE0F2F1),
  };

  static const Map<String, Color> fg = {
    "Chef's Choice": AppColors.darkBrown,
    "Gourmet": Color(0xFF4A148C),
    "Express": Color(0xFF0D47A1),
    "Spicy": Color(0xFFB71C1C),
    "Vegan": Color(0xFF1B5E20),
    "Veggie": Color(0xFF2E7D32),
    "Family Friendly": Color(0xFF33691E),
    "Calorie Smart": Color(0xFF006064),
    "Breakfast": Color(0xFFEF6C00),
    "Popular": Color(0xFFBF360C),
    "Quick Dinner": Color(0xFF01579B),
    "High Protein": Color(0xFF283593),
    "Protein Rich": Color(0xFF283593),
    "Healthy": Color(0xFF1B5E20),
    "Light": Color(0xFF2E7D32),
    "Classic": Color(0xFF6D4C41),
    "Everyday": Color(0xFF5F6368),
    "Low Calorie": Color(0xFF004D40),
  };

  /// Get background color for a tag
  static Color bgFor(String tag) => bg[tag] ?? const Color(0xFFF1F3F4);

  /// Get foreground (text) color for a tag
  static Color fgFor(String tag) => fg[tag] ?? const Color(0xFF5F6368);
}
