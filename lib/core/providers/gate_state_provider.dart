import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ethiomealkit/core/services/persistence_service.dart';

/// Unified delivery gate state for instant onboarding
/// Single source of truth for location, day, window
class GateState {
  final String location; // 'home' | 'office'
  final String locationLabel; // 'Home' | 'Office'
  final String city; // 'Addis Ababa'
  final String? windowId;
  final DateTime? deliveryDate;
  final String? timeSlot; // e.g., '14-16'
  final String? friendlyTime; // e.g., 'Afternoon (2–4 pm)'
  final bool isRecommended;
  final bool isEditable;

  const GateState({
    this.location = 'home',
    this.locationLabel = 'Home',
    this.city = 'Addis Ababa',
    this.windowId,
    this.deliveryDate,
    this.timeSlot,
    this.friendlyTime,
    this.isRecommended = false,
    this.isEditable = true,
  });

  GateState copyWith({
    String? location,
    String? locationLabel,
    String? city,
    String? windowId,
    DateTime? deliveryDate,
    String? timeSlot,
    String? friendlyTime,
    bool? isRecommended,
    bool? isEditable,
  }) {
    return GateState(
      location: location ?? this.location,
      locationLabel: locationLabel ?? this.locationLabel,
      city: city ?? this.city,
      windowId: windowId ?? this.windowId,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      timeSlot: timeSlot ?? this.timeSlot,
      friendlyTime: friendlyTime ?? this.friendlyTime,
      isRecommended: isRecommended ?? this.isRecommended,
      isEditable: isEditable ?? this.isEditable,
    );
  }

  /// Check if gate is ready (has all required info)
  bool get isReady => windowId != null && deliveryDate != null;

  /// Get day label (e.g., "Tomorrow", "Thu, Oct 17")
  String get dayLabel {
    if (deliveryDate == null) return 'Tomorrow';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final deliveryDay = DateTime(
      deliveryDate!.year,
      deliveryDate!.month,
      deliveryDate!.day,
    );

    if (deliveryDay == tomorrow) return 'Tomorrow';

    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${weekdays[deliveryDate!.weekday - 1]}, ${months[deliveryDate!.month - 1]} ${deliveryDate!.day}';
  }
}

/// Gate state controller with auto-selection
class GateStateNotifier extends StateNotifier<GateState> {
  GateStateNotifier() : super(const GateState()) {
    _init();
  }

  Future<void> _init() async {
    // Try to restore from persistence first
    await _loadSavedState();

    // If nothing saved, auto-select recommended
    if (!state.isReady) {
      await autoSelectRecommended();
    }
  }

  Future<void> _loadSavedState() async {
    try {
      final saved = await PersistenceService.loadDeliveryWindow();
      if (saved != null) {
        state = GateState(
          location: 'home',
          locationLabel: 'Home',
          city: saved['city'] as String? ?? 'Addis Ababa',
          windowId: saved['id'] as String?,
          deliveryDate: saved['start_at'] != null
              ? DateTime.parse(saved['start_at'] as String)
              : null,
          timeSlot: _extractSlot(saved),
          friendlyTime: _extractFriendlyTime(saved),
          isRecommended: false,
          isEditable: true,
        );
        print(
          '📂 Restored gate state: ${state.dayLabel} • ${state.friendlyTime}',
        );
      }
    } catch (e) {
      print('⚠️ Could not restore gate state: $e');
    }
  }

  /// Instantly auto-select recommended delivery based on historical patterns
  Future<void> autoSelectRecommended() async {
    try {
      final client = Supabase.instance.client;

      // Fetch available windows (next 7 days, afternoon preferred)
      final response = await client
          .from('delivery_windows')
          .select('*')
          .eq('city', 'Addis Ababa')
          .eq('is_active', true)
          .gte('start_at', DateTime.now().toUtc().toIso8601String())
          .order('start_at')
          .limit(10);

      final windows = response as List<dynamic>;

      if (windows.isEmpty) {
        print('⚠️ No delivery windows available');
        return;
      }

      // Smart selection: Prefer afternoon, next day, with capacity
      final recommended = windows.firstWhere(
        (w) {
          final slot = w['slot']?.toString() ?? '';
          final capacity = (w['capacity'] ?? 0) as int;
          final booked = (w['booked_count'] ?? 0) as int;
          return slot.contains('14-16') && capacity > booked;
        },
        orElse: () => windows.firstWhere(
          (w) => (w['capacity'] as int) > (w['booked_count'] as int),
          orElse: () => windows.first,
        ),
      );

      final startAt = DateTime.parse(
        recommended['start_at'] as String,
      ).toLocal();
      final slot = recommended['slot'] as String? ?? '';

      state = GateState(
        location: 'home',
        locationLabel: 'Home',
        city: 'Addis Ababa',
        windowId: recommended['id'] as String,
        deliveryDate: startAt,
        timeSlot: slot,
        friendlyTime: _formatFriendlyTime(startAt, slot),
        isRecommended: true,
        isEditable: true,
      );

      // Persist for quick restore
      await PersistenceService.saveDeliveryWindow(
        state.windowId!,
        state.locationLabel,
        state.deliveryDate!,
        state.deliveryDate!.add(const Duration(hours: 2)),
        state.city,
      );

      print(
        '✅ Auto-gated: ${state.dayLabel} • ${state.friendlyTime} • ${state.locationLabel}',
      );
    } catch (e) {
      print('❌ Auto-gate failed: $e');
    }
  }

  /// Update location (Home/Office)
  void setLocation(String location, String label) {
    state = state.copyWith(location: location, locationLabel: label);
    _persist();
  }

  /// Update delivery window
  void setWindow({
    required String windowId,
    required DateTime date,
    required String slot,
    bool isRecommended = false,
  }) {
    state = state.copyWith(
      windowId: windowId,
      deliveryDate: date,
      timeSlot: slot,
      friendlyTime: _formatFriendlyTime(date, slot),
      isRecommended: isRecommended,
    );
    _persist();
  }

  void _persist() {
    if (state.windowId != null && state.deliveryDate != null) {
      PersistenceService.saveDeliveryWindow(
        state.windowId!,
        state.locationLabel,
        state.deliveryDate!,
        state.deliveryDate!.add(const Duration(hours: 2)),
        state.city,
      );
    }
  }

  String? _extractSlot(Map<String, dynamic> saved) {
    // Try to extract slot from saved data
    return saved['slot'] as String?;
  }

  String? _extractFriendlyTime(Map<String, dynamic> saved) {
    try {
      final startAt = DateTime.parse(saved['start_at'] as String);
      final slot = saved['slot'] as String? ?? '';
      return _formatFriendlyTime(startAt, slot);
    } catch (e) {
      return null;
    }
  }

  String _formatFriendlyTime(DateTime start, String slot) {
    final hour = start.hour;
    String period;

    if (hour >= 6 && hour < 12) {
      period = 'Morning';
    } else if (hour >= 12 && hour < 17) {
      period = 'Afternoon';
    } else {
      period = 'Evening';
    }

    final parts = slot.split('-');
    if (parts.length == 2) {
      return '$period (${parts[0]}–${parts[1]} pm)';
    }
    return period;
  }
}

final gateStateProvider = StateNotifierProvider<GateStateNotifier, GateState>(
  (ref) => GateStateNotifier(),
);

/// Derived: Is gate ready (all info collected)?
final gateReadyProvider = Provider<bool>((ref) {
  return ref.watch(gateStateProvider).isReady;
});

/// Derived: Gate summary for chip display
final gateSummaryProvider = Provider<String>((ref) {
  final gate = ref.watch(gateStateProvider);

  if (!gate.isReady) return 'Select delivery';

  return '${gate.dayLabel} • ${gate.friendlyTime} • ${gate.locationLabel}';
});

/// Derived: Short summary for compact displays
final gateShortSummaryProvider = Provider<String>((ref) {
  final gate = ref.watch(gateStateProvider);

  if (!gate.isReady) return 'Delivery';

  return '${gate.dayLabel} • ${gate.timeSlot}';
});
