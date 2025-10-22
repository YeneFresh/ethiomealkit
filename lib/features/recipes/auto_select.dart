/// Smart partial auto-selection logic for recipes.
///
/// Rules:
/// - Box size 2 → auto-select 1 recipe
/// - Box size 4 → auto-select 3 recipes
/// - Never exceed remaining allowance
/// - Run once per week per user (idempotent)
///
/// Strategy:
/// 1. Prefer "Chef's Choice" recipes
/// 2. Then prefer Healthy/Fresh tags
/// 3. Ensure variety (avoid duplicate primary tags)
/// 4. Stable randomization for ties
library;

class AutoSelectRequest {
  final List<Map<String, dynamic>> recipes; // from currentWeeklyRecipes()
  final Set<String> alreadySelectedIds; // from userSelections()
  final int allowance; // meals_per_week
  final int targetAuto; // 1 if box=2, 3 if box=4
  final String userId;
  final DateTime weekStart;

  AutoSelectRequest({
    required this.recipes,
    required this.alreadySelectedIds,
    required this.allowance,
    required this.targetAuto,
    required this.userId,
    required this.weekStart,
  });
}

class AutoSelectChoice {
  final List<String> toSelect; // recipe ids to add

  AutoSelectChoice({required this.toSelect});

  bool get isEmpty => toSelect.isEmpty;
  bool get isNotEmpty => toSelect.isNotEmpty;
  int get count => toSelect.length;
}

/// Plans which recipes to auto-select based on smart ranking.
AutoSelectChoice planAutoSelection(AutoSelectRequest r) {
  // Calculate how many we need
  final remaining = r.allowance - r.alreadySelectedIds.length;
  final needed = (r.targetAuto - (r.alreadySelectedIds.isEmpty ? 0 : 0))
      .clamp(0, remaining);

  if (needed <= 0) {
    return AutoSelectChoice(toSelect: []);
  }

  // Filter out already selected recipes
  List<Map<String, dynamic>> candidates = r.recipes
      .where((x) => !(r.alreadySelectedIds.contains(x['id'] as String)))
      .toList();

  if (candidates.isEmpty) {
    return AutoSelectChoice(toSelect: []);
  }

  // Score each recipe
  int score(Map<String, dynamic> rec) {
    final tags = _extractTags(rec);
    int s = 0;

    // Chef's Choice gets highest priority
    if (tags.contains("chef's choice") || tags.contains('chef_choice')) {
      s += 100;
    }

    // Healthy/Fresh tags
    if (tags.intersection({'healthy', 'light', 'veggie', 'fresh'}).isNotEmpty) {
      s += 30;
    }

    // Quick/Fast recipes
    if (tags.contains('30-min') || tags.contains('quick')) {
      s += 10;
    }

    // Stable tie-breaker using hash of user + recipe + week
    final h = _stableHash(
      '${r.userId}${rec['id']}${r.weekStart.toIso8601String()}',
    );
    return (s * 10000) + (h % 10000);
  }

  // Sort candidates by score (descending)
  candidates.sort((a, b) => score(b).compareTo(score(a)));

  // Apply variety rule: avoid stacking same primary tag
  final chosen = <String>[];
  final usedPrimaries = <String>{};

  for (final rec in candidates) {
    if (chosen.length >= needed) break;

    final primary = _primaryTagOf(rec);

    // Skip if we already used this primary tag and we have enough alternatives
    if (usedPrimaries.contains(primary) && candidates.length > needed * 2) {
      continue;
    }

    chosen.add(rec['id'] as String);
    usedPrimaries.add(primary);
  }

  return AutoSelectChoice(toSelect: chosen);
}

/// Extracts tags from a recipe as a lowercase set.
Set<String> _extractTags(Map<String, dynamic> rec) {
  final tags = rec['tags'];
  if (tags == null) return {};

  if (tags is List) {
    return tags.map((e) => e.toString().toLowerCase()).toSet();
  }

  return {};
}

/// Determines the primary tag for variety checking.
String _primaryTagOf(Map<String, dynamic> rec) {
  final tags = _extractTags(rec).toList()..sort(); // Sort for determinism

  // Priority tags (check in order)
  const priorities = [
    "chef's choice",
    'chef_choice',
    'healthy',
    'light',
    'spicy',
    'beef',
    'chicken',
    'fish',
    'veg',
    'veggie',
    'ethiopian',
    'fusion',
  ];

  for (final p in priorities) {
    if (tags.contains(p)) return p;
  }

  return tags.isNotEmpty ? tags.first : 'other';
}

/// Stable hash function for tie-breaking.
int _stableHash(String input) {
  return input.codeUnits.fold<int>(
    0,
    (a, b) => ((a * 31) + b) & 0x7fffffff,
  );
}

/// Calculates target auto-select count based on box size.
int calculateTargetAuto(int mealsPerWeek) {
  if (mealsPerWeek <= 3) return 1; // Conservative for 2-3 person plans
  return 3; // 4+ person plans get 3 pre-selected
}
