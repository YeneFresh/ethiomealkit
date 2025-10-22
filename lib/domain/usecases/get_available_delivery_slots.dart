import '../entities/delivery_slot.dart';
import '../repositories/delivery_repository.dart';

/// Use case: Get available delivery slots with business rules applied
class GetAvailableDeliverySlots {
  final DeliveryRepository _repo;

  GetAvailableDeliverySlots(this._repo);

  Future<List<DeliverySlot>> call({
    required String city,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final from = fromDate ?? DateTime.now();
    final to = toDate ?? from.add(const Duration(days: 28));

    final slots = await _repo.fetchAvailableSlots(
      city: city,
      fromDate: from,
      toDate: to,
    );

    // Business rules applied at domain level
    return slots.where((slot) => slot.isActive).toList();
  }

  /// Get recommended slot (business logic)
  DeliverySlot? getRecommended(List<DeliverySlot> slots) {
    // Prefer afternoon slots (14-16) that are selectable
    final afternoon = slots
        .where((s) =>
            s.group == 'Afternoon' &&
            s.slot.contains('14-16') &&
            s.isSelectable)
        .toList();

    if (afternoon.isNotEmpty) return afternoon.first;

    // Fallback: first selectable slot
    return slots.firstWhere(
      (s) => s.isSelectable,
      orElse: () => slots.isNotEmpty
          ? slots.first
          : throw Exception('No delivery slots available'),
    );
  }
}



