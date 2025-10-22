import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'recipe_selection_providers.dart';
import '../../features/box/providers/box_selection_providers.dart';

/// Smart auto-selection state
class AutoPickState {
  final bool hasAutoSelected;
  final int autoSelectedCount;
  final bool showNudge;

  const AutoPickState({
    this.hasAutoSelected = false,
    this.autoSelectedCount = 0,
    this.showNudge = false,
  });

  AutoPickState copyWith({
    bool? hasAutoSelected,
    int? autoSelectedCount,
    bool? showNudge,
  }) {
    return AutoPickState(
      hasAutoSelected: hasAutoSelected ?? this.hasAutoSelected,
      autoSelectedCount: autoSelectedCount ?? this.autoSelectedCount,
      showNudge: showNudge ?? this.showNudge,
    );
  }
}

/// Auto-pick controller with graceful UX
class AutoPickNotifier extends StateNotifier<AutoPickState> {
  final Ref ref;

  AutoPickNotifier(this.ref) : super(const AutoPickState());

  /// Soft auto-select: Pick N recipes based on preferences
  /// Shows a gentle nudge instead of forcing
  Future<void> softAutoSelect() async {
    if (state.hasAutoSelected) return; // Only once per session

    final quota = ref.read(boxQuotaProvider);
    final selected = ref.read(selectedRecipesProvider);
    final remaining = quota - selected.length;

    if (remaining <= 0 || quota == 0) return;

    // Smart pick logic:
    // 1. Chef's Choice first (highest confidence)
    // 2. Popular (user-tested)
    // 3. Quick recipes (low friction)
    final all = ref.read(filteredRecipesProvider);
    final candidates = [...all]..sort((a, b) {
      int scoreA = _getRecipeScore(a);
      int scoreB = _getRecipeScore(b);
      return scoreA.compareTo(scoreB);
    });

    final toPick = <String>[];
    for (final recipe in candidates) {
      if (toPick.length >= remaining) break;
      if (!selected.contains(recipe.id)) {
        toPick.add(recipe.id);
      }
    }

    if (toPick.isEmpty) return;

    // Gracefully add to selection
    final notifier = ref.read(selectedRecipesProvider.notifier);
    for (final id in toPick) {
      notifier.toggle(id);
    }

    // Show gentle nudge
    state = state.copyWith(
      hasAutoSelected: true,
      autoSelectedCount: toPick.length,
      showNudge: true,
    );

    print('🤲 Handpicked ${toPick.length} recipes for you');
  }

  int _getRecipeScore(Recipe recipe) {
    int score = 0;
    
    // Chef's Choice = highest priority
    if (recipe.tags.contains("Chef's Choice")) score += 100;
    
    // Popular = user-tested
    if (recipe.tags.contains('Popular')) score += 50;
    
    // Quick recipes = low friction
    final totalTime = recipe.prepMinutes + recipe.cookMinutes;
    if (totalTime <= 30) score += 30;
    
    // Express = fast
    if (recipe.tags.contains('Express')) score += 20;
    
    // Prefer lower cook time for ease
    score -= totalTime ~/ 5;
    
    return score;
  }

  /// Dismiss the nudge
  void dismissNudge() {
    state = state.copyWith(showNudge: false);
  }

  /// Reset for new session
  void reset() {
    state = const AutoPickState();
  }
}

final autoPickProvider =
    StateNotifierProvider<AutoPickNotifier, AutoPickState>(
  (ref) => AutoPickNotifier(ref),
);

/// Remaining slots provider (derived)
final remainingSlotsProvider = Provider<int>((ref) {
  final quota = ref.watch(boxQuotaProvider);
  final selected = ref.watch(selectedRecipesProvider).length;
  return quota - selected;
});

/// At capacity provider (derived)
final atCapacityProvider = Provider<bool>((ref) {
  return ref.watch(remainingSlotsProvider) <= 0;
});

/// Can add more provider (derived)
final canAddMoreProvider = Provider<bool>((ref) {
  final quota = ref.watch(boxQuotaProvider);
  return quota > 0 && !ref.watch(atCapacityProvider);
});




