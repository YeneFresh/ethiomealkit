import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ethiomealkit/domain/entities/delivery_slot.dart';
import 'package:ethiomealkit/domain/repositories/delivery_repository.dart';
import 'package:ethiomealkit/data/dtos/delivery_slot_dto.dart';

/// Supabase implementation of DeliveryRepository
class DeliveryRepositorySupabase implements DeliveryRepository {
  final SupabaseClient _sb;

  DeliveryRepositorySupabase(this._sb);

  @override
  Future<List<DeliverySlot>> fetchAvailableSlots({
    required String city,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    try {
      final res = await _sb
          .from('delivery_windows')
          .select('*')
          .eq('city', city)
          .eq('is_active', true)
          .gte('start_at', fromDate.toUtc().toIso8601String())
          .lte('start_at', toDate.toUtc().toIso8601String())
          .order('start_at');

      return (res as List)
          .map((json) => DeliverySlotDto.fromJson(json).toEntity())
          .toList();
    } catch (e) {
      print('❌ Error fetching delivery slots: $e');
      return [];
    }
  }

  @override
  Future<DeliverySlot?> getUserSelectedSlot(String userId) async {
    try {
      final res = await _sb
          .from('user_delivery_windows')
          .select('window_id, delivery_windows(*)')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (res == null) return null;

      final windowData = res['delivery_windows'];
      if (windowData == null) return null;

      return DeliverySlotDto.fromJson(windowData).toEntity();
    } catch (e) {
      print('❌ Error fetching user delivery slot: $e');
      return null;
    }
  }

  @override
  Future<void> setUserSlot({
    required String userId,
    required String slotId,
    required String addressId,
  }) async {
    try {
      await _sb.rpc(
        'upsert_user_delivery_preference',
        params: {
          'p_user_id': userId,
          'p_window_id': slotId,
          'p_address_id': addressId,
        },
      );
      print('✅ Set delivery slot: $slotId for $addressId');
    } catch (e) {
      print('❌ Error setting delivery slot: $e');
      rethrow;
    }
  }
}
