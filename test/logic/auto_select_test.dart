import 'package:flutter_test/flutter_test.dart';
import 'package:ethiomealkit/features/recipes/auto_select.dart';

void main() {
  group('Auto-Select Logic', () {
    final testRecipes = [
      {
        'id': 'r1',
        'title': 'Doro Wat',
        'tags': ["chef's choice", 'spicy', 'chicken'],
      },
      {
        'id': 'r2',
        'title': 'Kitfo',
        'tags': ['beef', 'traditional'],
      },
      {
        'id': 'r3',
        'title': 'Shiro',
        'tags': ['healthy', 'veggie', 'light'],
      },
      {
        'id': 'r4',
        'title': 'Tibs',
        'tags': ['beef', 'spicy'],
      },
      {
        'id': 'r5',
        'title': 'Injera',
        'tags': ['healthy', 'veg'],
      },
    ];

    test('Box=2 with 0 selected → plans 1 (chef first)', () {
      final request = AutoSelectRequest(
        recipes: testRecipes,
        alreadySelectedIds: {},
        allowance: 2,
        targetAuto: 1,
        userId: 'user123',
        weekStart: DateTime(2025, 10, 13),
      );

      final choice = planAutoSelection(request);

      expect(choice.count, 1);
      expect(choice.toSelect, contains('r1')); // Doro Wat has chef's choice
    });

    test('Box=4 with 0 selected → plans 3', () {
      final request = AutoSelectRequest(
        recipes: testRecipes,
        alreadySelectedIds: {},
        allowance: 4,
        targetAuto: 3,
        userId: 'user123',
        weekStart: DateTime(2025, 10, 13),
      );

      final choice = planAutoSelection(request);

      expect(choice.count, 3);
      expect(choice.toSelect, contains('r1')); // Chef's choice first
    });

    test('Box=4 with 1 selected → plans fewer based on allowance', () {
      final request = AutoSelectRequest(
        recipes: testRecipes,
        alreadySelectedIds: {'r1'},
        allowance: 4,
        targetAuto: 3,
        userId: 'user123',
        weekStart: DateTime(2025, 10, 13),
      );

      final choice = planAutoSelection(request);

      expect(choice.count, lessThanOrEqualTo(3));
      expect(choice.toSelect, isNot(contains('r1'))); // Already selected
    });

    test('Variety: avoids picking 3 beef in a row when alternatives exist', () {
      final beefHeavyRecipes = [
        {
          'id': 'r1',
          'title': 'Tibs 1',
          'tags': ['beef', 'spicy'],
        },
        {
          'id': 'r2',
          'title': 'Tibs 2',
          'tags': ['beef', 'traditional'],
        },
        {
          'id': 'r3',
          'title': 'Tibs 3',
          'tags': ['beef', 'quick'],
        },
        {
          'id': 'r4',
          'title': 'Shiro',
          'tags': ['healthy', 'veggie'],
        },
        {
          'id': 'r5',
          'title': 'Fish Goulash',
          'tags': ['fish', 'healthy'],
        },
      ];

      final request = AutoSelectRequest(
        recipes: beefHeavyRecipes,
        alreadySelectedIds: {},
        allowance: 4,
        targetAuto: 3,
        userId: 'user123',
        weekStart: DateTime(2025, 10, 13),
      );

      final choice = planAutoSelection(request);

      // Should include variety, not all beef
      final selected = beefHeavyRecipes
          .where((r) => choice.toSelect.contains(r['id']))
          .toList();
      final beefCount = selected
          .where((r) => (r['tags'] as List).contains('beef'))
          .length;

      expect(beefCount, lessThan(3)); // Not all 3 should be beef
    });

    test('Idempotency: same inputs → same choices', () {
      final request = AutoSelectRequest(
        recipes: testRecipes,
        alreadySelectedIds: {},
        allowance: 4,
        targetAuto: 3,
        userId: 'user123',
        weekStart: DateTime(2025, 10, 13),
      );

      final choice1 = planAutoSelection(request);
      final choice2 = planAutoSelection(request);

      expect(choice1.toSelect, equals(choice2.toSelect));
    });

    test('Respects allowance limit', () {
      final request = AutoSelectRequest(
        recipes: testRecipes,
        alreadySelectedIds: {'r1', 'r2'}, // 2 already selected
        allowance: 3, // Only 3 total allowed
        targetAuto: 3, // Wants to auto-select 3
        userId: 'user123',
        weekStart: DateTime(2025, 10, 13),
      );

      final choice = planAutoSelection(request);

      // Can only select 1 more (3 - 2 = 1)
      expect(choice.count, lessThanOrEqualTo(1));
    });

    test('Returns empty if quota already met', () {
      final request = AutoSelectRequest(
        recipes: testRecipes,
        alreadySelectedIds: {'r1', 'r2', 'r3', 'r4'}, // 4 selected
        allowance: 4, // Quota met
        targetAuto: 3,
        userId: 'user123',
        weekStart: DateTime(2025, 10, 13),
      );

      final choice = planAutoSelection(request);

      expect(choice.isEmpty, true);
    });

    test('calculateTargetAuto returns correct values', () {
      expect(calculateTargetAuto(2), 1); // Box 2 → 1
      expect(calculateTargetAuto(3), 1); // Box 3 → 1
      expect(calculateTargetAuto(4), 3); // Box 4 → 3
      expect(calculateTargetAuto(5), 3); // Box 5 → 3
    });
  });
}
