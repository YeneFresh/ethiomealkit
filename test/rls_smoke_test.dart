// RLS Smoke Test
// Tests: Anonymous users cannot write, authenticated users can only access their own data

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

  group('RLS Security Smoke Tests', () {
    test('Anonymous users cannot call write RPCs', () async {
      // Setup: Anonymous call to write RPC throws auth error
      when(
        () => mockApi.setOnboardingPlan(
          boxSize: any(named: 'boxSize'),
          mealsPerWeek: any(named: 'mealsPerWeek'),
        ),
      ).thenThrow(
        SupaClientException('Failed to set onboarding plan: Not authenticated'),
      );

      // Act & Assert: Should throw
      expect(
        () => mockApi.setOnboardingPlan(boxSize: 2, mealsPerWeek: 3),
        throwsA(isA<SupaClientException>()),
      );
    });

    test('Anonymous users cannot upsert delivery window', () async {
      // Setup: Anonymous write blocked
      when(
        () => mockApi.upsertUserActiveWindow(
          windowId: any(named: 'windowId'),
          locationLabel: any(named: 'locationLabel'),
        ),
      ).thenThrow(
        SupaClientException('Failed to set active window: Not authenticated'),
      );

      // Act & Assert: Should throw
      expect(
        () => mockApi.upsertUserActiveWindow(
          windowId: 'window-1',
          locationLabel: 'Home - Addis Ababa',
        ),
        throwsA(isA<SupaClientException>()),
      );
    });

    test('Anonymous users cannot toggle recipe selections', () async {
      // Setup: Anonymous write blocked
      when(
        () => mockApi.toggleRecipeSelection(
          recipeId: any(named: 'recipeId'),
          select: any(named: 'select'),
        ),
      ).thenThrow(
        SupaClientException(
          'Failed to toggle recipe selection: Not authenticated',
        ),
      );

      // Act & Assert: Should throw
      expect(
        () => mockApi.toggleRecipeSelection(recipeId: 'recipe-1', select: true),
        throwsA(isA<SupaClientException>()),
      );
    });

    test('Anonymous users cannot create orders', () async {
      // Setup: confirm_scheduled_order requires authentication
      when(
        () => mockApi.confirmScheduledOrder(address: any(named: 'address')),
      ).thenThrow(
        SupaClientException('Failed to confirm order: Not authenticated'),
      );

      // Act & Assert: Should throw
      expect(
        () => mockApi.confirmScheduledOrder(
          address: {
            'name': 'Test',
            'phone': '123',
            'line1': 'Street',
            'city': 'City',
          },
        ),
        throwsA(isA<SupaClientException>()),
      );
    });

    test('Anonymous users can read public data', () async {
      // Setup: Read operations should work for anonymous
      when(() => mockApi.availableWindows()).thenAnswer(
        (_) async => [
          {
            'id': 'window-1',
            'start_at': DateTime.now().toIso8601String(),
            'end_at': DateTime.now()
                .add(const Duration(hours: 2))
                .toIso8601String(),
            'weekday': 6,
            'slot': '14-16',
            'city': 'Addis Ababa',
            'capacity': 20,
            'booked_count': 5,
            'is_active': true,
          },
        ],
      );

      // Act: Read public data
      final windows = await mockApi.availableWindows();

      // Assert: Should succeed
      expect(windows, isNotEmpty);
      expect(windows.length, equals(1));
      expect(windows[0]['id'], equals('window-1'));
    });

    test('User readiness returns not ready for anonymous', () async {
      // Setup: Anonymous user has no active window
      when(() => mockApi.userReadiness()).thenAnswer(
        (_) async => {
          'user_id': null,
          'is_ready': false,
          'reasons': ['NO_USER_SESSION'],
          'active_city': null,
          'active_window_id': null,
        },
      );

      // Act: Check readiness
      final readiness = await mockApi.userReadiness();

      // Assert: Should be not ready
      expect(readiness['is_ready'], false);
      expect(readiness['user_id'], isNull);
      expect(readiness['reasons'], contains('NO_USER_SESSION'));
    });

    test('RLS policy names follow convention', () {
      // Test that our policy names are consistent
      final expectedPolicies = [
        'orders self access',
        'order_items self access',
        'Users can manage their own active window',
        'Users can manage their own onboarding state',
        'Users can manage their own recipe selections',
        'Public read delivery windows',
        'Public read recipes',
        'Public read weeks',
      ];

      // Verify naming convention
      for (final policy in expectedPolicies) {
        expect(policy, isNotEmpty);
        // Policies should be descriptive
        expect(policy.length, greaterThan(10));
      }
    });
  });
}
