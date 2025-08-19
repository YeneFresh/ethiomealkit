import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'sentry_service.dart';

class AuthEventLogger {
  static const int _debounceMs = 4000; // 4 seconds debounce
  static final Map<String, DateTime> _lastEventTimes = {};

  // Check if we should debounce this event
  static bool _shouldDebounce(String eventKey) {
    final now = DateTime.now();
    final lastTime = _lastEventTimes[eventKey];
    
    if (lastTime != null) {
      final difference = now.difference(lastTime).inMilliseconds;
      if (difference < _debounceMs) {
        return true; // Should debounce
      }
    }
    
    _lastEventTimes[eventKey] = now;
    return false;
  }

  // Log auth event to database and Sentry
  static Future<void> logEvent({
    required String event,
    required String provider,
    String? route,
    String? errorCode,
    Map<String, dynamic>? metadata,
  }) async {
    // Debounce check
    final eventKey = '${event}_${provider}_${route ?? 'unknown'}';
    if (_shouldDebounce(eventKey)) {
      return; // Skip logging due to debouncing
    }

    try {
      // Get current user ID if available
      final user = Supabase.instance.client.auth.currentUser;
      final userId = user?.id;
      final email = user?.email;

      // Prepare metadata
      final fullMetadata = {
        'platform': kIsWeb ? 'web' : 'mobile',
        'timestamp': DateTime.now().toIso8601String(),
        'user_agent': kIsWeb ? 'web' : 'mobile_app',
        ...?metadata,
      };

      // Log to database via RPC
      if (user != null) {
        try {
          await Supabase.instance.client.rpc(
            'log_auth_event',
            params: {
              'p_event': event,
              'p_provider': provider,
              'p_route': route,
              'p_error_code': errorCode,
              'p_metadata': fullMetadata,
            },
          );
        } catch (e) {
          // If database logging fails, still log to Sentry
          SentryService.trackAuthError(
            provider: provider,
            errorCode: 'logging_failed',
            errorMessage: 'Failed to log auth event to database: $e',
            route: route,
            userId: userId,
            metadata: fullMetadata,
          );
        }
      }

      // Log to Sentry
      if (errorCode != null) {
        SentryService.trackAuthError(
          provider: provider,
          errorCode: errorCode,
          errorMessage: 'Auth event: $event',
          route: route,
          userId: userId,
          metadata: fullMetadata,
        );
      } else {
        SentryService.trackAuthSuccess(
          provider: provider,
          route: route,
          userId: userId,
          metadata: fullMetadata,
        );
      }

      // Set user context in Sentry if authenticated
      if (userId != null) {
        SentryService.setUserContext(
          userId: userId,
          email: email,
          additionalData: {
            'provider': provider,
            'last_event': event,
            'last_route': route,
          },
        );
      }
    } catch (e) {
      // Fallback: log to Sentry if everything else fails
      SentryService.trackAuthError(
        provider: provider,
        errorCode: 'logging_exception',
        errorMessage: 'Exception in AuthEventLogger: $e',
        route: route,
        metadata: metadata,
      );
    }
  }

  // Convenience methods for common auth events
  static Future<void> logMagicLinkSent({
    String? route,
    Map<String, dynamic>? metadata,
  }) async {
    await logEvent(
      event: 'link_sent',
      provider: 'magic_link',
      route: route,
      metadata: metadata,
    );
  }

  static Future<void> logSignInSuccess({
    required String provider,
    String? route,
    Map<String, dynamic>? metadata,
  }) async {
    await logEvent(
      event: 'signin_success',
      provider: provider,
      route: route,
      metadata: metadata,
    );
  }

  static Future<void> logSignInError({
    required String provider,
    required String errorCode,
    required String errorMessage,
    String? route,
    Map<String, dynamic>? metadata,
  }) async {
    await logEvent(
      event: 'signin_error',
      provider: provider,
      route: route,
      errorCode: errorCode,
      metadata: {
        'error_message': errorMessage,
        ...?metadata,
      },
    );
  }

  static Future<void> logSignUpSuccess({
    required String provider,
    String? route,
    Map<String, dynamic>? metadata,
  }) async {
    await logEvent(
      event: 'signup_success',
      provider: provider,
      route: route,
      metadata: metadata,
    );
  }

  static Future<void> logSignUpError({
    required String provider,
    required String errorCode,
    required String errorMessage,
    String? route,
    Map<String, dynamic>? metadata,
  }) async {
    await logEvent(
      event: 'signup_error',
      provider: provider,
      route: route,
      errorCode: errorCode,
      metadata: {
        'error_message': errorMessage,
        ...?metadata,
      },
    );
  }

  static Future<void> logPasswordReset({
    String? route,
    Map<String, dynamic>? metadata,
  }) async {
    await logEvent(
      event: 'password_reset',
      provider: 'password',
      route: route,
      metadata: metadata,
    );
  }

  static Future<void> logLogout({
    String? route,
    Map<String, dynamic>? metadata,
  }) async {
    await logEvent(
      event: 'logout',
      provider: 'session',
      route: route,
      metadata: metadata,
    );
    
    // Clear Sentry user context
    SentryService.clearUserContext();
  }

  static Future<void> logBiometricAuth({
    required bool success,
    String? errorCode,
    String? route,
    Map<String, dynamic>? metadata,
  }) async {
    if (success) {
      await logEvent(
        event: 'signin_success',
        provider: 'biometric',
        route: route,
        metadata: metadata,
      );
    } else {
      await logEvent(
        event: 'signin_error',
        provider: 'biometric',
        route: route,
        errorCode: errorCode ?? 'biometric_failed',
        metadata: metadata,
      );
    }
  }
}

