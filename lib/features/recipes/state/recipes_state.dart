import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ethiomealkit/data/api/supa_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Recipe tags for filtering and badging
enum RecipeTag {
  chefsChoice,
  express,
  family,
  recommended,
  new_,
  healthy,
  spicy,
}

/// Weekly recipes provider - fetches from Supabase
final weeklyRecipesProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  try {
    final api = SupaClient(Supabase.instance.client);
    final recipes = await api.currentWeeklyRecipes(limit: 15);
    print('📦 Riverpod: Loaded ${recipes.length} recipes');
    return recipes;
  } catch (e) {
    print('❌ Riverpod: Failed to load recipes: $e');
    return [];
  }
});

/// User selections provider - fetches from Supabase or local storage
final userSelectionsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  try {
    final api = SupaClient(Supabase.instance.client);
    final selections = await api.userSelections();
    print('📦 Riverpod: Loaded ${selections.length} selections');
    return selections;
  } catch (e) {
    print('ℹ️ Riverpod: No selections yet (fresh user): $e');
    return [];
  }
});

/// Helper to get recipe tag from string
RecipeTag? recipeTagFromString(String tag) {
  final tagLower = tag.toLowerCase();
  if (tagLower.contains("chef") || tagLower == 'chef_choice') {
    return RecipeTag.chefsChoice;
  }
  if (tagLower == 'express' || tagLower == 'quick' || tagLower == '30-min') {
    return RecipeTag.express;
  }
  if (tagLower == 'family' || tagLower == 'family-friendly') {
    return RecipeTag.family;
  }
  if (tagLower == 'new') {
    return RecipeTag.new_;
  }
  if (tagLower == 'healthy' || tagLower == 'light') {
    return RecipeTag.healthy;
  }
  if (tagLower == 'spicy') {
    return RecipeTag.spicy;
  }
  return null;
}
