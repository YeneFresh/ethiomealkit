// Recipe Providers - Proxies app.user_selections and app.current_weekly_recipes

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ethiomealkit/data/api/supa_client.dart';
import 'package:ethiomealkit/core/providers/gate_state_provider.dart';

// Data Models
class Recipe {
  final String id;
  final String title;
  final String slug;
  final String? imageUrl;
  final List<String> tags;
  final int sortOrder;
  final DateTime weekStart;

  const Recipe({
    required this.id,
    required this.title,
    required this.slug,
    this.imageUrl,
    required this.tags,
    required this.sortOrder,
    required this.weekStart,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      slug: json['slug'] ?? '',
      imageUrl: json['image_url'],
      tags: List<String>.from(json['tags'] ?? []),
      sortOrder: json['sort_order'] ?? 0,
      weekStart: json['week_start'] != null
          ? DateTime.parse(json['week_start'])
          : DateTime.now(),
    );
  }
}

class RecipeSelection {
  final String recipeId;
  final DateTime weekStart;
  final int boxSize;
  final bool selected;

  const RecipeSelection({
    required this.recipeId,
    required this.weekStart,
    required this.boxSize,
    required this.selected,
  });

  factory RecipeSelection.fromJson(Map<String, dynamic> json) {
    return RecipeSelection(
      recipeId: json['recipe_id'] ?? '',
      weekStart: json['week_start'] != null
          ? DateTime.parse(json['week_start'])
          : DateTime.now(),
      boxSize: json['box_size'] ?? 2,
      selected: json['selected'] ?? false,
    );
  }
}

class SelectionStatus {
  final int totalSelected;
  final int remaining;
  final int allowed;
  final bool ok;

  const SelectionStatus({
    required this.totalSelected,
    required this.remaining,
    required this.allowed,
    required this.ok,
  });

  factory SelectionStatus.fromJson(Map<String, dynamic> json) {
    return SelectionStatus(
      totalSelected: json['total_selected'] ?? 0,
      remaining: json['remaining'] ?? 0,
      allowed: json['allowed'] ?? 0,
      ok: json['ok'] ?? false,
    );
  }

  bool get canSelectMore => remaining > 0;
  String get statusText => '$totalSelected/$allowed selected';
}

// Core Providers
final selectionsProvider =
    FutureProvider.autoDispose<List<RecipeSelection>>((ref) async {
  final api = ref.watch(supaClientProvider);

  try {
    final data = await api.userSelections();
    return data.map((json) => RecipeSelection.fromJson(json)).toList();
  } catch (e) {
    return [];
  }
});

// Gated on readinessProvider.is_ready
final weeklyRecipesProvider =
    FutureProvider.autoDispose<List<Recipe>>((ref) async {
  final api = ref.watch(supaClientProvider);
  final isReady = ref.watch(gateReadyProvider);

  if (!isReady) {
    return []; // Return empty when not ready
  }

  try {
    final data = await api.currentWeeklyRecipes();
    return data.map((json) => Recipe.fromJson(json)).toList();
  } catch (e) {
    return [];
  }
});

// Computed Provider
final selectionStatusProvider = Provider.autoDispose<SelectionStatus>((ref) {
  final selectionsAsync = ref.watch(selectionsProvider);

  return selectionsAsync.when(
    data: (selections) {
      final selectedCount = selections.where((s) => s.selected).length;
      final allowed = selections.isNotEmpty ? selections.first.boxSize : 0;

      return SelectionStatus(
        totalSelected: selectedCount,
        remaining: allowed - selectedCount,
        allowed: allowed,
        ok: true,
      );
    },
    loading: () => const SelectionStatus(
      totalSelected: 0,
      remaining: 0,
      allowed: 0,
      ok: false,
    ),
    error: (_, __) => const SelectionStatus(
      totalSelected: 0,
      remaining: 0,
      allowed: 0,
      ok: false,
    ),
  );
});

// Action Provider
final toggleRecipeSelectionProvider = FutureProvider.family
    .autoDispose<SelectionStatus, String>((ref, recipeId) async {
  final api = ref.watch(supaClientProvider);
  final currentSelections = ref.read(selectionsProvider);

  // Find current selection state
  final currentSelection = currentSelections.when(
    data: (selections) => selections.firstWhere(
      (s) => s.recipeId == recipeId,
      orElse: () => RecipeSelection(
        recipeId: '',
        weekStart: DateTime.now(),
        boxSize: 0,
        selected: false,
      ),
    ),
    loading: () => RecipeSelection(
      recipeId: '',
      weekStart: DateTime.now(),
      boxSize: 0,
      selected: false,
    ),
    error: (_, __) => RecipeSelection(
      recipeId: '',
      weekStart: DateTime.now(),
      boxSize: 0,
      selected: false,
    ),
  );

  final newSelection = !currentSelection.selected;

  try {
    final result = await api.toggleRecipeSelection(
      recipeId: recipeId,
      select: newSelection,
    );

    final status = SelectionStatus.fromJson(result);

    // Invalidate related providers
    ref.invalidate(selectionsProvider);
    ref.invalidate(selectionStatusProvider);

    return status;
  } catch (e) {
    rethrow;
  }
});
