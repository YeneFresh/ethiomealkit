import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ethiomealkit/features/delivery/models/delivery_models.dart';

class DeliveryRepository {
  final SupabaseClient sb;
  DeliveryRepository(this.sb);

  /// Get current user's window (null if not set)
  Future<DeliveryWindow?> getCurrent(String userId, DateTime week) async {
    try {
      final res = await sb.rpc(
        'get_current_user_window',
        params: {'p_user': userId, 'p_week': week.toIso8601String()},
      );
      return _fromRpc(res);
    } catch (e) {
      print('ℹ️ get_current_user_window RPC not available: $e');
      return null; // Graceful degradation
    }
  }

  /// Recommend a smart default window
  Future<DeliveryWindow> recommend(String userId, DateTime week) async {
    try {
      final res = await sb.rpc(
        'recommend_user_window',
        params: {'p_user': userId, 'p_week': week.toIso8601String()},
      );
      return _fromRpc(res)!;
    } catch (e) {
      print('ℹ️ recommend_user_window RPC not available, using fallback: $e');
      // Fallback: Thursday afternoon, 2 days from now
      return DeliveryWindow(
        date: DateTime.now().add(const Duration(days: 2)),
        daypart: DeliveryDaypart.afternoon,
        location: DeliveryLocation.home,
      );
    }
  }

  /// Set user's window (idempotent upsert)
  Future<DeliveryWindow> setWindow({
    required String userId,
    required DateTime week,
    required String locationId, // 'home' | 'office'
    required String daypart, // 'morning' | 'afternoon'
    required DateTime date,
  }) async {
    try {
      final res = await sb.rpc(
        'set_user_window',
        params: {
          'p_user': userId,
          'p_week': week.toIso8601String(),
          'p_location': locationId,
          'p_daypart': daypart,
          'p_date': date.toIso8601String(),
        },
      );
      return _fromRpc(res)!;
    } catch (e) {
      print('ℹ️ set_user_window RPC not available, using local-only: $e');
      // Local-only mode: return what user selected
      final dp = daypart == 'morning'
          ? DeliveryDaypart.morning
          : DeliveryDaypart.afternoon;
      final loc = locationId == 'home'
          ? DeliveryLocation.home
          : DeliveryLocation.office;
      return DeliveryWindow(date: date, daypart: dp, location: loc);
    }
  }

  DeliveryWindow? _fromRpc(dynamic json) {
    if (json == null) return null;
    final dp = (json['daypart'] as String) == 'morning'
        ? DeliveryDaypart.morning
        : DeliveryDaypart.afternoon;
    final locId = json['location_id'] as String; // 'home' or 'office'
    final loc = locId == 'home'
        ? DeliveryLocation.home
        : DeliveryLocation.office;
    final date = DateTime.parse(json['date'] as String);
    return DeliveryWindow(date: date, daypart: dp, location: loc);
  }
}
