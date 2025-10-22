// Recipe Selection Providers - Plan Allowance Enforcement
// Manages recipe selection with proper plan allowance and over-select prevention

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/api/supa_client.dart';

// =============================================================================
// Data Models
// =============================================================================

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
  bool get isAtLimit => remaining == 0;
  String get statusText => '$totalSelected/$allowed selected';
}

// =============================================================================
// Core Providers
// =============================================================================

// 1. Weekly Recipes Provider (Gated)
final weeklyRecipesProvider =
    FutureProvider.autoDispose<List<Recipe>>((ref) async {
  final api = ref.watch(supaClientProvider);

  try {
    final data = await api.currentWeeklyRecipes();
    return data.map((json) => Recipe.fromJson(json)).toList();
  } catch (e) {
    return [];
  }
});

// 2. User Selections Provider
final userSelectionsProvider =
    FutureProvider.autoDispose<List<RecipeSelection>>((ref) async {
  final api = ref.watch(supaClientProvider);

  try {
    final data = await api.userSelections();
    return data.map((json) => RecipeSelection.fromJson(json)).toList();
  } catch (e) {
    return [];
  }
});

// 3. Selection Status Provider
final selectionStatusProvider = Provider.autoDispose<SelectionStatus>((ref) {
  final selectionsAsync = ref.watch(userSelectionsProvider);

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

// =============================================================================
// Action Providers
// =============================================================================

// 4. Toggle Recipe Selection Provider
final toggleRecipeSelectionProvider = FutureProvider.family
    .autoDispose<SelectionStatus, String>((ref, recipeId) async {
  final api = ref.watch(supaClientProvider);
  final currentSelections = ref.read(userSelectionsProvider);

  // Find current selection state
  final now = DateTime.now();
  final currentSelection = currentSelections.when(
    data: (selections) => selections.firstWhere(
      (s) => s.recipeId == recipeId,
      orElse: () => RecipeSelection(
        recipeId: '',
        weekStart: now,
        boxSize: 0,
        selected: false,
      ),
    ),
    loading: () => RecipeSelection(
      recipeId: '',
      weekStart: now,
      boxSize: 0,
      selected: false,
    ),
    error: (_, __) => RecipeSelection(
      recipeId: '',
      weekStart: now,
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

    // Invalidate related providers to refresh data
    ref.invalidate(userSelectionsProvider);
    ref.invalidate(selectionStatusProvider);

    return status;
  } catch (e) {
    rethrow;
  }
});

// =============================================================================
// Computed Providers
// =============================================================================

// 5. Selected Recipes Provider
final selectedRecipesProvider = Provider.autoDispose<List<Recipe>>((ref) {
  final recipesAsync = ref.watch(weeklyRecipesProvider);
  final selectionsAsync = ref.watch(userSelectionsProvider);

  return recipesAsync.when(
    data: (recipes) {
      return selectionsAsync.when(
        data: (selections) {
          final selectedIds = selections
              .where((s) => s.selected)
              .map((s) => s.recipeId)
              .toSet();

          return recipes.where((r) => selectedIds.contains(r.id)).toList();
        },
        loading: () => [],
        error: (_, __) => [],
      );
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// 6. Is Recipe Selected Provider
final isRecipeSelectedProvider =
    Provider.family.autoDispose<bool, String>((ref, recipeId) {
  final selectionsAsync = ref.watch(userSelectionsProvider);

  return selectionsAsync.when(
    data: (selections) {
      return selections.any((s) => s.recipeId == recipeId && s.selected);
    },
    loading: () => false,
    error: (_, __) => false,
  );
});

// =============================================================================
// Providers cleaned up - removed unused:
// - canSelectRecipeProvider
// - recipeSelectionCountProvider
// - selectionErrorProvider
// - clearSelectionErrorProvider
// - recipeTagsProvider
// - filteredRecipesProvider
// =============================================================================
