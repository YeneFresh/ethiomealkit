/// Delivery slot entity (domain model)
class DeliverySlot {
  final String id;
  final DateTime startAt;
  final DateTime endAt;
  final String city;
  final int capacity;
  final int bookedCount;
  final bool isActive;

  const DeliverySlot({
    required this.id,
    required this.startAt,
    required this.endAt,
    required this.city,
    required this.capacity,
    required this.bookedCount,
    this.isActive = true,
  });

  bool get hasCapacity => capacity > bookedCount;

  bool get isSelectable => isActive && hasCapacity && !isCutoff;

  /// Check if slot is past cutoff (48 hours)
  bool get isCutoff {
    final now = DateTime.now();
    final cutoffLimit = now.add(const Duration(hours: 48));
    return !startAt.isAfter(cutoffLimit);
  }

  String get slot {
    final startHour = startAt.hour.toString().padLeft(2, '0');
    final endHour = endAt.hour.toString().padLeft(2, '0');
    return '$startHour-$endHour';
  }

  String get group {
    final hour = startAt.hour;
    if (hour >= 6 && hour < 12) return 'Morning';
    if (hour >= 12 && hour < 17) return 'Afternoon';
    return 'Evening';
  }

  String get dayLabel {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays[startAt.weekday - 1];
  }

  String? get disabledReason {
    if (!isActive) return 'Unavailable';
    if (!hasCapacity) return 'Full';
    if (isCutoff) return 'Past cutoff (48h)';
    return null;
  }

  DeliverySlot copyWith({
    String? id,
    DateTime? startAt,
    DateTime? endAt,
    String? city,
    int? capacity,
    int? bookedCount,
    bool? isActive,
  }) {
    return DeliverySlot(
      id: id ?? this.id,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      city: city ?? this.city,
      capacity: capacity ?? this.capacity,
      bookedCount: bookedCount ?? this.bookedCount,
      isActive: isActive ?? this.isActive,
    );
  }
}
