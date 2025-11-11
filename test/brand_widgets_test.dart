import 'package:ethiomealkit/features/home/home_screen.dart';
import 'package:ethiomealkit/ui/brand/brand_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('HomeScreen shows BrandLogo in AppBar title', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    // BrandTitle uses BrandLogo(monogram) in the AppBar title
    expect(find.byType(BrandLogo), findsWidgets);
  });

  testWidgets('BrandTitle exposes accessible label', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    // The BrandLogo semantics label is "YeneFresh"
    expect(find.bySemanticsLabel('YeneFresh'), findsWidgets);
  });
}
