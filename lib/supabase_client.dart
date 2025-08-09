import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static bool get isInitialized {
    try {
      return Supabase.instance.client.restUrl.isNotEmpty;
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
      throw StateError('Supabase is not initialized. Make sure to configure your .env file with valid Supabase credentials.');
    }
    return client;
  }
}



