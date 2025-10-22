import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ethiomealkit/features/delivery/data/delivery_repository.dart';
import 'package:ethiomealkit/features/delivery/local/delivery_local_store.dart';
import 'package:ethiomealkit/features/delivery/models/delivery_models.dart';

// Delivery repository provider
final deliveryRepoProvider = Provider<DeliveryRepository>((ref) {
  return DeliveryRepository(Supabase.instance.client);
});

// Current user ID provider
final userIdProvider = Provider<String>((ref) {
  final user = Supabase.instance.client.auth.currentUser;
  return user?.id ?? 'guest';
});

// Current week provider (Monday start)
final currentWeekProvider = Provider<DateTime>((ref) {
  final now = DateTime.now();
  return now.subtract(Duration(days: now.weekday - 1));
});

// Main delivery window controller
class DeliveryWindowController extends AsyncNotifier<DeliveryWindow?> {
  late final DeliveryRepository _repo;
  late final String _userId;
  late final DateTime _week;
  bool _hasLoaded = false;

  @override
  Future<DeliveryWindow?> build() async {
    _repo = ref.read(deliveryRepoProvider);
    _userId = ref.read(userIdProvider);
    _week = ref.read(currentWeekProvider);

    if (_hasLoaded) {
      return state.value;
    }

    print('🚀 Initializing delivery window...');

    // Step 1: Try local cache (instant)
    final cached = await DeliveryLocalStore.loadWindow();
    if (cached != null) {
      print('📂 Restored from cache: ${cached.humanSummary}');
      _hasLoaded = true;
      return cached;
    }

    // Step 2: Try server (if available)
    final current = await _repo.getCurrent(_userId, _week);
    if (current != null) {
      print('☁️ Loaded from server: ${current.humanSummary}');
      await DeliveryLocalStore.saveWindow(current);
      _hasLoaded = true;
      return current;
    }

    // Step 3: Recommend and auto-select
    print('💡 Auto-selecting recommended window...');
    await Future.delayed(
      const Duration(milliseconds: 1000),
    ); // Thoughtful pause
    final recommended = await _repo.recommend(_userId, _week);
    print('✅ Recommended: ${recommended.humanSummary}');

    await DeliveryLocalStore.saveWindow(recommended);
    _hasLoaded = true;
    return recommended;
  }

  /// Quick toggle location (Home <-> Office) without opening editor
  Future<void> quickSetLocation(String locId) async {
    final cur = state.value;
    if (cur == null) return;

    print('🏠 Quick toggle to: $locId');

    final updated = await _repo.setWindow(
      userId: _userId,
      week: _week,
      locationId: locId,
      daypart: cur.daypart.name,
      date: cur.date,
    );

    state = AsyncData(updated);
    await DeliveryLocalStore.saveWindow(updated);
    print('✅ Location updated: ${updated.humanSummary}');
  }

  /// Set all delivery window properties (from editor)
  Future<void> setAll({
    required String locId,
    required DeliveryDaypart daypart,
    required DateTime date,
  }) async {
    print('📝 Setting delivery window: $locId, ${daypart.name}, $date');

    final updated = await _repo.setWindow(
      userId: _userId,
      week: _week,
      locationId: locId,
      daypart: daypart.name,
      date: date,
    );

    state = AsyncData(updated);
    await DeliveryLocalStore.saveWindow(updated);
    print('✅ Delivery window updated: ${updated.humanSummary}');
  }
}

final deliveryWindowControllerProvider =
    AsyncNotifierProvider<DeliveryWindowController, DeliveryWindow?>(
      () => DeliveryWindowController(),
    );
