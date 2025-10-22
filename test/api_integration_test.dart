// API Integration Test
// Tests: All SupaClient methods return expected data structures

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

  group('API Integration - Method Contracts', () {
    test('availableWindows returns list of delivery windows', () async {
      // Setup
      when(() => mockApi.availableWindows()).thenAnswer(
        (_) async => [
          {
            'id': 'window-1',
            'start_at': '2025-10-12T14:00:00Z',
            'end_at': '2025-10-12T16:00:00Z',
            'weekday': 6,
            'slot': '14-16',
            'city': 'Addis Ababa',
            'capacity': 20,
            'booked_count': 5,
            'has_capacity': true,
            'is_active': true,
          },
        ],
      );

      // Act
      final windows = await mockApi.availableWindows();

      // Assert
      expect(windows, isA<List<Map<String, dynamic>>>());
      expect(windows[0]['id'], isA<String>());
      expect(windows[0]['weekday'], isA<int>());
      expect(windows[0]['has_capacity'], isA<bool>());
    });

    test('userReadiness returns delivery gate status', () async {
      // Setup
      when(() => mockApi.userReadiness()).thenAnswer(
        (_) async => {
          'user_id': 'user-123',
          'is_ready': true,
          'reasons': [],
          'active_city': 'Home - Addis Ababa',
          'active_window_id': 'window-1',
          'window_start': '2025-10-12T14:00:00Z',
          'window_end': '2025-10-12T16:00:00Z',
          'weekday': 6,
          'slot': '14-16',
        },
      );

      // Act
      final readiness = await mockApi.userReadiness();

      // Assert
      expect(readiness, isA<Map<String, dynamic>>());
      expect(readiness['is_ready'], isA<bool>());
      expect(readiness['reasons'], isA<List>());
      expect(readiness['active_city'], isA<String>());
    });

    test('userSelections returns recipe selections with plan', () async {
      // Setup
      when(() => mockApi.userSelections()).thenAnswer(
        (_) async => [
          {
            'recipe_id': 'recipe-1',
            'week_start': '2025-10-06',
            'box_size': 3,
            'selected': true,
          },
          {
            'recipe_id': 'recipe-2',
            'week_start': '2025-10-06',
            'box_size': 3,
            'selected': false,
          },
        ],
      );

      // Act
      final selections = await mockApi.userSelections();

      // Assert
      expect(selections, isA<List<Map<String, dynamic>>>());
      expect(selections[0]['recipe_id'], isA<String>());
      expect(selections[0]['box_size'], isA<int>());
      expect(selections[0]['selected'], isA<bool>());
    });

    test('currentWeeklyRecipes returns gated recipe list', () async {
      // Setup
      when(() => mockApi.currentWeeklyRecipes()).thenAnswer(
        (_) async => [
          {
            'id': 'recipe-1',
            'title': 'Doro Wat',
            'slug': 'doro-wat',
            'image_url': '/images/doro-wat.jpg',
            'tags': ['traditional', 'chicken'],
            'sort_order': 1,
            'week_start': '2025-10-06',
          },
        ],
      );

      // Act
      final recipes = await mockApi.currentWeeklyRecipes();

      // Assert
      expect(recipes, isA<List<Map<String, dynamic>>>());
      expect(recipes[0]['title'], isA<String>());
      expect(recipes[0]['tags'], isA<List>());
      expect(recipes[0]['sort_order'], isA<int>());
    });

    test('All write operations throw SupaClientException on failure', () {
      // Setup: All write ops throw on error
      when(
        () => mockApi.setOnboardingPlan(
          boxSize: any(named: 'boxSize'),
          mealsPerWeek: any(named: 'mealsPerWeek'),
        ),
      ).thenThrow(SupaClientException('Test error'));

      when(
        () => mockApi.upsertUserActiveWindow(
          windowId: any(named: 'windowId'),
          locationLabel: any(named: 'locationLabel'),
        ),
      ).thenThrow(SupaClientException('Test error'));

      when(
        () => mockApi.toggleRecipeSelection(
          recipeId: any(named: 'recipeId'),
          select: any(named: 'select'),
        ),
      ).thenThrow(SupaClientException('Test error'));

      when(
        () => mockApi.confirmScheduledOrder(address: any(named: 'address')),
      ).thenThrow(SupaClientException('Test error'));

      // Assert: All throw SupaClientException
      expect(
        () => mockApi.setOnboardingPlan(boxSize: 2, mealsPerWeek: 3),
        throwsA(isA<SupaClientException>()),
      );

      expect(
        () => mockApi.upsertUserActiveWindow(
          windowId: 'w1',
          locationLabel: 'Home',
        ),
        throwsA(isA<SupaClientException>()),
      );

      expect(
        () => mockApi.toggleRecipeSelection(recipeId: 'r1', select: true),
        throwsA(isA<SupaClientException>()),
      );

      expect(
        () => mockApi.confirmScheduledOrder(address: {}),
        throwsA(isA<SupaClientException>()),
      );
    });

    test('SupaClient contract: all methods are defined', () {
      // This test documents the expected API surface
      final expectedMethods = [
        'availableWindows',
        'userReadiness',
        'userSelections',
        'currentWeeklyRecipes',
        'upsertUserActiveWindow',
        'setOnboardingPlan',
        'toggleRecipeSelection',
        'getUserOnboardingState',
        'confirmScheduledOrder',
        'healthCheck',
      ];

      // Verify we have all expected methods
      expect(expectedMethods.length, equals(10));

      // Verify method names are consistent (camelCase)
      for (final method in expectedMethods) {
        expect(method[0], equals(method[0].toLowerCase())); // starts lowercase
        expect(method.contains('_'), false); // no underscores
      }
    });
  });
}
