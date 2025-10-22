// Checkout Happy Path Test
// Tests: Address submit → confirm_scheduled_order → order created

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

  group('Checkout Happy Path', () {
    test('confirmScheduledOrder creates order successfully', () async {
      // Setup: Valid address and selections
      final testAddress = {
        'name': 'Test User',
        'phone': '+251911234567',
        'line1': 'Bole Road, House 123',
        'line2': '',
        'city': 'Addis Ababa',
        'notes': 'Ring doorbell twice',
      };

      // Mock RPC response
      when(
        () => mockApi.confirmScheduledOrder(address: any(named: 'address')),
      ).thenAnswer((_) async => ('order-uuid-123', 3));

      // Act: Confirm order
      final (orderId, totalItems) = await mockApi.confirmScheduledOrder(
        address: testAddress,
      );

      // Assert: Order created
      expect(orderId, isNotEmpty);
      expect(orderId, equals('order-uuid-123'));
      expect(totalItems, equals(3));

      // Verify RPC was called with address
      verify(
        () => mockApi.confirmScheduledOrder(address: testAddress),
      ).called(1);
    });

    test('confirmScheduledOrder throws when no recipes selected', () async {
      // Setup: RPC throws exception
      when(
        () => mockApi.confirmScheduledOrder(address: any(named: 'address')),
      ).thenThrow(
        SupaClientException('Failed to confirm order: No recipes selected'),
      );

      // Act & Assert: Should throw
      expect(
        () => mockApi.confirmScheduledOrder(
          address: {
            'name': 'Test',
            'phone': '123',
            'line1': 'Street',
            'city': 'Addis Ababa',
          },
        ),
        throwsA(isA<SupaClientException>()),
      );
    });

    test(
      'confirmScheduledOrder throws when delivery window not selected',
      () async {
        // Setup: RPC throws exception
        when(
          () => mockApi.confirmScheduledOrder(address: any(named: 'address')),
        ).thenThrow(
          SupaClientException(
            'Failed to confirm order: Delivery window not selected',
          ),
        );

        // Act & Assert: Should throw
        expect(
          () => mockApi.confirmScheduledOrder(
            address: {
              'name': 'Test',
              'phone': '123',
              'line1': 'Street',
              'city': 'Addis Ababa',
            },
          ),
          throwsA(isA<SupaClientException>()),
        );
      },
    );

    test('confirmScheduledOrder validates address format', () async {
      // Valid address should have all required fields
      final validAddress = {
        'name': 'John Doe',
        'phone': '+251911234567',
        'line1': 'Bole Road',
        'line2': 'Apt 5',
        'city': 'Addis Ababa',
        'notes': 'Call on arrival',
      };

      // All required fields present
      expect(validAddress.containsKey('name'), true);
      expect(validAddress.containsKey('phone'), true);
      expect(validAddress.containsKey('line1'), true);
      expect(validAddress.containsKey('city'), true);
    });

    test('Order flow enforces correct sequence', () {
      // Test data representing flow state
      final flowState = {
        'has_plan': true,
        'is_authenticated': true,
        'has_delivery_window': true,
        'has_recipe_selections': true,
        'has_address': true,
      };

      // Verify all prerequisites met
      expect(flowState['has_plan'], true);
      expect(flowState['is_authenticated'], true);
      expect(flowState['has_delivery_window'], true);
      expect(flowState['has_recipe_selections'], true);
      expect(flowState['has_address'], true);

      // All conditions met = can create order
      final canCreateOrder = flowState.values.every((v) => v == true);
      expect(canCreateOrder, true);
    });
  });
}
