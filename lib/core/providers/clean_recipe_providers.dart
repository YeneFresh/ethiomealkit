import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/recipe.dart';
import 'repository_providers.dart';
import 'usecase_providers.dart';

/// ===== Clean Architecture Recipe Providers =====
/// Zero business logic in widgets!

/// Weekly menu controller (uses clean use-case)
class WeeklyMenuController extends AsyncNotifier<List<Recipe>> {
  @override
  Future<List<Recipe>> build() async {
    final weekStart = ref.read(currentWeekStartProvider);
    final useCase = ref.read(getWeeklyMenuProvider);
    return await useCase(weekStart);
  }

  /// Refresh menu
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }
}

final weeklyMenuControllerProvider =
    AsyncNotifierProvider<WeeklyMenuController, List<Recipe>>(
  () => WeeklyMenuController(),
);

/// Selected recipes controller (domain-driven)
class SelectedRecipesController extends StateNotifier<Set<String>> {
  final Ref ref;

  SelectedRecipesController(this.ref) : super({});

  void toggle(String id) {
    if (state.contains(id)) {
      state = {...state}..remove(id);
    } else {
      state = {...state, id};
    }
    _persist();
  }

  void setAll(List<String> ids) {
    state = ids.toSet();
    _persist();
  }

  void clear() {
    state = {};
    _persist();
  }

  Future<void> _persist() async {
    // Delegate to repository
    try {
      final userId = ref.read(currentUserIdProvider);
      final weekStart = ref.read(currentWeekStartProvider);
      final repo = ref.read(recipeRepositoryProvider);
      await repo.saveUserSelection(userId, state.toList(), weekStart);
    } catch (e) {
      print('⚠️ Could not persist recipe selection: $e');
    }
  }

  /// Auto-select using use-case
  Future<void> autoSelect(int count) async {
    final useCase = ref.read(autoSelectRecipesProvider);
    final availableRecipes =
        ref.read(weeklyMenuControllerProvider).valueOrNull ?? [];

    final selected = useCase(
      availableRecipes: availableRecipes,
      count: count,
      excludeIds: state,
    );

    setAll([...state, ...selected]);
    print('🤲 Auto-selected ${selected.length} recipes');
  }
}

final selectedRecipesControllerProvider =
    StateNotifierProvider<SelectedRecipesController, Set<String>>(
  (ref) => SelectedRecipesController(ref),
);

/// Derived: Remaining slots
final remainingSlotsProvider = Provider<int>((ref) {
  // Import boxQuotaProvider from existing code
  final quota = ref.watch(boxQuotaProvider);
  final selected = ref.watch(selectedRecipesControllerProvider).length;
  return quota - selected;
});

/// Derived: At capacity
final atCapacityProvider = Provider<bool>((ref) {
  return ref.watch(remainingSlotsProvider) <= 0;
});

// TODO: Import boxQuotaProvider from features/box/providers/box_selection_providers.dart
// For now, stub it here to avoid circular deps during migration
final boxQuotaProvider = Provider<int>((ref) => 4);



