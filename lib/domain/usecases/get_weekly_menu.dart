import '../entities/recipe.dart';
import '../repositories/recipe_repository.dart';

/// Use case: Get weekly menu recipes
/// Encapsulates business logic for fetching weekly recipes
class GetWeeklyMenu {
  final RecipeRepository _repo;

  GetWeeklyMenu(this._repo);

  Future<List<Recipe>> call(DateTime weekStart) async {
    final recipes = await _repo.fetchWeekly(weekStart);

    // Business rule: Sort by pick score for better auto-selection
    recipes.sort((a, b) => b.pickScore.compareTo(a.pickScore));

    return recipes;
  }
}



