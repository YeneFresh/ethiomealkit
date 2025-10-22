import 'package:flutter/material.dart';

class YfColors {
  static const brown = Color(0xFF6D4C41);
  static const gold = Color(0xFFFFC107);
}

ThemeData buildLightTheme() {
  final base = ThemeData(useMaterial3: true, colorSchemeSeed: YfColors.brown);
  return base.copyWith(
    colorScheme: base.colorScheme.copyWith(
      primary: YfColors.brown,
      secondary: YfColors.gold,
    ),
    scaffoldBackgroundColor: Colors.white,
    cardTheme: const CardThemeData(elevation: 1),
  );
}

ThemeData buildDarkTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    colorScheme: base.colorScheme.copyWith(
      primary: YfColors.brown,
      secondary: YfColors.gold,
    ),
  );
}
