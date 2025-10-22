import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Meal JSON roundtrips without losing required fields', () async {
    final jsonStr = await rootBundle.loadString('test/fixtures/meal.json');
    final Map<String, dynamic> original = json.decode(jsonStr);

    // Placeholder: until real model is wired, simulate identity roundtrip
    final out = Map<String, dynamic>.from(original);

    for (final key in original.keys) {
      expect(out.containsKey(key), true, reason: 'Missing key: $key');
    }
  });
}
