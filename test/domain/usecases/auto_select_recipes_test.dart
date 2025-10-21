import 'package:flutter_test/flutter_test.dart';
import 'package:ethiomealkit/domain/entities/recipe.dart';
import 'package:ethiomealkit/domain/usecases/auto_select_recipes.dart';

void main() {
  group('AutoSelectRecipes', () {
    late AutoSelectRecipes useCase;

    setUp(() {
      useCase = AutoSelectRecipes();
    });

    test('prioritizes Chef\'s Choice over Popular', () {
      final recipes = [
        Recipe(
          id: '1',
          title: 'Popular Dish',
          description: '',
          prepMinutes: 10,
          cookMinutes: 20,
          calories: 400,
          tags: ['Popular'],
        ),
        Recipe(
          id: '2',
          title: 'Chef\'s Special',
          description: '',
          prepMinutes: 15,
          cookMinutes: 30,
          calories: 500,
          tags: ['Chef\'s Choice'],
        ),
      ];

      final selected = useCase(availableRecipes: recipes, count: 1);

      expect(selected.length, 1);
      expect(selected.first, '2'); // Chef's Choice wins
    });

    test('prefers quick recipes when priority is equal', () {
      final recipes = [
        Recipe(
          id: '1',
          title: 'Slow Cook',
          description: '',
          prepMinutes: 10,
          cookMinutes: 40,
          calories: 400,
          tags: ['Popular'],
        ),
        Recipe(
          id: '2',
          title: 'Quick Meal',
          description: '',
          prepMinutes: 5,
          cookMinutes: 15,
          calories: 350,
          tags: ['Popular', 'Express'],
        ),
      ];

      final selected = useCase(availableRecipes: recipes, count: 1);

      expect(selected.first, '2'); // Quicker recipe wins
    });

    test('respects count limit', () {
      final recipes = List.generate(
        10,
        (i) => Recipe(
          id: '$i',
          title: 'Recipe $i',
          description: '',
          prepMinutes: 10,
          cookMinutes: 20,
          calories: 400,
          tags: [],
        ),
      );

      final selected = useCase(availableRecipes: recipes, count: 3);

      expect(selected.length, 3);
    });

    test('excludes already selected recipes', () {
      final recipes = [
        Recipe(
          id: '1',
          title: 'Recipe 1',
          description: '',
          prepMinutes: 10,
          cookMinutes: 20,
          calories: 400,
          tags: ['Chef\'s Choice'],
        ),
        Recipe(
          id: '2',
          title: 'Recipe 2',
          description: '',
          prepMinutes: 10,
          cookMinutes: 20,
          calories: 400,
          tags: ['Popular'],
        ),
      ];

      final selected = useCase(
        availableRecipes: recipes,
        count: 1,
        excludeIds: {'1'}, // Already selected
      );

      expect(selected.first, '2'); // Skips excluded recipe
    });

    test('calculates auto-pick count based on quota', () {
      expect(useCase.calculateAutoPickCount(3), 3); // Small box: pick all
      expect(useCase.calculateAutoPickCount(4), 3); // Leave 1 for user
      expect(useCase.calculateAutoPickCount(5), 3); // 60% of 5
    });
  });
}



