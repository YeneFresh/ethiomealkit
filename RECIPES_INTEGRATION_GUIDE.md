# Recipes Integration Guide

## ✅ Completed Components

### 1. `lib/features/recipes/widgets/recipe_card.dart`
Premium recipe card with:
- 4:3 aspect ratio images
- Badges (Chef's Choice, New, Fast, Light)
- Chef notes
- Selection state with micro-scale animation (1.0 → 1.03 → 1.0)
- Haptic feedback
- Quota indicator
- Design tokens only (no inline colors)

### 2. `lib/features/recipes/auto_select.dart`
Smart auto-selection logic:
- Box=2 → selects 1 recipe
- Box=4 → selects 3 recipes
- Prioritizes Chef's Choice → Healthy/Fresh → Quick
- Ensures variety (avoids duplicate primary tags)
- Stable randomization for ties
- Functions: `planAutoSelection()`, `calculateTargetAuto()`

### 3. `lib/features/recipes/widgets/recipe_filters_bar.dart`
Horizontal scrollable filter chips:
- 10 filters: healthy, spicy, veggie, <30min, Ethiopian, beef, chicken, fish, new, chef's pick
- Debounced updates (150ms)
- Shows result count when filters active
- Clear all button
- 44dp tap targets (accessibility)

### 4. `lib/features/recipes/nudges.dart`
Retention components:
- `HandpickedBanner` - dismissible auto-select notification
- `SelectionProgress` - progress bar + social proof ("Most choose 3–4")
- `QuotaFullSnackBar` - shown when max reached

---

## 🔧 Integration Steps for `recipes_screen.dart`

### Step 1: Add Imports

```dart
// Add these imports at the top
import 'widgets/recipe_card.dart';
import 'widgets/recipe_filters_bar.dart';
import 'nudges.dart';
import 'auto_select.dart';
```

### Step 2: Add State Variables

```dart
class _RecipesScreenState extends ConsumerState<RecipesScreen>
    with TickerProviderStateMixin {
  // ... existing state ...
  
  // NEW: Add these
  Set<String> _activeFilters = {};
  bool _showHandpickedBanner = false;
  List<Map<String, dynamic>> _filteredRecipes = [];
}
```

### Step 3: Replace Auto-Select Logic

**Current code** (lines 200-259):
```dart
Future<void> _autoSelectRecipes() async {
  // ... basic logic that selects first N ...
}
```

**Replace with:**
```dart
Future<void> _autoSelectRecipes() async {
  await Future.delayed(Duration(milliseconds: 400));
  if (!mounted) return;

  try {
    final api = SupaClient(Supabase.instance.client);
    
    // Use smart auto-selection
    final request = AutoSelectRequest(
      recipes: _recipes,
      alreadySelectedIds: _selections
          .where((s) => s['selected'] == true)
          .map((s) => s['recipe_id'] as String)
          .toSet(),
      allowance: _allowedCount,
      targetAuto: calculateTargetAuto(_allowedCount),
      userId: Supabase.instance.client.auth.currentUser?.id ?? '',
      weekStart: DateTime.now(), // Use actual week_start from API
    );

    final choice = planAutoSelection(request);
    
    if (choice.isEmpty) return;

    // Apply selections
    for (var recipeId in choice.toSelect) {
      await api.toggleRecipeSelection(
        recipeId: recipeId,
        select: true,
      );
    }

    await _loadData();
    
    // Show handpicked banner
    setState(() {
      _showHandpickedBanner = true;
    });

    // Track analytics
    Analytics.recipesAutoSelected(count: choice.count);
  } catch (e) {
    print('Auto-selection failed: $e');
  }
}
```

### Step 4: Add Filter Logic

```dart
void _updateFilters(Set<String> filters) {
  setState(() {
    _activeFilters = filters;
    _applyFilters();
  });
  
  // Analytics
  // Analytics.filterToggled(filters: filters.toList());
}

void _applyFilters() {
  if (_activeFilters.isEmpty) {
    _filteredRecipes = _recipes;
    return;
  }

  _filteredRecipes = _recipes.where((recipe) {
    final tags = (recipe['tags'] as List?)
        ?.map((t) => t.toString().toLowerCase())
        .toSet() ?? {};
    
    return _activeFilters.any((filter) => tags.contains(filter));
  }).toList();
}
```

### Step 5: Update Build Method - Replace `_buildRecipesView`

**Key changes:**
1. Add `SelectionProgress` widget after progress header
2. Add `HandpickedBanner` if `_showHandpickedBanner`
3. Add `RecipeFiltersBar` before grid
4. Replace recipe card rendering with new `RecipeCard` widget
5. Add `cacheExtent: 800` to GridView

**Updated `_buildRecipesView` structure:**
```dart
Widget _buildRecipesView(BuildContext context, ThemeData theme) {
  if (_recipes.isEmpty) {
    return _buildEmptyState(theme);
  }

  final recipesToShow = _activeFilters.isEmpty ? _recipes : _filteredRecipes;

  return Column(
    children: [
      // 1. Selection Progress
      Padding(
        padding: EdgeInsets.symmetric(vertical: Yf.s16),
        child: SelectionProgress(
          selected: _selectedCount,
          total: _allowedCount,
          showSocialProof: true,
        ),
      ),

      // 2. Handpicked Banner (dismissible)
      if (_showHandpickedBanner)
        HandpickedBanner(
          onDismiss: () => setState(() => _showHandpickedBanner = false),
        ),

      // 3. Filters Bar
      RecipeFiltersBar(
        activeFilters: _activeFilters,
        onFiltersChanged: _updateFilters,
        resultCount: recipesToShow.length,
      ),

      SizedBox(height: Yf.s16),

      // 4. Recipe Grid
      Expanded(
        child: GridView.builder(
          padding: EdgeInsets.all(Yf.s16),
          cacheExtent: 800, // Performance optimization
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: Yf.s16,
            mainAxisSpacing: Yf.s16,
          ),
          itemCount: recipesToShow.length,
          itemBuilder: (context, index) {
            final recipe = recipesToShow[index];
            final isSelected = _selections.any(
              (s) => s['recipe_id'] == recipe['id'] && s['selected'] == true,
            );

            // NEW: Use RecipeCard widget
            return AnimatedBuilder(
              animation: _animationControllers[index],
              builder: (context, child) => SlideTransition(
                position: _slideAnimations[index],
                child: FadeTransition(
                  opacity: _fadeAnimations[index],
                  child: RecipeCard(
                    id: recipe['id'],
                    title: recipe['title'],
                    imageUrl: recipe['image_url'],
                    tags: List<String>.from(recipe['tags'] ?? []),
                    isSelected: isSelected,
                    chefNote: _getChefNote(recipe),
                    selectedCount: _selectedCount,
                    allowedCount: _allowedCount,
                    onTap: () => _toggleRecipe(recipe['id']),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ],
  );
}
```

### Step 6: Helper Methods

```dart
String? _getChefNote(Map<String, dynamic> recipe) {
  final tags = (recipe['tags'] as List?)?.map((t) => t.toString().toLowerCase()).toSet() ?? {};
  
  if (tags.contains("chef's choice")) {
    // Could pull from recipe metadata or hardcode based on tags
    if (tags.contains('spicy')) return "Chef's pick · Spicy · 30-min";
    if (tags.contains('healthy')) return "Chef's pick · Light & fresh";
    return "Chef's favorite";
  }
  return null;
}

Future<void> _toggleRecipe(String recipeId) async {
  // Check if at quota and trying to add
  final isSelected = _selections.any(
    (s) => s['recipe_id'] == recipeId && s['selected'] == true,
  );

  if (!isSelected && _selectedCount >= _allowedCount) {
    ScaffoldMessenger.of(context).showSnackBar(
      QuotaFullSnackBar(context: context),
    );
    return;
  }

  try {
    final api = SupaClient(Supabase.instance.client);
    await api.toggleRecipeSelection(
      recipeId: recipeId,
      select: !isSelected,
    );
    await _loadData();
    
    // Analytics
    // if (isSelected) {
    //   Analytics.recipeDeselected(recipeId: recipeId);
    // } else {
    //   Analytics.recipeSelected(recipeId: recipeId);
    // }
  } catch (e) {
    print('Toggle failed: $e');
  }
}
```

---

## 📊 Analytics Events to Wire

Add these to `lib/core/analytics.dart`:

```dart
static void recipeSelected({required String recipeId, String? title}) {
  trackEvent('recipe_selected', {'recipe_id': recipeId, 'title': title});
}

static void recipeDeselected({required String recipeId}) {
  trackEvent('recipe_deselected', {'recipe_id': recipeId});
}

static void filterToggled({required List<String> filters}) {
  trackEvent('filter_toggled', {'active_filters': filters});
}
```

---

## 🎨 Performance Checklist

- ✅ `cacheExtent: 800` on GridView
- ⏳ Image precaching (add after first idle frame)
- ✅ Debounced filters (150ms built-in)
- ⏳ Memoize filtered results if needed

---

## 🧪 Testing TODO

1. Golden tests for RecipeCard (light/dark, selected/unselected)
2. Golden test for RecipeFiltersBar with active chips
3. Unit test auto-select logic (`test/logic/auto_select_test.dart`)
4. Integration test full flow

---

## 🚀 Quick Start

1. Copy the integration steps above
2. Update `recipes_screen.dart` section by section
3. Test the flow: Delivery → Recipes → Auto-select → Filters
4. Add analytics wiring
5. Run linter and fix any errors
6. Test on device for performance

---

## 🐛 Known Issues to Address

1. Need to pass actual `week_start` from API to auto-select
2. Chef notes currently use tag heuristics - could be DB field
3. Image precaching not yet implemented
4. Analytics calls commented out - wire when ready

---

## 📝 File Summary

**Created:**
- `lib/features/recipes/widgets/recipe_card.dart` (300 lines)
- `lib/features/recipes/auto_select.dart` (120 lines)
- `lib/features/recipes/widgets/recipe_filters_bar.dart` (280 lines)
- `lib/features/recipes/nudges.dart` (200 lines)

**To Update:**
- `lib/features/recipes/recipes_screen.dart` (integrate above)
- `lib/core/analytics.dart` (add 3 events)

**To Create (Testing):**
- `test/logic/auto_select_test.dart`
- `test/ui/recipes_golden_test.dart`





