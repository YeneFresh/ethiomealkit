import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../auto_select.dart';

/// User's box size (from onboarding) - determines how many recipes they can select
final userBoxSizeProvider =
    StateProvider<int>((_) => 4); // Default 4 for guests

/// Selected recipe IDs (local state)
class SelectionState extends StateNotifier<Set<String>> {
  SelectionState() : super({});

  void toggle(String recipeId) {
    final next = Set<String>.from(state);
    if (next.contains(recipeId)) {
      next.remove(recipeId);
    } else {
      next.add(recipeId);
    }
    state = next;
  }

  void setAll(List<String> ids) => state = ids.toSet();
  void clear() => state = {};
}

final selectedRecipesProvider =
    StateNotifierProvider<SelectionState, Set<String>>(
  (ref) => SelectionState(),
);

/// Auto-selected recipe IDs (to show ribbons)
final autoSelectedIdsProvider = StateProvider<Set<String>>((_) => {});

/// Auto-select hook - picks recipes on first load based on tags/weights
/// Returns the list of picked IDs
Future<List<String>> autoSelectIfNeeded({
  required WidgetRef ref,
  required List<Map<String, dynamic>> recipes,
  required int boxSize,
}) async {
  final selected = ref.read(selectedRecipesProvider);
  if (boxSize <= 0 || selected.isNotEmpty || recipes.isEmpty) {
    return [];
  }

  // Check if already auto-selected this week
  final weekStart = recipes.first['week_start'] != null
      ? DateTime.parse(recipes.first['week_start'].toString())
      : DateTime.now();
  final weekKey = weekStart.toIso8601String().substring(0, 10);

  final prefs = await SharedPreferences.getInstance();
  final alreadyDone = prefs.getBool('auto_select_applied:$weekKey') ?? false;
  if (alreadyDone) {
    print('ℹ️ Auto-select already done for week $weekKey');
    return [];
  }

  // Determine target auto-select count
  final targetAuto = boxSize <= 3 ? 1 : 3;

  // Use existing auto-select logic
  final request = AutoSelectRequest(
    recipes: recipes,
    alreadySelectedIds: {},
    allowance: boxSize,
    targetAuto: targetAuto,
    userId: Supabase.instance.client.auth.currentUser?.id ?? 'guest',
    weekStart: weekStart,
  );

  final choice = planAutoSelection(request);
  if (choice.isEmpty) return [];

  // Update providers
  ref.read(selectedRecipesProvider.notifier).setAll(choice.toSelect);
  ref.read(autoSelectedIdsProvider.notifier).state = choice.toSelect.toSet();

  // Mark as done
  await prefs.setBool('auto_select_applied:$weekKey', true);

  print(
      '🤖 Auto-selected ${choice.toSelect.length} recipes: ${choice.toSelect}');
  return choice.toSelect;
}
