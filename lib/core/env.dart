import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static Future<void> load() async {
    await dotenv.load(fileName: ".env");
  }
  
  static String get supabaseUrl =>
      dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey =>
      dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  static bool get useMocks =>
      (dotenv.env['USE_MOCKS'] ?? 'false').toLowerCase() == 'true';
      
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
    
    if (url.contains('<your-ref>')) {
      return 'SUPABASE_URL contains placeholder - needs real project URL';
    }
    
    if (key.isEmpty) {
      return 'SUPABASE_ANON_KEY is empty';
    }
    
    if (key.contains('<your-anon-public-key>')) {
      return 'SUPABASE_ANON_KEY contains placeholder - needs real anon key';
    }
    
    return 'Configuration appears valid';
  }
}



