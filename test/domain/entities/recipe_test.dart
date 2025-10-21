import 'package:flutter_test/flutter_test.dart';
import 'package:ethiomealkit/domain/entities/recipe.dart';

void main() {
  group('Recipe Entity', () {
    test('calculates total minutes correctly', () {
      final recipe = Recipe(
        id: '1',
        title: 'Test Recipe',
        description: '',
        prepMinutes: 15,
        cookMinutes: 25,
        calories: 400,
        tags: [],
      );

      expect(recipe.totalMinutes, 40);
    });

    test('identifies quick recipes correctly', () {
      final quick = Recipe(
        id: '1',
        title: 'Quick Meal',
        description: '',
        prepMinutes: 10,
        cookMinutes: 15,
        calories: 300,
        tags: [],
      );

      final slow = Recipe(
        id: '2',
        title: 'Slow Cook',
        description: '',
        prepMinutes: 20,
        cookMinutes: 40,
        calories: 500,
        tags: [],
      );

      expect(quick.isQuick, true);
      expect(slow.isQuick, false);
    });

    test('identifies Chef\'s Choice correctly', () {
      final chefChoice = Recipe(
        id: '1',
        title: 'Special',
        description: '',
        prepMinutes: 10,
        cookMinutes: 20,
        calories: 400,
        tags: ['Chef\'s Choice', 'Premium'],
      );

      final regular = Recipe(
        id: '2',
        title: 'Regular',
        description: '',
        prepMinutes: 10,
        cookMinutes: 20,
        calories: 400,
        tags: ['Popular'],
      );

      expect(chefChoice.isChefChoice, true);
      expect(regular.isChefChoice, false);
    });

    test('calculates pick score with correct priorities', () {
      final chefChoice = Recipe(
        id: '1',
        title: 'Chef Special',
        description: '',
        prepMinutes: 10,
        cookMinutes: 30,
        calories: 500,
        tags: ['Chef\'s Choice'],
      );

      final popular = Recipe(
        id: '2',
        title: 'Popular Dish',
        description: '',
        prepMinutes: 10,
        cookMinutes: 30,
        calories: 500,
        tags: ['Popular'],
      );

      final quick = Recipe(
        id: '3',
        title: 'Quick Meal',
        description: '',
        prepMinutes: 5,
        cookMinutes: 15,
        calories: 300,
        tags: ['Express'],
      );

      // Chef's Choice should have highest score
      expect(chefChoice.pickScore > popular.pickScore, true);
      expect(chefChoice.pickScore > quick.pickScore, true);
    });

    test('copyWith creates new instance with updated values', () {
      final original = Recipe(
        id: '1',
        title: 'Original',
        description: 'Desc',
        prepMinutes: 10,
        cookMinutes: 20,
        calories: 400,
        tags: ['Tag1'],
      );

      final updated = original.copyWith(title: 'Updated');

      expect(updated.title, 'Updated');
      expect(updated.id, '1'); // Unchanged
      expect(updated, isNot(same(original))); // New instance
    });

    test('equality based on ID only', () {
      final recipe1 = Recipe(
        id: '1',
        title: 'Title 1',
        description: '',
        prepMinutes: 10,
        cookMinutes: 20,
        calories: 400,
        tags: [],
      );

      final recipe2 = Recipe(
        id: '1',
        title: 'Title 2', // Different title
        description: '',
        prepMinutes: 15,
        cookMinutes: 25,
        calories: 500,
        tags: [],
      );

      expect(recipe1, recipe2); // Same ID = equal
      expect(recipe1.hashCode, recipe2.hashCode);
    });
  });
}



