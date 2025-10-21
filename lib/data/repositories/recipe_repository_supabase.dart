import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/recipe.dart';
import '../../domain/repositories/recipe_repository.dart';
import '../dtos/recipe_dto.dart';

/// Supabase implementation of RecipeRepository
class RecipeRepositorySupabase implements RecipeRepository {
  final SupabaseClient _sb;

  RecipeRepositorySupabase(this._sb);

  @override
  Future<List<Recipe>> fetchWeekly(DateTime weekStart) async {
    try {
      final res = await _sb.rpc('get_weekly_menu', params: {
        'week_start': weekStart.toUtc().toIso8601String(),
      });

      return (res as List)
          .map((json) => RecipeDto.fromJson(json).toEntity())
          .toList();
    } catch (e) {
      print('❌ Error fetching weekly menu: $e');
      // Fallback to fetchAll if RPC not available
      return fetchAll();
    }
  }

  @override
  Future<List<Recipe>> fetchAll() async {
    try {
      final res = await _sb
          .from('recipes')
          .select('*')
          .eq('is_active', true)
          .order('sort_order');

      return (res as List)
          .map((json) => RecipeDto.fromJson(json).toEntity())
          .toList();
    } catch (e) {
      print('❌ Error fetching all recipes: $e');
      rethrow;
    }
  }

  @override
  Future<Recipe?> fetchById(String id) async {
    try {
      final res =
          await _sb.from('recipes').select('*').eq('id', id).maybeSingle();

      if (res == null) return null;

      return RecipeDto.fromJson(res).toEntity();
    } catch (e) {
      print('❌ Error fetching recipe $id: $e');
      return null;
    }
  }

  @override
  Future<void> saveUserSelection(
      String userId, List<String> recipeIds, DateTime weekStart) async {
    try {
      // Use RPC or direct insert depending on schema
      await _sb.rpc('save_user_recipe_selection', params: {
        'p_user_id': userId,
        'p_recipe_ids': recipeIds,
        'p_week_start': weekStart.toUtc().toIso8601String(),
      });
      print('✅ Saved ${recipeIds.length} recipe selections');
    } catch (e) {
      print('❌ Error saving selections: $e');
      // Gracefully fail for guest users
    }
  }

  @override
  Future<List<String>> loadUserSelection(
      String userId, DateTime weekStart) async {
    try {
      final res = await _sb
          .from('user_recipe_selections')
          .select('recipe_id')
          .eq('user_id', userId)
          .eq('week_start', weekStart.toUtc().toIso8601String());

      return (res as List).map((r) => r['recipe_id'] as String).toList();
    } catch (e) {
      print('❌ Error loading selections: $e');
      return [];
    }
  }
}



