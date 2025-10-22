import 'package:supabase_flutter/supabase_flutter.dart';
import 'env.dart';

class SupaBootstrap {
  static Future<void> init() async {
    if (Supabase.instance.client.auth.currentSession != null) return;
    await Supabase.initialize(
        url: Env.supabaseUrl, anonKey: Env.supabaseAnonKey);
  }
}
