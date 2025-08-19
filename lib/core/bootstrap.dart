import 'package:logging/logging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../api/api_client.dart';
import '../api/mock_api_client.dart';
import '../api/supabase_api_client.dart';
import 'env.dart';

/// Bootstrap function to initialize the backend and return the appropriate API client
Future<ApiClient> initBackend({Logger? logger}) async {
  // Load environment variables
  await Env.load();

  // Log configuration status in debug mode
  if (logger != null) {
    logger.info('🔍 Environment check:');
    logger.info('  URL: ${Env.supabaseUrl}');
    logger.info('  Key length: ${Env.supabaseAnonKey.length}');
    logger.info('  Use mocks: ${Env.useMocks}');
    logger.info('  Has valid Supabase: ${Env.hasValidSupabase}');
    logger.info('  Config status: ${Env.getConfigStatus()}');
  }

  // Check if we should use Supabase
  if (Env.hasValidSupabase) {
    try {
      await Supabase.initialize(
        url: Env.supabaseUrl,
        anonKey: Env.supabaseAnonKey,
      );
      if (logger != null) {
        logger.info('✅ Using Supabase backend');
      }
      return SupabaseApiClient();
    } catch (e) {
      if (logger != null) {
        logger.warning(
            '⚠️ Failed to initialize Supabase, falling back to mock backend: $e');
      }
      return MockApiClient();
    }
  } else {
    if (logger != null) {
      logger.info('🔧 Using mock backend (${Env.getConfigStatus()})');
    }
    return MockApiClient();
  }
}
