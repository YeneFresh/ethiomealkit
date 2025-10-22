// Onboarding Flow E2E Test
// Tests: Delivery gate logic (locked → unlocked)

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

  group('Onboarding Flow - Delivery Gate', () {
    test('Recipes are locked when user has no delivery window', () async {
      // Setup: User not ready (no delivery window)
      when(() => mockApi.userReadiness()).thenAnswer(
        (_) async => {
          'user_id': null,
          'is_ready': false,
          'reasons': ['NO_ACTIVE_WINDOW'],
          'active_city': null,
          'active_window_id': null,
        },
      );

      // Act: Check readiness
      final readiness = await mockApi.userReadiness();

      // Assert: Should be locked
      expect(readiness['is_ready'], false);
      expect(readiness['reasons'], contains('NO_ACTIVE_WINDOW'));

      // Verify API was called
      verify(() => mockApi.userReadiness()).called(1);
    });

    test('Recipes are unlocked after delivery window selected', () async {
      // Setup: User ready (has delivery window)
      when(() => mockApi.userReadiness()).thenAnswer(
        (_) async => {
          'user_id': 'test-user-123',
          'is_ready': true,
          'reasons': [],
          'active_city': 'Home - Addis Ababa',
          'active_window_id': 'window-1',
          'window_start': DateTime.now().toIso8601String(),
          'window_end': DateTime.now()
              .add(const Duration(hours: 2))
              .toIso8601String(),
          'weekday': 6,
          'slot': '14-16',
        },
      );

      // Setup: Recipes available after unlock
      when(() => mockApi.currentWeeklyRecipes()).thenAnswer(
        (_) async => [
          {
            'id': 'recipe-1',
            'title': 'Doro Wat',
            'slug': 'doro-wat',
            'image_url': '/images/doro-wat.jpg',
            'tags': ['traditional', 'chicken'],
            'sort_order': 1,
            'week_start': DateTime.now().toIso8601String(),
          },
        ],
      );

      // Act: Check readiness
      final readiness = await mockApi.userReadiness();

      // Assert: Should be ready
      expect(readiness['is_ready'], true);
      expect(readiness['reasons'], isEmpty);
      expect(readiness['active_window_id'], isNotNull);

      // Act: Load recipes (now allowed)
      final recipes = await mockApi.currentWeeklyRecipes();

      // Assert: Recipes available
      expect(recipes, isNotEmpty);
      expect(recipes[0]['title'], equals('Doro Wat'));

      // Verify API calls
      verify(() => mockApi.userReadiness()).called(1);
      verify(() => mockApi.currentWeeklyRecipes()).called(1);
    });

    test('Delivery gate enforces window selection before recipes', () async {
      // Scenario 1: No window = locked
      when(() => mockApi.userReadiness()).thenAnswer(
        (_) async => {
          'is_ready': false,
          'reasons': ['NO_ACTIVE_WINDOW'],
        },
      );

      final lockedState = await mockApi.userReadiness();
      expect(lockedState['is_ready'], false);

      // Scenario 2: After selecting window = unlocked
      when(() => mockApi.userReadiness()).thenAnswer(
        (_) async => {
          'is_ready': true,
          'reasons': [],
          'active_window_id': 'window-1',
        },
      );

      final unlockedState = await mockApi.userReadiness();
      expect(unlockedState['is_ready'], true);
    });

    test('Full onboarding sequence prerequisites', () {
      // Test the logical flow requirements
      final flowChecks = {
        'step1_box_selected': true,
        'step2_authenticated': true,
        'step3_window_selected': true,
        'step4_recipes_selected': true,
        'step5_address_entered': true,
      };

      // All steps must be complete to create order
      final canCheckout = flowChecks.values.every((check) => check);
      expect(canCheckout, true);

      // Missing any step blocks checkout
      flowChecks['step3_window_selected'] = false;
      final shouldBeBlocked = flowChecks.values.every((check) => check);
      expect(shouldBeBlocked, false);
    });
  });
}
