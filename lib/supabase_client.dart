import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ethiomealkit/core/env.dart';

class SupabaseConfig {
  static bool get isInitialized {
    try {
      // Check if Supabase instance exists and has been initialized
      final hasValidUrl =
          Env.supabaseUrl.isNotEmpty && !Env.supabaseUrl.contains('<your-ref>');
      final hasValidKey =
          Env.supabaseAnonKey.isNotEmpty &&
          !Env.supabaseAnonKey.contains('<your-anon-public-key>');
      return hasValidUrl && hasValidKey && !Env.useMocks;
    } catch (e) {
      return false;
    }
  }

  static bool get isConfigured => isInitialized;

  static SupabaseClient? get client {
    try {
      return isInitialized ? Supabase.instance.client : null;
    } catch (e) {
      return null;
    }
  }

  // Safe getter that throws a meaningful error if not initialized
  static SupabaseClient get safeClient {
    final client = SupabaseConfig.client;
    if (client == null) {
      throw StateError(
        'Supabase is not initialized. Make sure to configure your .env file with valid Supabase credentials.',
      );
    }
    return client;
  }
}
