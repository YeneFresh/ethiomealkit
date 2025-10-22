import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ethiomealkit/bootstrap/env.dart';

class SupaBootstrap {
  static Future<void> init() async {
    try {
      await Supabase.initialize(
        url: Env.supabaseUrl,
        anonKey: Env.supabaseAnonKey,
        debug: kDebugMode,
      );
    } catch (_) {
      // Already initialized; noop
    }
  }

  static SupabaseClient get client => Supabase.instance.client;
}
