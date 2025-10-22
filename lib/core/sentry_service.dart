import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;

class SentryService {
  static const String _dsn = ''; // Disabled for now - set to your actual DSN when ready
  
  static Future<void> init() async {
    // Only initialize if DSN is provided
    if (_dsn.isEmpty) return;
    
    await SentryFlutter.init(
      (options) {
        options.dsn = _dsn;
        options.tracesSampleRate = 1.0;
        options.enableAutoSessionTracking = true;
        options.attachStacktrace = true;
        options.debug = kDebugMode;
        
        // Add auth context
        options.beforeSend = (event, hint) {
          // Add app context
          event.tags?['platform'] = kIsWeb ? 'web' : 'mobile';
          event.tags?['app'] = 'yenefresh';
          return event;
        };
      },
    );
  }

  // Add breadcrumb for auth flow tracking
  static void addAuthBreadcrumb({
    required String action,
    required String provider,
    String? route,
    String? userId,
    Map<String, dynamic>? metadata,
  }) {
    Sentry.addBreadcrumb(
      Breadcrumb(
        message: 'Auth: $action',
        category: 'auth',
        type: 'debug',
        data: {
          'action': action,
          'provider': provider,
          'route': route,
          'user_id': userId,
          'platform': kIsWeb ? 'web' : 'mobile',
          ...?metadata,
        },
        level: SentryLevel.info,
      ),
    );
  }

  // Track auth success
  static void trackAuthSuccess({
    required String provider,
    String? route,
    String? userId,
    Map<String, dynamic>? metadata,
  }) {
    addAuthBreadcrumb(
      action: 'success',
      provider: provider,
      route: route,
      userId: userId,
      metadata: metadata,
    );
    
    Sentry.addBreadcrumb(
      Breadcrumb(
        message: 'Authentication successful',
        category: 'auth',
        type: 'info',
        data: {
          'provider': provider,
          'route': route,
          'user_id': userId,
          'status': 'success',
        },
        level: SentryLevel.info,
      ),
    );
  }

  // Track auth error
  static void trackAuthError({
    required String provider,
    required String errorCode,
    required String errorMessage,
    String? route,
    String? userId,
    Map<String, dynamic>? metadata,
  }) {
    addAuthBreadcrumb(
      action: 'error',
      provider: provider,
      route: route,
      userId: userId,
      metadata: {
        'error_code': errorCode,
        'error_message': errorMessage,
        ...?metadata,
      },
    );

    // Capture the error
    Sentry.captureException(
      Exception('Auth Error: $errorMessage'),
      hint: Hint.withMap({
        'provider': provider,
        'error_code': errorCode,
        'route': route,
        'user_id': userId,
        'category': 'auth',
        ...?metadata,
      }),
    );
  }

  // Track route navigation
  static void trackRouteChange({
    required String fromRoute,
    required String toRoute,
    String? userId,
  }) {
    Sentry.addBreadcrumb(
      Breadcrumb(
        message: 'Route changed: $fromRoute → $toRoute',
        category: 'navigation',
        type: 'navigation',
        data: {
          'from_route': fromRoute,
          'to_route': toRoute,
          'user_id': userId,
        },
        level: SentryLevel.info,
      ),
    );
  }

  // Set user context for authenticated users
  static void setUserContext({
    required String userId,
    String? email,
    Map<String, dynamic>? additionalData,
  }) {
    Sentry.configureScope((scope) {
      scope.setUser(SentryUser(
        id: userId,
        email: email,
        data: additionalData,
      ));
    });
  }

  // Clear user context on logout
  static void clearUserContext() {
    Sentry.configureScope((scope) {
      scope.setUser(null);
    });
  }

  // Add performance monitoring for auth flows
  static ISentrySpan? startAuthSpan({
    required String operation,
    required String provider,
    String? route,
  }) {
    final transaction = Sentry.startTransaction(
      operation,
      'auth',
      bindToScope: true,
    );

    transaction.setTag('provider', provider);
    if (route != null) transaction.setTag('route', route);
    transaction.setTag('platform', kIsWeb ? 'web' : 'mobile');

    return transaction;
  }

  // Finish auth span
  static void finishAuthSpan(ISentrySpan? span, {bool success = true}) {
    if (span != null) {
      span.setTag('success', success.toString());
      span.finish();
    }
  }
}
