import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final boxFlowProvider =
    ChangeNotifierProvider<BoxFlowController>((_) => BoxFlowController());

class BoxFlowController extends ChangeNotifier {
  final supa = Supabase.instance.client;

  // Week context
  late final String weekStr = _mondayUtcStr(DateTime.now());
  String _mondayUtcStr(DateTime d) {
    final local = DateTime(d.year, d.month, d.day);
    final delta = local.weekday - DateTime.monday;
    final monLocal = local.subtract(Duration(days: delta));
    final monUtc = DateTime.utc(monLocal.year, monLocal.month, monLocal.day);
    return DateFormat('yyyy-MM-dd').format(monUtc);
  }

  // Profile / plan
  int mealsPerWeek = 3; // plan size
  int servingsPerMeal = 2;
  final Set<String> selectedIds = {}; // recipe ids selected for the week

  // Delivery state (HelloChef-style)
  String deliveryCity = 'Addis Ababa';
  DateTime? deliveryDate1; // local date
  String? deliveryWindow1Id; // uuid to a window row
  bool deliveryPrefConfirmed = false; // "Confirm to view recipes"

  bool get hasDeliveryChoice =>
      deliveryDate1 != null && deliveryWindow1Id != null;

  // Server knowledge
  bool serverHasSelections = false;

  // Recipes
  List<Map<String, dynamic>> recipes = [];
  bool loading = false;
  String? error;

  // Filters / sort
  final Set<String> activeChips =
      {}; // e.g. {rapid, family, veggie, bestseller, new}
  String sortKey =
      'none'; // 'kcal_asc','cook_asc','protein_desc','carb_asc' (fallbacks handled)

  // Chip "learning": simple weights that we'll reorder by
  final Map<String, double> chipWeights = {
    'rapid': 0.6,
    'family': 0.5,
    'veggie': 0.4,
    'bestseller': 0.3,
    'new': 0.2,
  };

  Future<void> loadRecipesAndSelections() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      // profile
      final uid = supa.auth.currentUser?.id;
      if (uid != null) {
        final prof =
            await supa.from('profiles').select().eq('id', uid).maybeSingle();
        if (prof != null) {
          mealsPerWeek = (prof['meals_per_week'] as int?) ?? mealsPerWeek;
          servingsPerMeal =
              (prof['servings_per_meal'] as int?) ?? servingsPerMeal;
        }
      }

      // Recipes for week
      final r = await supa
          .from('recipes')
          .select()
          .eq('week_start', weekStr)
          .eq('is_active', true)
          .order('name', ascending: true);
      recipes = List<Map<String, dynamic>>.from(r);

      // Existing selections
      if (uid != null) {
        final sel = await supa
            .from('user_meal_selections')
            .select('recipe_id')
            .eq('user_id', uid)
            .eq('week_start', weekStr);
        serverHasSelections = sel.isNotEmpty;
        if (selectedIds.isEmpty && sel.isNotEmpty) {
          selectedIds.addAll(sel.map<String>((e) => e['recipe_id'] as String));
        }
      }
    } catch (e) {
      error = '$e';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<List<Map<String, dynamic>>> loadWindowsForDate(DateTime date) async {
    final res = await supa.from('delivery_windows').select().order('slot');
    return List<Map<String, dynamic>>.from(res);
  }

  // Delivery actions
  void setDelivery1(DateTime date, String windowId) {
    deliveryDate1 = date;
    deliveryWindow1Id = windowId;
    notifyListeners();
  }

  void confirmDeliveryPref() {
    deliveryPrefConfirmed = true;
    notifyListeners();
  }

  // Selection
  void togglePick(String recipeId) {
    if (selectedIds.contains(recipeId)) {
      selectedIds.remove(recipeId);
    } else {
      if (selectedIds.length >= mealsPerWeek) return; // hard cap
      selectedIds.add(recipeId);
    }
    _nudgeChipWeightsForRecipe(recipeId, 0.05); // tiny learning bump
    notifyListeners();
  }

  Future<void> persistSelections() async {
    final uid = supa.auth.currentUser!.id;
    await supa
        .from('user_meal_selections')
        .delete()
        .match({'user_id': uid, 'week_start': weekStr});
    if (selectedIds.isEmpty) return;
    final rows = selectedIds
        .map((rid) => {'user_id': uid, 'week_start': weekStr, 'recipe_id': rid})
        .toList();
    await supa.from('user_meal_selections').insert(rows);
    serverHasSelections = true;
    notifyListeners();
  }

  // Chips
  void toggleChip(String key) {
    if (activeChips.contains(key)) {
      activeChips.remove(key);
      chipWeights[key] = max(0, chipWeights[key]! - 0.01);
    } else {
      activeChips.add(key);
      chipWeights[key] = chipWeights[key]! + 0.02;
    }
    notifyListeners();
  }

  List<String> orderedChips() {
    final keys = chipWeights.keys.toList();
    keys.sort((a, b) => chipWeights[b]!.compareTo(chipWeights[a]!));
    return keys;
  }

  void setSort(String key) {
    sortKey = key;
    notifyListeners();
  }

  // Derived list
  List<Map<String, dynamic>> get filteredSorted {
    Iterable<Map<String, dynamic>> it = recipes;

    if (activeChips.isNotEmpty) {
      it = it.where((r) {
        final cats = List<String>.from(r['categories'] ?? const <String>[]);
        // map chips to categories/tags
        bool match(String chip) {
          switch (chip) {
            case 'rapid':
              return cats.contains('quick_easy');
            case 'family':
              return cats.contains('family');
            case 'veggie':
              return cats.contains('veggie');
            case 'bestseller':
              return (r['tags'] ?? []).contains('bestseller');
            case 'new':
              return (r['tags'] ?? []).contains('new');
            default:
              return false;
          }
        }

        return activeChips.any(match);
      });
    }

    final list = it.toList();
    int kcal(Map r) => (r['kcal'] ?? 0) as int;
    int cook(Map r) => (r['cook_minutes'] ?? 0) as int;

    switch (sortKey) {
      case 'kcal_asc':
        list.sort((a, b) => kcal(a).compareTo(kcal(b)));
        break;
      case 'cook_asc':
        list.sort((a, b) => cook(a).compareTo(cook(b)));
        break;
      case 'kcal_desc':
        list.sort((a, b) => kcal(b).compareTo(kcal(a)));
        break;
      default:
        break;
    }
    return list;
  }

  void _nudgeChipWeightsForRecipe(String recipeId, double delta) {
    final r = recipes.firstWhere(
        (e) => (e['id']?.toString() ?? e['slug'].toString()) == recipeId,
        orElse: () => <String, dynamic>{});
    final cats = List<String>.from(r['categories'] ?? const <String>[]);
    if (cats.contains('quick_easy'))
      chipWeights['rapid'] = (chipWeights['rapid'] ?? 0.3) + delta;
    if (cats.contains('family'))
      chipWeights['family'] = (chipWeights['family'] ?? 0.3) + delta;
    if (cats.contains('veggie'))
      chipWeights['veggie'] = (chipWeights['veggie'] ?? 0.3) + delta;
  }
}
