# Clean Architecture Migration Guide

## 🎯 Goal
Kill widget-level business logic, speed up tests, make Cursor changes safer.

## 📁 New Structure

```
lib/
├── core/
│   ├── providers/
│   │   ├── repository_providers.dart     # DI for repos
│   │   ├── usecase_providers.dart        # DI for use-cases
│   │   └── clean_recipe_providers.dart   # Clean controllers
│   ├── theme/
│   ├── widgets/
│   └── services/
│
├── domain/                                # Pure Dart, no Flutter!
│   ├── entities/
│   │   ├── recipe.dart                   # Business model
│   │   └── delivery_slot.dart            # Business model
│   ├── repositories/                      # Interfaces only
│   │   ├── recipe_repository.dart
│   │   └── delivery_repository.dart
│   └── usecases/                          # Business logic
│       ├── get_weekly_menu.dart
│       ├── auto_select_recipes.dart
│       └── get_available_delivery_slots.dart
│
├── data/                                  # Framework-specific
│   ├── dtos/
│   │   ├── recipe_dto.dart               # JSON ↔ Entity
│   │   └── delivery_slot_dto.dart
│   └── repositories/
│       ├── recipe_repository_supabase.dart
│       └── delivery_repository_supabase.dart
│
└── features/
    └── [feature]/
        ├── widgets/                       # Dumb UI only!
        └── screens/                       # Compose providers
```

---

## 🔄 Migration Pattern

### Before (Old Code)
```dart
// ❌ Widget has business logic
class RecipeCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipes = ref.watch(recipesProvider);
    
    // Business logic in widget!
    final filtered = recipes.where((r) => 
        r.tags.contains('Popular') && r.cookMinutes < 30
    ).toList();
    
    return ListView(...);
  }
}
```

### After (Clean)
```dart
// ✅ Widget is dumb, logic in use-case
class RecipeCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipes = ref.watch(weeklyMenuControllerProvider);
    
    // Pure rendering, zero logic
    return recipes.when(
      data: (list) => ListView(...),
      loading: () => CircularProgressIndicator(),
      error: (e, st) => ErrorWidget(e),
    );
  }
}
```

---

## 📦 Layer Responsibilities

### **Domain Layer** (Pure Dart)
- ✅ Business entities (`Recipe`, `DeliverySlot`)
- ✅ Repository interfaces (contracts)
- ✅ Use cases (business logic)
- ❌ No Flutter imports
- ❌ No Supabase imports
- ❌ No UI code

**Example:**
```dart
// domain/usecases/auto_select_recipes.dart
class AutoSelectRecipes {
  List<String> call({
    required List<Recipe> available,
    required int count,
  }) {
    // Pure business logic
    return available
        .where((r) => r.isChefChoice || r.isPopular)
        .take(count)
        .map((r) => r.id)
        .toList();
  }
}
```

### **Data Layer** (Framework-Specific)
- ✅ DTOs (JSON ↔ Entity mapping)
- ✅ Repository implementations (Supabase, Hive, etc.)
- ✅ Network/DB calls
- ❌ No business logic
- ❌ No UI code

**Example:**
```dart
// data/repositories/recipe_repository_supabase.dart
class RecipeRepositorySupabase implements RecipeRepository {
  final SupabaseClient _sb;
  
  @override
  Future<List<Recipe>> fetchWeekly(DateTime week) async {
    final res = await _sb.rpc('get_weekly_menu', params: {'week': week});
    return (res as List)
        .map((json) => RecipeDto.fromJson(json).toEntity())
        .toList();
  }
}
```

### **Presentation Layer** (Widgets)
- ✅ UI composition
- ✅ Provider watching
- ✅ User interactions
- ❌ No business logic
- ❌ No direct Supabase calls
- ❌ No data transformation

**Example:**
```dart
// features/weekly_menu/weekly_menu_screen.dart
class WeeklyMenuScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menu = ref.watch(weeklyMenuControllerProvider);
    
    return menu.when(
      data: (recipes) => RecipeGrid(recipes: recipes),
      loading: () => LoadingShimmer(),
      error: (e, st) => ErrorDisplay(error: e),
    );
  }
}
```

---

## 🧪 Testing Benefits

### Before (Impossible to Test)
```dart
// Can't test without Flutter/Supabase
test('recipe filtering', () {
  // Need full widget tree + Supabase connection
});
```

### After (Easy to Test)
```dart
// Pure Dart tests, no mocking needed
test('auto-select picks chef choice first', () {
  final useCase = AutoSelectRecipes();
  final recipes = [
    Recipe(id: '1', tags: ['Chef\'s Choice'], ...),
    Recipe(id: '2', tags: ['Popular'], ...),
  ];
  
  final selected = useCase(available: recipes, count: 1);
  
  expect(selected, ['1']); // Chef's Choice wins
});
```

---

## 🔌 Riverpod Wiring

### Composition Pattern
```dart
// 1. Infrastructure
final supabaseProvider = Provider((_) => Supabase.instance.client);

// 2. Repositories (data layer)
final recipeRepoProvider = Provider<RecipeRepository>(
  (ref) => RecipeRepositorySupabase(ref.read(supabaseProvider))
);

// 3. Use cases (domain layer)
final getWeeklyMenuProvider = Provider<GetWeeklyMenu>(
  (ref) => GetWeeklyMenu(ref.read(recipeRepoProvider))
);

// 4. Controllers (presentation layer)
class WeeklyMenuController extends AsyncNotifier<List<Recipe>> {
  @override
  Future<List<Recipe>> build() async {
    final useCase = ref.read(getWeeklyMenuProvider);
    final week = ref.read(currentWeekStartProvider);
    return await useCase(week);
  }
}

final weeklyMenuControllerProvider = AsyncNotifierProvider<WeeklyMenuController, List<Recipe>>(
  () => WeeklyMenuController()
);
```

---

## 🚀 Migration Steps

### Step 1: Domain Entities (Complete ✅)
- [x] `domain/entities/recipe.dart`
- [x] `domain/entities/delivery_slot.dart`

### Step 2: Repository Interfaces (Complete ✅)
- [x] `domain/repositories/recipe_repository.dart`
- [x] `domain/repositories/delivery_repository.dart`

### Step 3: Use Cases (Complete ✅)
- [x] `domain/usecases/get_weekly_menu.dart`
- [x] `domain/usecases/auto_select_recipes.dart`
- [x] `domain/usecases/get_available_delivery_slots.dart`

### Step 4: Data Layer (Complete ✅)
- [x] `data/dtos/recipe_dto.dart`
- [x] `data/dtos/delivery_slot_dto.dart`
- [x] `data/repositories/recipe_repository_supabase.dart`
- [x] `data/repositories/delivery_repository_supabase.dart`

### Step 5: Riverpod Wiring (Complete ✅)
- [x] `core/providers/repository_providers.dart`
- [x] `core/providers/usecase_providers.dart`
- [x] `core/providers/clean_recipe_providers.dart`

### Step 6: Migrate Existing Code (In Progress)
- [ ] Replace old `recipesProvider` with `weeklyMenuControllerProvider`
- [ ] Replace `selectedRecipesProvider` with `selectedRecipesControllerProvider`
- [ ] Update widgets to use clean providers
- [ ] Remove business logic from widgets

---

## 📝 Code Examples

### Example 1: Fetching Weekly Menu

**Old way (mixed concerns):**
```dart
final recipesProvider = FutureProvider<List<Recipe>>((ref) async {
  final client = Supabase.instance.client;
  final res = await client.from('recipes').select('*');
  return (res as List).map((json) {
    return Recipe(
      id: json['id'],
      title: json['title'],
      // ... lots of mapping logic in provider
    );
  }).toList();
});
```

**New way (clean):**
```dart
// Widget just watches
final menu = ref.watch(weeklyMenuControllerProvider);

// Controller delegates to use-case
class WeeklyMenuController extends AsyncNotifier<List<Recipe>> {
  @override
  Future<List<Recipe>> build() async {
    return ref.read(getWeeklyMenuProvider)(currentWeek());
  }
}

// Use-case has pure business logic
class GetWeeklyMenu {
  Future<List<Recipe>> call(DateTime week) {
    final recipes = await _repo.fetchWeekly(week);
    recipes.sort((a, b) => b.pickScore.compareTo(a.pickScore));
    return recipes;
  }
}

// Repository handles data access
class RecipeRepositorySupabase {
  Future<List<Recipe>> fetchWeekly(DateTime week) {
    final res = await _sb.rpc('get_weekly_menu', ...);
    return (res as List).map(RecipeDto.fromJson).map((d) => d.toEntity()).toList();
  }
}
```

### Example 2: Auto-Selecting Recipes

**Old way:**
```dart
// Business logic scattered in widget
void _autoSelect() {
  final recipes = ref.read(recipesProvider).value ?? [];
  final chefs = recipes.where((r) => r.tags.contains("Chef's Choice"));
  final popular = recipes.where((r) => r.tags.contains('Popular'));
  // ... complex logic here
}
```

**New way:**
```dart
// Widget delegates to controller
ElevatedButton(
  onPressed: () => ref.read(selectedRecipesControllerProvider.notifier).autoSelect(4),
  child: const Text('Auto-complete'),
)

// Controller delegates to use-case
class SelectedRecipesController extends StateNotifier<Set<String>> {
  Future<void> autoSelect(int count) async {
    final useCase = ref.read(autoSelectRecipesProvider);
    final available = ref.read(weeklyMenuControllerProvider).valueOrNull ?? [];
    final selected = useCase(availableRecipes: available, count: count);
    setAll(selected);
  }
}

// Use-case has testable business logic
class AutoSelectRecipes {
  List<String> call({required List<Recipe> available, required int count}) {
    return available
        .where((r) => r.isChefChoice || r.isPopular)
        .take(count)
        .map((r) => r.id)
        .toList();
  }
}
```

---

## ✅ Benefits

### For Development
- **Cursor-safe**: Changes to UI don't break business logic
- **Hot-swappable**: Switch Supabase → Firebase without touching domain
- **Modular**: Each layer has single responsibility
- **Type-safe**: Compile-time errors catch issues early

### For Testing
- **Fast**: Domain tests run in milliseconds (no Flutter/Supabase)
- **Isolated**: Test use-cases without mocking repos
- **Reliable**: No flaky network/DB tests
- **Coverage**: Easy to hit 90%+ coverage

### For Team
- **Onboarding**: New devs understand layers clearly
- **Code review**: Small, focused PRs per layer
- **Debugging**: Error traces point to exact layer
- **Refactoring**: Change data layer without touching domain

---

## 🧪 Example Tests

### Domain Layer Test
```dart
// test/domain/usecases/auto_select_recipes_test.dart
void main() {
  test('auto-select prioritizes chef choice over popular', () {
    final useCase = AutoSelectRecipes();
    
    final recipes = [
      Recipe(id: '1', tags: ['Popular'], cookMinutes: 20, ...),
      Recipe(id: '2', tags: ['Chef\'s Choice'], cookMinutes: 30, ...),
    ];
    
    final selected = useCase(availableRecipes: recipes, count: 1);
    
    expect(selected, ['2']); // Chef's Choice wins
  });
  
  test('auto-select prefers quick recipes when equal priority', () {
    final useCase = AutoSelectRecipes();
    
    final recipes = [
      Recipe(id: '1', tags: ['Popular'], cookMinutes: 40, ...),
      Recipe(id: '2', tags: ['Popular'], cookMinutes: 20, ...),
    ];
    
    final selected = useCase(availableRecipes: recipes, count: 1);
    
    expect(selected, ['2']); // Shorter cook time wins
  });
}
```

### Repository Test (with fake)
```dart
// test/data/repositories/recipe_repository_fake.dart
class RecipeRepositoryFake implements RecipeRepository {
  final List<Recipe> _fakeData = [
    Recipe(id: '1', title: 'Doro Wat', ...),
    Recipe(id: '2', title: 'Kitfo', ...),
  ];
  
  @override
  Future<List<Recipe>> fetchWeekly(DateTime week) async {
    await Future.delayed(Duration(milliseconds: 10)); // Simulate network
    return _fakeData;
  }
}

void main() {
  test('weekly menu returns sorted recipes', () async {
    final repo = RecipeRepositoryFake();
    final useCase = GetWeeklyMenu(repo);
    
    final result = await useCase(DateTime.now());
    
    expect(result.length, 2);
    expect(result.first.title, 'Doro Wat');
  });
}
```

---

## 🔧 How to Use in Widgets

### Old Way (Business Logic in Widget)
```dart
class RecipesScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipesAsync = ref.watch(recipesProvider);
    
    // ❌ Business logic here
    final filtered = recipesAsync.value?.where((r) {
      return r.tags.contains('Chef\'s Choice') && r.cookMinutes < 30;
    }).toList() ?? [];
    
    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (_, i) => RecipeCard(recipe: filtered[i]),
    );
  }
}
```

### New Way (Dumb Widget, Smart Provider)
```dart
// Widget is pure presentation
class RecipesScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menu = ref.watch(weeklyMenuControllerProvider);
    
    return menu.when(
      data: (recipes) => ListView.builder(
        itemCount: recipes.length,
        itemBuilder: (_, i) => RecipeCard(recipe: recipes[i]),
      ),
      loading: () => const CircularProgressIndicator(),
      error: (e, _) => ErrorDisplay(error: e),
    );
  }
}

// Business logic in use-case (testable!)
class GetWeeklyMenu {
  Future<List<Recipe>> call(DateTime week) async {
    final recipes = await _repo.fetchWeekly(week);
    
    // All filtering/sorting logic here
    recipes.sort((a, b) => b.pickScore.compareTo(a.pickScore));
    
    return recipes;
  }
}
```

---

## 🎨 Widget Guidelines

### DO ✅
- Watch providers
- Render UI
- Handle user input (tap, scroll)
- Navigate
- Show snackbars/dialogs
- Pass data down via constructors

### DON'T ❌
- Filter/sort/transform data
- Make API calls
- Calculate business values
- Contain if/else business rules
- Directly access Supabase
- Mix presentation and logic

---

## 🔄 Gradual Migration Plan

### Phase 1: Foundation (Complete ✅)
- [x] Create domain entities
- [x] Create repository interfaces
- [x] Create core use-cases
- [x] Create DTOs
- [x] Create Supabase repositories
- [x] Wire up Riverpod providers

### Phase 2: Recipe Flow (Next)
- [ ] Update `recipes_selection_screen.dart` to use `weeklyMenuControllerProvider`
- [ ] Update `recipe_grid_card.dart` to use `selectedRecipesControllerProvider`
- [ ] Remove old `recipe_selection_providers.dart` business logic
- [ ] Add tests for `AutoSelectRecipes` use-case

### Phase 3: Delivery Flow
- [ ] Create `DeliveryGateController` using clean providers
- [ ] Update delivery modal to use use-cases
- [ ] Remove inline business logic from widgets

### Phase 4: Box Flow
- [ ] Extract box selection logic to use-cases
- [ ] Create `CalculateBoxPricing` use-case
- [ ] Clean up provider dependencies

### Phase 5: Testing
- [ ] Add domain layer tests (no mocks needed)
- [ ] Add repository tests (with fakes)
- [ ] Add widget tests (with provider overrides)
- [ ] Achieve >80% coverage

---

## 📊 Current vs Target

### Current State
```
Widget → Provider (with business logic) → Supabase
  ↓
Mixed concerns, hard to test, tightly coupled
```

### Target State
```
Widget → Controller → Use Case → Repository → Supabase
  ↓         ↓           ↓           ↓
 Dumb    Riverpod   Business    Data Access
  UI      Glue       Logic       Layer
```

---

## 🎯 Next Actions

1. **Update `recipes_selection_screen.dart`**:
   - Replace `recipesProvider` → `weeklyMenuControllerProvider`
   - Replace `selectedRecipesProvider` → `selectedRecipesControllerProvider`

2. **Update `recipe_grid_card.dart`**:
   - Remove filtering logic
   - Use `selectedRecipesControllerProvider.notifier.toggle(id)`

3. **Create tests**:
   - `test/domain/usecases/auto_select_recipes_test.dart`
   - `test/domain/entities/recipe_test.dart`

4. **Deprecate old files** (after migration):
   - Mark `core/providers/recipe_selection_providers.dart` as legacy
   - Gradually remove business logic

---

**Generated**: 2025-10-13
**Status**: Foundation complete, ready for widget migration





