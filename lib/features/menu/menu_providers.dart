import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Week anchor (Monday of current week)
final weekStartProvider = Provider<DateTime>((ref) {
  final now = DateTime.now();
  final monday = now.subtract(Duration(days: (now.weekday - 1)));
  return DateTime(monday.year, monday.month, monday.day);
});

// Profile stream (id, meals_per_week, preferences, onboarding_complete)
class Profile {
  final String id;
  final int mealsPerWeek;
  final List<String> preferences;
  final bool onboardingComplete;
  Profile(
      {required this.id,
      required this.mealsPerWeek,
      required this.preferences,
      required this.onboardingComplete});
  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        id: j['id'] as String,
        mealsPerWeek: (j['meals_per_week'] ?? 3) as int,
        preferences:
            (j['preferences'] as List?)?.map((e) => e.toString()).toList() ??
                const [],
        onboardingComplete: (j['onboarding_complete'] ?? false) as bool,
      );
}

final profileProvider = FutureProvider.autoDispose<Profile?>((ref) async {
  final supa = Supabase.instance.client;
  final uid = supa.auth.currentUser?.id;
  if (uid == null) return null;
  final rows = await supa.from('profiles').select().eq('id', uid).limit(1);
  return rows.isEmpty ? null : Profile.fromJson(rows.first);
});

// Recipe model used in UI
class Recipe {
  final String id;
  final String slug;
  final String name;
  final List<String> categories;
  final int? cookMinutes;
  final String? heroImage;
  Recipe(
      {required this.id,
      required this.slug,
      required this.name,
      required this.categories,
      this.cookMinutes,
      this.heroImage});
  factory Recipe.fromJson(Map<String, dynamic> j) => Recipe(
        id: j['id'] as String,
        slug: j['slug'] as String,
        name: j['name'] as String,
        categories:
            (j['categories'] as List?)?.map((e) => e.toString()).toList() ??
                const [],
        cookMinutes: j['cook_minutes'] as int?,
        heroImage: j['hero_image'] as String?,
      );
}

// Weekly menu for weekStart (joined to recipes)
final weeklyMenuProvider =
    FutureProvider.autoDispose<List<Recipe>>((ref) async {
  final supa = Supabase.instance.client;
  final weekStart = ref.watch(weekStartProvider);
  final rows = await supa
      .from('weekly_menu')
      .select(
          'week_start, recipes:recipe_id(id,slug,name,categories,cook_minutes,hero_image)')
      .eq('week_start', weekStart.toIso8601String().substring(0, 10));
  final list = (rows as List)
      .map((r) => Recipe.fromJson(r['recipes'] as Map<String, dynamic>))
      .toList();
  return list;
});

// User selections for the week (recipe_id set)
final userSelectionsProvider =
    FutureProvider.autoDispose<Set<String>>((ref) async {
  final supa = Supabase.instance.client;
  final uid = supa.auth.currentUser?.id;
  if (uid == null) return <String>{};
  final weekStart = ref.watch(weekStartProvider);
  final rows = await supa
      .from('user_meal_selections')
      .select('recipe_id')
      .eq('user_id', uid)
      .eq('week_start', weekStart.toIso8601String().substring(0, 10));
  return rows.map<String>((r) => r['recipe_id'] as String).toSet();
});

// Filtered menu using profile.preferences (MVP local filter)
final filteredMenuProvider = Provider.autoDispose<List<Recipe>>((ref) {
  final menu = ref
      .watch(weeklyMenuProvider)
      .maybeWhen(data: (d) => d, orElse: () => const <Recipe>[]);
  final profile =
      ref.watch(profileProvider).maybeWhen(data: (p) => p, orElse: () => null);
  if (profile == null || profile.preferences.isEmpty) return menu;
  return menu
      .where((r) => r.categories
          .toSet()
          .intersection(profile.preferences.toSet())
          .isNotEmpty)
      .toList();
});

final sortByProvider = StateProvider<String>((_) => 'default');

class FilterState {
  final Set<String> tags;
  const FilterState({this.tags = const {}});
  FilterState copyWith({Set<String>? tags}) =>
      FilterState(tags: tags ?? this.tags);
}

class FilterStateNotifier extends StateNotifier<FilterState> {
  FilterStateNotifier() : super(const FilterState());
  void toggle(String k) {
    final s = Set<String>.from(state.tags);
    s.contains(k) ? s.remove(k) : s.add(k);
    state = state.copyWith(tags: s);
  }

  void clear() => state = const FilterState();
}

final filterStateProvider =
    StateNotifierProvider<FilterStateNotifier, FilterState>(
  (_) => FilterStateNotifier(),
);

class QuickChipNotifier extends StateNotifier<Set<String>> {
  QuickChipNotifier() : super({});
  void toggle(String k) {
    final s = Set<String>.from(state);
    s.contains(k) ? s.remove(k) : s.add(k);
    state = s;
  }
}

final quickChipProvider = StateNotifierProvider<QuickChipNotifier, Set<String>>(
  (_) => QuickChipNotifier(),
);
