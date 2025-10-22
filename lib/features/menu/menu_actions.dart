import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> pickRecipe({
  required String recipeId,
  required DateTime weekStart,
}) async {
  final supa = Supabase.instance.client;
  final uid = supa.auth.currentUser!.id;
  await supa.from('user_meal_selections').insert({
    'user_id': uid,
    'week_start': DateTime(
      weekStart.year,
      weekStart.month,
      weekStart.day,
    ).toIso8601String(),
    'recipe_id': recipeId,
  });
}

Future<void> unpickRecipe({
  required String recipeId,
  required DateTime weekStart,
}) async {
  final supa = Supabase.instance.client;
  final uid = supa.auth.currentUser!.id;
  await supa.from('user_meal_selections').delete().match({
    'user_id': uid,
    'week_start': DateTime(
      weekStart.year,
      weekStart.month,
      weekStart.day,
    ).toIso8601String(),
    'recipe_id': recipeId,
  });
}
