import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/recipe_repository.dart';
import '../../domain/repositories/delivery_repository.dart';
import '../../data/repositories/recipe_repository_supabase.dart';
import '../../data/repositories/delivery_repository_supabase.dart';

/// ===== Infrastructure Providers =====

final supabaseProvider =
    Provider<SupabaseClient>((_) => Supabase.instance.client);

/// ===== Repository Providers =====

final recipeRepositoryProvider = Provider<RecipeRepository>((ref) {
  return RecipeRepositorySupabase(ref.watch(supabaseProvider));
});

final deliveryRepositoryProvider = Provider<DeliveryRepository>((ref) {
  return DeliveryRepositorySupabase(ref.watch(supabaseProvider));
});

/// ===== User Context =====

final currentUserIdProvider = Provider<String>((ref) {
  final user = Supabase.instance.client.auth.currentUser;
  return user?.id ?? 'guest';
});

final currentWeekStartProvider = Provider<DateTime>((ref) {
  // Business logic: Get Monday of current or next week
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final daysToMonday = (8 - now.weekday) % 7;
  final nextMonday =
      daysToMonday == 0 ? today : today.add(Duration(days: daysToMonday));
  return nextMonday;
});



