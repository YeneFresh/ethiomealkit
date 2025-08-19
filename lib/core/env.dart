import 'package:flutter/foundation.dart';

class Env {
  static Future<void> load() async {
    // For Flutter web, .env files are not loaded at runtime
    // Use hardcoded values or build-time environment injection
    if (kDebugMode) {
      debugPrint('Using hardcoded Supabase credentials for Flutter web');
    }
  }

  // Supabase project configuration
  static String get supabaseUrl => 'https://dtpoaskptvsabptisamp.supabase.co';

  // Supabase anon key
  static String get supabaseAnonKey =>
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR0cG9hc2twdHZzYWJwdGlzYW1wIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ3MzA0NDksImV4cCI6MjA3MDMwNjQ0OX0.Nxh4b4YVcQBnLD8MX_5s9pUMGrV2-MceOwlfbCkpyXU';

  static bool get useMocks => false; // No mocks for production

  // Hardened validation helper
  static bool get hasValidSupabase {
    final url = supabaseUrl;
    final key = supabaseAnonKey;

    return !useMocks &&
        url.isNotEmpty &&
        url.startsWith('https://') &&
        url.contains('.supabase.co') &&
        key.isNotEmpty &&
        key.length > 100;
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
