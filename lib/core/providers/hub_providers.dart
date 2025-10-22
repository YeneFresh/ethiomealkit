import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Weekly status model
class WeeklyStatus {
  final String weekStart; // ISO date
  final int selectedRecipes;
  final int quota;
  final bool isSkipped;
  final String? deliveryDate;
  final String? deliveryWindow;

  const WeeklyStatus({
    required this.weekStart,
    required this.selectedRecipes,
    required this.quota,
    this.isSkipped = false,
    this.deliveryDate,
    this.deliveryWindow,
  });

  bool get isComplete => selectedRecipes >= quota;
  int get remaining => quota - selectedRecipes;
}

/// Current weekly status provider (stub - replace with real Supabase query)
final weeklyStatusProvider = FutureProvider<WeeklyStatus>((ref) async {
  // TODO: Query from Supabase app.weekly_menu_with_flags
  await Future.delayed(const Duration(milliseconds: 500));
  
  return const WeeklyStatus(
    weekStart: '2025-10-13',
    selectedRecipes: 4,
    quota: 4,
    isSkipped: false,
    deliveryDate: 'Thu, 17 Oct',
    deliveryWindow: 'Afternoon (2–4 pm)',
  );
});

/// Next delivery provider
final nextDeliveryProvider = Provider<Map<String, String?>>((ref) {
  final status = ref.watch(weeklyStatusProvider).value;
  
  return {
    'date': status?.deliveryDate ?? 'Thu, 17 Oct',
    'window': status?.deliveryWindow ?? 'Afternoon (2–4 pm)',
    'address': 'Home • Addis Ababa',
  };
});

/// User stats provider (for rewards)
final userStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  // TODO: Query from Supabase user profile
  await Future.delayed(const Duration(milliseconds: 300));
  
  return {
    'streak': 3, // weeks
    'points': 1250,
    'tier': 'Gold', // Bronze, Silver, Gold, Platinum
    'referrals': 2,
    'weeklyGoal': 4, // recipes
    'weeklyProgress': 3,
  };
});




