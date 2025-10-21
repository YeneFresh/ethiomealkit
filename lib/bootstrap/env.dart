import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const sentryDsn = String.fromEnvironment('SENTRY_DSN', defaultValue: '');
  static const appEnv = String.fromEnvironment('APP_ENV', defaultValue: 'dev');

  static void assertRequired() {
    final missing = <String>[];
    if (supabaseUrl.isEmpty) missing.add('SUPABASE_URL');
    if (supabaseAnonKey.isEmpty) missing.add('SUPABASE_ANON_KEY');

    if (appEnv == 'prod') {
      if (kDebugMode) {
        throw StateError('APP_ENV=prod but build is Debug. Use a Release build.');
      }
      if (sentryDsn.isEmpty) missing.add('SENTRY_DSN (required in prod)');
    }

    if (missing.isNotEmpty) {
      final msg = [
        'Missing required --dart-define(s): ${missing.join(', ')}',
        'Example:',
        'flutter run --dart-define=SUPABASE_URL=https://xxx.supabase.co '
            '--dart-define=SUPABASE_ANON_KEY=*** '
            '--dart-define=APP_ENV=dev --dart-define=SENTRY_DSN=',
      ].join('\n');
      throw StateError(msg);
    }
  }

  static Map<String, String> asTags() => {
        'app_env': appEnv,
        if (kReleaseMode) 'build_mode': 'release' else 'build_mode': 'debug',
        if (!kIsWeb) 'platform': Platform.operatingSystem,
      };
}


