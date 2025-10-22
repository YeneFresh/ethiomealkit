import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ethiomealkit/domain/usecases/get_weekly_menu.dart';
import 'package:ethiomealkit/domain/usecases/auto_select_recipes.dart';
import 'package:ethiomealkit/domain/usecases/get_available_delivery_slots.dart';
import 'package:ethiomealkit/core/providers/repository_providers.dart';

/// ===== Use Case Providers =====

final getWeeklyMenuProvider = Provider<GetWeeklyMenu>((ref) {
  return GetWeeklyMenu(ref.watch(recipeRepositoryProvider));
});

final autoSelectRecipesProvider = Provider<AutoSelectRecipes>((ref) {
  return AutoSelectRecipes();
});

final getAvailableDeliverySlotsProvider = Provider<GetAvailableDeliverySlots>((
  ref,
) {
  return GetAvailableDeliverySlots(ref.watch(deliveryRepositoryProvider));
});
