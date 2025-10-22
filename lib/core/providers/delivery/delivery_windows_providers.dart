import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../address_providers.dart' show selectedCityProvider;

// ===== CONFIG =====
const kCutoffHours = 48;

// ===== MODELS =====
class DeliveryWindow {
  final String id;
  final DateTime startAt;
  final DateTime endAt;
  final String city;
  final String slot; // e.g., "14:00–16:00"
  final bool hasCapacity;
  final bool isActive;
  final bool isCutoff;
  final bool isRecommended;

  const DeliveryWindow({
    required this.id,
    required this.startAt,
    required this.endAt,
    required this.city,
    required this.slot,
    required this.hasCapacity,
    required this.isActive,
    required this.isCutoff,
    this.isRecommended = false,
  });

  DeliveryWindow copyWith({
    String? id,
    DateTime? startAt,
    DateTime? endAt,
    String? city,
    String? slot,
    bool? hasCapacity,
    bool? isActive,
    bool? isCutoff,
    bool? isRecommended,
  }) {
    return DeliveryWindow(
      id: id ?? this.id,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      city: city ?? this.city,
      slot: slot ?? this.slot,
      hasCapacity: hasCapacity ?? this.hasCapacity,
      isActive: isActive ?? this.isActive,
      isCutoff: isCutoff ?? this.isCutoff,
      isRecommended: isRecommended ?? this.isRecommended,
    );
  }

  // UI-friendly labels
  String get dayLabel {
    final weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
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
      'Dec'
    ];
    return '${weekdayNames[startAt.weekday - 1]}, ${months[startAt.month - 1]} ${startAt.day}';
  }

  String get timeLabel => slot;

  String get friendlyTimeLabel {
    final parts = slot.split('–');
    if (parts.length == 2) {
      return '${parts[0]} – ${parts[1]}';
    }
    return slot;
  }

  String get label => '$city';

  String? get disabledReason {
    if (!isActive) return 'Unavailable';
    if (!hasCapacity) return 'Full';
    if (isCutoff) return 'Past cutoff (48h)';
    return null;
  }

  bool get isSelectable => isActive && hasCapacity && !isCutoff;
}

class SelectedWindow {
  final String windowId;
  final DateTime startAt;
  final String label; // e.g., "Thu, 14:00–16:00"

  const SelectedWindow({
    required this.windowId,
    required this.startAt,
    required this.label,
  });
}

// ===== REPO =====
class DeliveryRepo {
  final SupabaseClient sb;

  DeliveryRepo(this.sb);

  Future<List<DeliveryWindow>> fetchWindows({
    required String city,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final now = DateTime.now();
    final cutoffLimit = now.add(const Duration(hours: kCutoffHours));

    final res = await sb
        .from('delivery_windows')
        .select('id,start_at,end_at,city,slot,capacity,booked_count,is_active')
        .gte('start_at', fromDate.toUtc().toIso8601String())
        .lte('start_at', toDate.toUtc().toIso8601String())
        .eq('city', city)
        .eq('is_active', true);

    final list = (res as List).map((r) {
      final start = DateTime.parse(r['start_at'] as String).toLocal();
      final end = DateTime.parse(r['end_at'] as String).toLocal();
      final isCutoff = !start.isAfter(cutoffLimit);
      final capacity = (r['capacity'] ?? 0) as int;
      final booked = (r['booked_count'] ?? 0) as int;
      final hasCapacity = capacity > booked;

      return DeliveryWindow(
        id: r['id'] as String,
        startAt: start,
        endAt: end,
        city: (r['city'] ?? '') as String,
        slot: (r['slot'] ?? '') as String,
        hasCapacity: hasCapacity,
        isActive: (r['is_active'] ?? false) as bool,
        isCutoff: isCutoff,
      );
    }).toList();

    // Sort by start time
    list.sort((a, b) => a.startAt.compareTo(b.startAt));

    // Mark first selectable window as recommended
    final firstSelectable = list.indexWhere((w) => w.isSelectable);
    if (firstSelectable >= 0) {
      list[firstSelectable] =
          list[firstSelectable].copyWith(isRecommended: true);
    }

    return list;
  }

  Future<SelectedWindow?> getSelectedWindow({required String userId}) async {
    try {
      final res = await sb
          .from('user_delivery_windows')
          .select('window_id, delivery_windows(start_at, end_at, slot, city)')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (res == null) return null;

      final w = res['delivery_windows'];
      if (w == null) return null;

      final start = DateTime.parse(w['start_at'] as String).toLocal();
      final slot = w['slot'] as String? ?? '';
      final city = w['city'] as String? ?? '';
      final label = _formatLabel(start, slot);

      return SelectedWindow(
        windowId: res['window_id'] as String,
        startAt: start,
        label: '$city – $label',
      );
    } catch (e) {
      print('❌ Error fetching selected window: $e');
      return null;
    }
  }

  Future<void> setSelectedWindow({
    required String userId,
    required String windowId,
    required String addressId,
    DateTime? effectiveWeekStart,
  }) async {
    try {
      await sb.rpc('upsert_user_delivery_preference', params: {
        'p_user_id': userId,
        'p_window_id': windowId,
        'p_address_id': addressId,
      });
      print('✅ Delivery window updated: $windowId');
    } catch (e) {
      print('❌ Error setting delivery window: $e');
      rethrow;
    }
  }

  static String _formatLabel(DateTime start, String slot) {
    final weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final wd = weekdayNames[start.weekday - 1];
    return '$wd, $slot';
  }

  static DateTime _mondayOfNextWeek() {
    final now = DateTime.now();
    final daysToMon = (8 - now.weekday) % 7;
    final nextMon = DateTime(now.year, now.month, now.day)
        .add(Duration(days: daysToMon == 0 ? 7 : daysToMon));
    return nextMon;
  }
}

// ===== SINGLETON CLIENT =====
final supabaseProvider =
    Provider<SupabaseClient>((_) => Supabase.instance.client);
final deliveryRepoProvider =
    Provider<DeliveryRepo>((ref) => DeliveryRepo(ref.watch(supabaseProvider)));

// ===== STATE (RIVERPOD) =====
final addressTypeProvider =
    StateProvider<String>((_) => 'home'); // 'home' | 'office'
// Note: selectedCityProvider is imported from address_providers.dart to avoid duplication

// User ID provider (uses authenticated user)
final userIdProvider = Provider<String>((ref) {
  final user = Supabase.instance.client.auth.currentUser;
  return user?.id ?? 'guest';
});

// Load window choices for the next 4 weeks, filtered by city
final availableWindowsProvider =
    FutureProvider<List<DeliveryWindow>>((ref) async {
  final repo = ref.watch(deliveryRepoProvider);
  final city = ref.watch(selectedCityProvider);
  final now = DateTime.now();
  final from = DateTime(now.year, now.month, now.day);
  final to = from.add(const Duration(days: 28));

  final list = await repo.fetchWindows(city: city, fromDate: from, toDate: to);
  return list;
});

// Group windows by date for better UX
final windowsByDateProvider =
    Provider<Map<String, List<DeliveryWindow>>>((ref) {
  final windowsAsync = ref.watch(availableWindowsProvider);
  final windows = windowsAsync.valueOrNull ?? [];

  final grouped = <String, List<DeliveryWindow>>{};
  for (final w in windows) {
    final dateKey =
        '${w.startAt.year}-${w.startAt.month.toString().padLeft(2, '0')}-${w.startAt.day.toString().padLeft(2, '0')}';
    grouped.putIfAbsent(dateKey, () => []).add(w);
  }

  return grouped;
});

// Selected window (source of truth with optimistic updates)
class SelectedWindowController
    extends AutoDisposeAsyncNotifier<SelectedWindow?> {
  DeliveryRepo get _repo => ref.read(deliveryRepoProvider);
  String get _uid => ref.read(userIdProvider);

  @override
  Future<SelectedWindow?> build() async {
    return await _repo.getSelectedWindow(userId: _uid);
  }

  Future<void> select({
    required DeliveryWindow window,
    required String addressId,
  }) async {
    // Optimistic update snapshot
    final prev = state.valueOrNull;
    final optimistic = SelectedWindow(
      windowId: window.id,
      startAt: window.startAt,
      label:
          '${window.city} – ${DeliveryRepo._formatLabel(window.startAt, window.slot)}',
    );
    state = AsyncData(optimistic);

    try {
      await _repo.setSelectedWindow(
        userId: _uid,
        windowId: window.id,
        addressId: addressId,
      );

      // Hard refetch to guarantee parity (no stale UI)
      final fresh = await _repo.getSelectedWindow(userId: _uid);
      state = AsyncData(fresh);

      // Invalidate dependent providers
      ref.invalidate(nextDeliverySummaryProvider);
      ref.invalidate(availableWindowsProvider);

      print('✅ Delivery window selection synced');
    } catch (e, st) {
      // Rollback on failure
      state = AsyncData(prev);
      print('❌ Failed to update delivery window, rolled back');
      // Surface error
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> autoSelectRecommended({String? addressId}) async {
    final windows = await ref.read(availableWindowsProvider.future);
    final recommended = windows.firstWhere(
      (w) => w.isRecommended && w.isSelectable,
      orElse: () => windows.firstWhere(
        (w) => w.isSelectable,
        orElse: () => windows.first,
      ),
    );

    final addrId = addressId ?? 'home';
    await select(window: recommended, addressId: addrId);
  }
}

final selectedDeliveryWindowProvider =
    AutoDisposeAsyncNotifierProvider<SelectedWindowController, SelectedWindow?>(
        () => SelectedWindowController());

// Derived: for Home/Pay summary
final nextDeliverySummaryProvider = Provider<String>((ref) {
  final sw = ref.watch(selectedDeliveryWindowProvider).valueOrNull;
  return sw?.label ?? '—';
});
