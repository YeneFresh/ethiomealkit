// This is a basic Flutter widget test for EthioMealKit.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ethiomealkit/main.dart';

void main() {
  testWidgets('EthioMealKit app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: MyApp()));

    // Verify that our app shows the authentication screen initially
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Welcome to EthioMealKit'), findsOneWidget);
    expect(find.text('Sign in with your email to continue'), findsOneWidget);

    // Verify that the email input field is present
    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.text('Send OTP Link'), findsOneWidget);
  });
}
