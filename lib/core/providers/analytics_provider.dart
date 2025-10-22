import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/analytics_service.dart';

/// Analytics service provider
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService(Supabase.instance.client);
});

/// Helper: Track event from anywhere in the app
extension AnalyticsRef on Ref {
  Future<void> trackEvent(String eventName, [Map<String, dynamic>? properties]) {
    return read(analyticsServiceProvider).track(eventName, properties);
  }
}




