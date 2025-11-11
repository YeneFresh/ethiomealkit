// lib/core/flags.dart
class Flags {
  /// Set true locally to see /admin routes. Keep false on main/prod.
  static const adminEnabled = bool.fromEnvironment('ADMIN_ENABLED', defaultValue: false);
}