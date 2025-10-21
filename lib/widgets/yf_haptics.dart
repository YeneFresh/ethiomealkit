import 'package:flutter/services.dart';

class YfHaptics {
  static Future<void> tap() async => HapticFeedback.selectionClick();
  static Future<void> success() async => HapticFeedback.lightImpact();
  static Future<void> warning() async => HapticFeedback.mediumImpact();
  static Future<void> error() async => HapticFeedback.heavyImpact();
}


