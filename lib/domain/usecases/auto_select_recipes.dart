import '../entities/recipe.dart';

/// Use case: Auto-select recipes based on preferences and business rules
class AutoSelectRecipes {
  /// Select N recipes using smart algorithm
  /// Returns list of recipe IDs
  List<String> call({
    required List<Recipe> availableRecipes,
    required int count,
    Set<String>? excludeIds,
  }) {
    final exclude = excludeIds ?? {};
    final candidates =
        availableRecipes.where((r) => !exclude.contains(r.id)).toList();

    // Sort by pickScore (highest first)
    candidates.sort((a, b) => b.pickScore.compareTo(a.pickScore));

    return candidates.take(count).map((r) => r.id).toList();
  }

  /// Calculate how many recipes to auto-pick based on box size
  int calculateAutoPickCount(int quotaRecipes) {
    // Business rule: Auto-pick 50-75% of quota
    if (quotaRecipes <= 3) return quotaRecipes; // All for small boxes
    if (quotaRecipes == 4) return 3; // Leave 1 slot for user choice
    return (quotaRecipes * 0.6).ceil(); // 60% for larger boxes
  }
}
