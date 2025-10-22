import '../entities/delivery_slot.dart';

/// Delivery repository interface (domain contract)
abstract class DeliveryRepository {
  Future<List<DeliverySlot>> fetchAvailableSlots({
    required String city,
    required DateTime fromDate,
    required DateTime toDate,
  });

  Future<DeliverySlot?> getUserSelectedSlot(String userId);

  Future<void> setUserSlot({
    required String userId,
    required String slotId,
    required String addressId,
  });
}



