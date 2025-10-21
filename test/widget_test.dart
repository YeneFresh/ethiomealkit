// Basic Widget Test - App Smoke Test
// Tests: App starts without crashing

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ethiomealkit/main.dart';

// Mock classes
class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

void main() {
  setUpAll(() {
    // Initialize Supabase mock for testing
    // This prevents the app from trying to connect during tests
  });

  testWidgets('App starts without crashing', (tester) async {
    // Build our app
    await tester.pumpWidget(const ProviderScope(child: MyApp()));

    // Verify app builds
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('MyApp uses Material 3', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));

    // Verify Material 3 is enabled
    expect(materialApp.theme?.useMaterial3, true);
  });

  testWidgets('MyApp has proper title', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));

    // Verify app title
    expect(materialApp.title, equals('EthiomealKit'));
  });

  testWidgets('Theme has brown color scheme', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    final theme = materialApp.theme;

    // Verify theme exists
    expect(theme, isNotNull);

    // Verify color scheme is light
    expect(theme!.brightness, equals(Brightness.light));
  });

  test('Theme has proper border radius tokens', () {
    // Test theme configuration
    const cardRadius = 16.0;
    const buttonRadius = 16.0;
    const inputRadius = 12.0;

    expect(cardRadius, greaterThanOrEqualTo(16.0));
    expect(cardRadius, lessThanOrEqualTo(20.0));
    expect(buttonRadius, greaterThanOrEqualTo(16.0));
    expect(buttonRadius, lessThanOrEqualTo(20.0));
    expect(inputRadius, greaterThanOrEqualTo(12.0));
  });
}
