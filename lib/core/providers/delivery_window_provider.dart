import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ethiomealkit/core/services/persistence_service.dart';

/// Address type for delivery
enum AddressType { home, office }

extension AddressTypeExt on AddressType {
  String get displayName => this == AddressType.home ? 'Home' : 'Office';
}

/// Delivery window model (legacy compatibility layer)
/// New code should use delivery/delivery_windows_providers.dart
class DeliveryWindow {
  final String id;
  final DateTime startAt;
  final DateTime endAt;
  final String city;
  final String label; // e.g., "Home – Addis Ababa"
  final String group; // 'Morning' | 'Afternoon' | 'Evening'
  final bool hasCapacity;
  final bool isRecommended;
  final String? slot; // e.g., "14-16"

  DeliveryWindow({
    required this.id,
    required this.startAt,
    required this.endAt,
    required this.city,
    required this.label,
    required this.group,
    required this.hasCapacity,
    required this.isRecommended,
    this.slot,
  });

  /// Format day label (e.g., "Tue, 14 Oct")
  String get dayLabel {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
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
    final weekday = weekdays[startAt.weekday - 1];
    final month = months[startAt.month - 1];
    return '$weekday, ${startAt.day} $month';
  }

  /// Format time label (e.g., "14:00–16:00")
  String get timeLabel {
    final startHour = startAt.hour.toString().padLeft(2, '0');
    final startMin = startAt.minute.toString().padLeft(2, '0');
    final endHour = endAt.hour.toString().padLeft(2, '0');
    final endMin = endAt.minute.toString().padLeft(2, '0');
    return '$startHour:$startMin–$endHour:$endMin';
  }

  /// Friendly time label (e.g., "Afternoon (2–4 pm)")
  String get friendlyTimeLabel {
    final startHour = startAt.hour;
    final endHour = endAt.hour;
    return '$group ($startHour–$endHour pm)';
  }

  factory DeliveryWindow.fromMap(
    Map<String, dynamic> map, [
    AddressType addressType = AddressType.home,
  ]) {
    final city = map['city'] ?? 'Addis Ababa';
    final startAt = DateTime.parse(map['start_at'].toString());
    final endAt = DateTime.parse(map['end_at'].toString());
    final slot = map['slot']?.toString() ?? '';

    // Determine time group from hour
    String group;
    final hour = startAt.hour;
    if (hour >= 6 && hour < 12) {
      group = 'Morning';
    } else if (hour >= 12 && hour < 17) {
      group = 'Afternoon';
    } else {
      group = 'Evening';
    }

    // Check if recommended (afternoon slots preferred)
    final isRecommended = group == 'Afternoon' && slot.contains('14-16');

    return DeliveryWindow(
      id: map['id'] ?? '',
      startAt: startAt,
      endAt: endAt,
      city: city,
      label: '${addressType.displayName} – $city',
      group: group,
      hasCapacity:
          map['capacity'] != null &&
          map['booked_count'] != null &&
          (map['capacity'] as num) > (map['booked_count'] as num),
      isRecommended: isRecommended,
      slot: slot,
    );
  }
}

/// Delivery window state notifier with persistence
class DeliveryWindowNotifier extends StateNotifier<DeliveryWindow?> {
  DeliveryWindowNotifier() : super(null) {
    _loadState();
  }

  Future<void> _loadState() async {
    final saved = await PersistenceService.loadDeliveryWindow();
    if (saved != null) {
      try {
        state = DeliveryWindow(
          id: saved['id'] as String,
          startAt: DateTime.parse(saved['start_at'] as String),
          endAt: DateTime.parse(saved['end_at'] as String),
          city: saved['city'] as String,
          label: saved['label'] as String,
          group: _inferGroup(DateTime.parse(saved['start_at'] as String)),
          hasCapacity: true,
          isRecommended: false,
        );
        print('📂 Restored delivery window: ${state?.label}');
      } catch (e) {
        print('⚠️ Failed to restore delivery window: $e');
      }
    }
  }

  String _inferGroup(DateTime start) {
    final hour = start.hour;
    if (hour >= 6 && hour < 12) return 'Morning';
    if (hour >= 12 && hour < 17) return 'Afternoon';
    return 'Evening';
  }

  void _persist() {
    if (state != null) {
      PersistenceService.saveDeliveryWindow(
        state!.id,
        state!.label,
        state!.startAt,
        state!.endAt,
        state!.city,
      );
    }
  }

  /// Auto-select recommended delivery window based on user location and time
  Future<void> autoSelectRecommended({
    String city = 'Addis Ababa',
    AddressType addressType = AddressType.home,
  }) async {
    try {
      final client = Supabase.instance.client;
      print('🔍 Querying delivery_windows table...');

      // Fetch available windows from Supabase
      final response = await client
          .from('delivery_windows')
          .select('*')
          .eq('city', city)
          .eq('is_active', true)
          .gte('capacity', 1)
          .order('start_at');

      final windows = response as List<dynamic>;
      print('📊 Raw response: $windows');

      if (windows.isEmpty) {
        print('⚠️ No delivery windows available - using default');
        return;
      }

      print('✅ Parsed ${windows.length} delivery windows');

      // Find recommended window (usually next available afternoon slot)
      final recommended = windows.firstWhere(
        (w) => w['slot']?.toString().contains('14-16') == true,
        orElse: () => windows.first,
      );

      final window = DeliveryWindow.fromMap(recommended, addressType);
      state = window;
      _persist();

      // Save to backend using the CORRECT RPC if user is authenticated
      try {
        final currentUser = client.auth.currentUser;
        if (currentUser != null) {
          // Use upsert_user_delivery_preference (not upsert_user_active_window)
          await client.rpc(
            'upsert_user_delivery_preference',
            params: {
              'p_user_id': currentUser.id,
              'p_window_id': window.id,
              'p_address_id': addressType == AddressType.home
                  ? 'home'
                  : 'office',
            },
          );
          print(
            '✅ Auto-selected and saved delivery window: ${window.timeLabel}',
          );
        } else {
          print('✅ Auto-selected delivery window (guest): ${window.timeLabel}');
        }
      } catch (e) {
        // Gracefully handle RPC errors for guest users or missing RPC
        print('ℹ️ Could not save delivery window: $e');
      }
    } catch (e) {
      print('❌ Failed to auto-select delivery window: $e');
    }
  }

  /// Set a specific delivery window
  void setWindow(DeliveryWindow window) {
    state = window;
    _persist();
  }

  /// Clear the selected window
  void clear() {
    state = null;
    // Note: clearDeliveryWindow not implemented yet in PersistenceService
  }
}

/// Provider for delivery window state
final deliveryWindowProvider =
    StateNotifierProvider<DeliveryWindowNotifier, DeliveryWindow?>(
      (ref) => DeliveryWindowNotifier(),
    );
