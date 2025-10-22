import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/api/supa_client.dart';
import '../services/persistence_service.dart';

// Import box quota from box selection providers
import '../../features/box/providers/box_selection_providers.dart'
    show boxQuotaProvider;

/// Recipe model for the grid
class Recipe {
  final String id;
  final String title;
  final String imageUrl;
  final int prepMinutes;
  final int cookMinutes;
  final int calories;
  final String? tag; // Chef's Choice, Express, Gourmet, Veggie, etc.
  final List<String> tags; // Multiple tags possible

  Recipe({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.prepMinutes,
    required this.cookMinutes,
    required this.calories,
    this.tag,
    this.tags = const [],
  });

  factory Recipe.fromMap(Map<String, dynamic> map) {
    final tagsList =
        map['tags'] is List ? List<String>.from(map['tags']) : <String>[];

    return Recipe(
      id: map['id'] ?? '',
      title: map['title'] ?? 'Untitled Recipe',
      imageUrl: map['image_url'] ?? '',
      prepMinutes: map['prep_minutes'] ?? 15,
      cookMinutes: map['cook_minutes'] ?? 15,
      calories: map['calories'] ?? 500,
      tag: tagsList.isNotEmpty ? tagsList.first : null,
      tags: tagsList,
    );
  }
}

/// Fetch recipes from Supabase
final recipesProvider = FutureProvider<List<Recipe>>((ref) async {
  try {
    final api = SupaClient(Supabase.instance.client);
    final data = await api.currentWeeklyRecipes(limit: 15);

    final recipes = data.map((r) => Recipe.fromMap(r)).toList();
    print('📦 Loaded ${recipes.length} recipes for selection');
    return recipes;
  } catch (e) {
    print('❌ Failed to load recipes: $e');
    return [];
  }
});

/// Selected recipe IDs with cap enforcement and persistence
class SelectedRecipesNotifier extends StateNotifier<Set<String>> {
  SelectedRecipesNotifier(this.ref) : super({}) {
    _loadState();
  }
  final Ref ref;

  Future<void> _loadState() async {
    state = await PersistenceService.loadSelectedRecipes();
    if (state.isNotEmpty) {
      print('📂 Restored ${state.length} selected recipes');
    }
  }

  void _persist() {
    PersistenceService.saveSelectedRecipes(state);
  }

  void toggle(String id) {
    // Import box providers for quota check
    final quota = ref.read(boxQuotaProvider);
    final isSelected = state.contains(id);

    if (isSelected) {
      // Always allow deselection
      final updated = Set<String>.from(state);
      updated.remove(id);
      state = updated;
      _persist();
      print('📝 Recipe $id removed. Selected: ${state.length}');
      return;
    }

    // Check if we can add (not at cap)
    if (quota == 0) {
      ref.read(selectionNudgeProvider.notifier).nudgeSelectBoxFirst();
      return;
    }

    if (state.length < quota) {
      final updated = Set<String>.from(state);
      updated.add(id);
      state = updated;
      _persist();
      print('📝 Recipe $id added. Selected: ${state.length}');
    } else {
      ref.read(selectionNudgeProvider.notifier).nudgeOverCap();
    }
  }

  void setAll(List<String> ids) {
    state = ids.toSet();
    _persist();
    print('📝 Bulk set: ${state.length} recipes selected');
  }

  void clear() {
    state = {};
    _persist();
  }
}

final selectedRecipesProvider =
    StateNotifierProvider<SelectedRecipesNotifier, Set<String>>(
  (ref) => SelectedRecipesNotifier(ref),
);

// boxQuotaProvider is defined in lib/features/box/providers/box_selection_providers.dart
// Import it from there when needed to avoid duplication

/// Active filters (Chef's Choice, Gourmet, Express, Veggie)
final activeFiltersProvider = StateProvider<Set<String>>((ref) => {});

/// Filtered recipes based on active filters
final filteredRecipesProvider = Provider<List<Recipe>>((ref) {
  final recipes = ref.watch(recipesProvider).value ?? [];
  final filters = ref.watch(activeFiltersProvider);

  if (filters.isEmpty) return recipes;

  return recipes.where((recipe) {
    // Match if recipe has any of the active filter tags
    return recipe.tags.any((tag) =>
        filters.contains(tag) ||
        filters.any((f) => tag.toLowerCase().contains(f.toLowerCase())));
  }).toList();
});

/// Selection nudge state for UI feedback
class SelectionNudgeState {
  final bool showOverCap;
  final bool showSelectBoxFirst;
  final bool showSwapRequired;
  const SelectionNudgeState({
    this.showOverCap = false,
    this.showSelectBoxFirst = false,
    this.showSwapRequired = false,
  });
}

class SelectionNudgeController extends StateNotifier<SelectionNudgeState> {
  final Ref ref;
  SelectionNudgeController(this.ref) : super(const SelectionNudgeState());

  void nudgeOverCap() {
    state = const SelectionNudgeState(showOverCap: true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) state = const SelectionNudgeState();
    });
  }

  void nudgeSelectBoxFirst() {
    state = const SelectionNudgeState(showSelectBoxFirst: true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) state = const SelectionNudgeState();
    });
  }

  void nudgeSwapRequired() {
    state = const SelectionNudgeState(showSwapRequired: true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) state = const SelectionNudgeState();
    });
  }
}

final selectionNudgeProvider =
    StateNotifierProvider<SelectionNudgeController, SelectionNudgeState>(
  (ref) => SelectionNudgeController(ref),
);

/// Auto-select controller for filling remaining slots
class AutoSelectController {
  final Ref ref;
  AutoSelectController(this.ref);

  void fillRemaining() {
    // Import from box providers
    final quota = ref.read(boxQuotaProvider);
    final selected = ref.read(selectedRecipesProvider);
    final remaining = quota - selected.length;

    if (remaining <= 0) return;

    final all = ref.read(filteredRecipesProvider);

    // Sort by priority: Chef's Choice > Popular > shortest cook time
    final candidates = [...all]..sort((a, b) {
        int score(Recipe r) =>
            (r.tags.contains("Chef's Choice") ? 0 : 2) +
            (r.tags.contains("Popular") ? 0 : 1) +
            r.cookMinutes;
        return score(a).compareTo(score(b));
      });

    final add = <String>[];
    for (final r in candidates) {
      if (add.length >= remaining) break;
      if (!selected.contains(r.id)) add.add(r.id);
    }

    final notifier = ref.read(selectedRecipesProvider.notifier);
    for (final id in add) {
      notifier.toggle(id);
    }

    print('🤖 Auto-completed with ${add.length} recipes');
  }
}

final autoSelectControllerProvider = Provider<AutoSelectController>(
  (ref) => AutoSelectController(ref),
);

/// Remaining selections (quota - current selections)
final remainingSelectionsProvider = Provider<int>((ref) {
  final quota = ref.watch(boxQuotaProvider);
  final chosen = ref.watch(selectedRecipesProvider).length;
  final remaining = quota - chosen;
  return remaining < 0 ? 0 : remaining;
});
