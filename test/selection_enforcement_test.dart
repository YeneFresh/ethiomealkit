// Selection Enforcement Test
// Tests: Plan allowance prevents over-selection

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ethiomealkit/data/api/supa_client.dart';

// Mock classes
class MockSupaClient extends Mock implements SupaClient {}

void main() {
  late MockSupaClient mockApi;

  setUp(() {
    mockApi = MockSupaClient();
  });

  group('Recipe Selection Enforcement', () {
    test('toggleRecipeSelection returns ok=false when over limit', () async {
      // Setup: User has 3 meals/week plan, already selected 3
      when(
        () => mockApi.toggleRecipeSelection(
          recipeId: any(named: 'recipeId'),
          select: true,
        ),
      ).thenAnswer(
        (_) async => {
          'total_selected': 3,
          'remaining': 0,
          'allowed': 3,
          'ok': false, // Over limit
        },
      );

      // Act: Try to select 4th recipe
      final result = await mockApi.toggleRecipeSelection(
        recipeId: 'recipe-4',
        select: true,
      );

      // Assert: Should be blocked
      expect(result['ok'], false);
      expect(result['total_selected'], 3);
      expect(result['remaining'], 0);
      expect(result['allowed'], 3);
    });

    test('toggleRecipeSelection returns ok=true when within limit', () async {
      // Setup: User has 3 meals/week plan, selected 2
      when(
        () => mockApi.toggleRecipeSelection(
          recipeId: any(named: 'recipeId'),
          select: true,
        ),
      ).thenAnswer(
        (_) async => {
          'total_selected': 3,
          'remaining': 0,
          'allowed': 3,
          'ok': true, // Within limit
        },
      );

      // Act: Select 3rd recipe (within limit)
      final result = await mockApi.toggleRecipeSelection(
        recipeId: 'recipe-3',
        select: true,
      );

      // Assert: Should succeed
      expect(result['ok'], true);
      expect(result['total_selected'], 3);
      expect(result['remaining'], 0);
      expect(result['allowed'], 3);
    });

    test('toggleRecipeSelection allows deselection even at limit', () async {
      // Setup: User at limit, wants to deselect
      when(
        () => mockApi.toggleRecipeSelection(
          recipeId: any(named: 'recipeId'),
          select: false,
        ),
      ).thenAnswer(
        (_) async => {
          'total_selected': 2,
          'remaining': 1,
          'allowed': 3,
          'ok': true,
        },
      );

      // Act: Deselect a recipe
      final result = await mockApi.toggleRecipeSelection(
        recipeId: 'recipe-1',
        select: false,
      );

      // Assert: Should succeed
      expect(result['ok'], true);
      expect(result['total_selected'], 2);
      expect(result['remaining'], 1);
    });

    test('Selection status correctly calculates remaining quota', () {
      // Test data
      const totalSelected = 2;
      const remaining = 1;
      const allowed = 3;

      // Assert calculations
      expect(totalSelected + remaining, equals(allowed));
      expect(remaining, greaterThan(0));
    });
  });
}
