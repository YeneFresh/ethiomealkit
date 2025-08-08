import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static bool get isConfigured => Supabase.instance.client.restUrl.isNotEmpty;
  static SupabaseClient get client => Supabase.instance.client;
}



