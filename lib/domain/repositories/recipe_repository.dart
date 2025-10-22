import '../entities/recipe.dart';

/// Recipe repository interface (domain contract)
/// Implementations live in data layer
abstract class RecipeRepository {
  Future<List<Recipe>> fetchWeekly(DateTime weekStart);
  Future<List<Recipe>> fetchAll();
  Future<Recipe?> fetchById(String id);
  Future<void> saveUserSelection(
      String userId, List<String> recipeIds, DateTime weekStart);
  Future<List<String>> loadUserSelection(String userId, DateTime weekStart);
}



