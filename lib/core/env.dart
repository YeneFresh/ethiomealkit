import 'package:flutter/foundation.dart';
import 'package:ethiomealkit/bootstrap/env.dart' as bootstrap;

class Env {
  static Future<void> load() async {
    // Fail-fast guard in debug/profile; no-op in release because asserts are stripped
    assert(() {
      bootstrap.Env.assertRequired();
      return true;
    }());
    // For Flutter web, .env files are not loaded at runtime
    // Use hardcoded values or build-time environment injection
    if (kDebugMode) {
      debugPrint('Connecting to production Supabase database');
    }
  }

  // Supabase project configuration - Production
  static String get supabaseUrl => 'https://dtpoaskptvsabptisamp.supabase.co';

  // Supabase anon key - Production
  static String get supabaseAnonKey =>
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR0cG9hc2twdHZzYWJwdGlzYW1wIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ3MzA0NDksImV4cCI6MjA3MDMwNjQ0OX0.Nxh4b4YVcQBnLD8MX_5s9pUMGrV2-MceOwlfbCkpyXU';

  // Use real database for production
  static bool get useMocks => false;

  // =============================================================================
  // APP METADATA
  // =============================================================================

  /// App version (semantic versioning)
  /// Update in pubspec.yaml version field
  static String get appVersion {
    const value = String.fromEnvironment('APP_VERSION', defaultValue: '1.0.0');
    return value;
  }

  /// Build number (monotonic, increment every build)
  /// Update in pubspec.yaml version field after '+'
  static String get buildNumber {
    const value = String.fromEnvironment('BUILD_NUMBER', defaultValue: '10001');
    return value;
  }

  /// Full version string (e.g., "1.0.0 (10001)")
  static String get fullVersion => '$appVersion ($buildNumber)';

  // =============================================================================
  // FEATURE FLAGS
  // =============================================================================

  /// Showcase mode for investor demos
  static bool get showcaseMode {
    const value = String.fromEnvironment('SHOWCASE', defaultValue: 'false');
    return value.toLowerCase() == 'true';
  }

  // Hardened validation helper
  static bool get hasValidSupabase {
    final url = supabaseUrl;
    final key = supabaseAnonKey;

    return !useMocks &&
        url.isNotEmpty &&
        (url.startsWith('https://') ||
            url.startsWith('http://localhost') ||
            url.startsWith('http://127.0.0.1')) &&
        key.isNotEmpty &&
        key.length > 50;
  }

  // Debug helper
  static String getConfigStatus() {
    final url = supabaseUrl;
    final key = supabaseAnonKey;
    final mocks = useMocks;

    if (mocks) {
      return 'Using mocks (USE_MOCKS=true)';
    }

    if (url.isEmpty) {
      return 'SUPABASE_URL is empty';
    }

    if (key.isEmpty) {
      return 'SUPABASE_ANON_KEY is empty';
    }

    if (hasValidSupabase) {
      return 'Configuration is valid - Supabase is properly configured';
    }

    return 'Configuration appears valid';
  }
}
