import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Delivery Gate Provider
final deliveryGateProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final supabase = Supabase.instance.client;
  try {
    final response = await supabase.rpc('user_delivery_readiness');
    return response as Map<String, dynamic>?;
  } catch (e) {
    return null;
  }
});

// Delivery Windows Provider
final deliveryWindowsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final supabase = Supabase.instance.client;
  try {
    final response = await supabase
        .from('delivery_windows')
        .select()
        .order('day_of_week')
        .order('start_time');
    return List<Map<String, dynamic>>.from(response);
  } catch (e) {
    return [];
  }
});

// Stage Delivery Controller
final stageDeliveryController = Provider((ref) {
  return (String addressLabel, String windowId) async {
    final supabase = Supabase.instance.client;
    final result = await supabase.rpc('stage_delivery_choice', params: {
      'address_label': addressLabel,
      'window_id': windowId,
    });
    // Invalidate the delivery gate provider to refresh the UI
    ref.invalidate(deliveryGateProvider);
    return result;
  };
});

// Confirm Delivery Controller
final confirmDeliveryController = Provider((ref) {
  return () async {
    final supabase = Supabase.instance.client;
    final result = await supabase.rpc('confirm_delivery_choice');
    // Invalidate both providers to refresh the UI
    ref.invalidate(deliveryGateProvider);
    ref.invalidate(weeklyMenuProvider);
    return result;
  };
});

// Weekly Menu Provider (placeholder for now)
final weeklyMenuProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  // This would load the weekly menu once delivery is confirmed
  return [];
});
