import 'package:ethiomealkit/domain/entities/delivery_slot.dart';

/// Delivery slot Data Transfer Object (DTO)
class DeliverySlotDto {
  final String id;
  final String startAt;
  final String endAt;
  final String city;
  final String slot;
  final int capacity;
  final int bookedCount;
  final bool isActive;

  const DeliverySlotDto({
    required this.id,
    required this.startAt,
    required this.endAt,
    required this.city,
    required this.slot,
    required this.capacity,
    required this.bookedCount,
    this.isActive = true,
  });

  factory DeliverySlotDto.fromJson(Map<String, dynamic> json) {
    return DeliverySlotDto(
      id: json['id'] as String? ?? '',
      startAt: json['start_at'] as String? ?? '',
      endAt: json['end_at'] as String? ?? '',
      city: json['city'] as String? ?? '',
      slot: json['slot'] as String? ?? '',
      capacity: json['capacity'] as int? ?? 0,
      bookedCount: json['booked_count'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  /// Convert DTO to domain entity
  DeliverySlot toEntity() {
    return DeliverySlot(
      id: id,
      startAt: DateTime.parse(startAt).toLocal(),
      endAt: DateTime.parse(endAt).toLocal(),
      city: city,
      capacity: capacity,
      bookedCount: bookedCount,
      isActive: isActive,
    );
  }
}
