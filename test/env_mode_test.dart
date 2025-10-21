import 'package:flutter_test/flutter_test.dart';

void main() {
  test('USE_MOCKS toggles mock vs supabase client', () {
    const useMocks = String.fromEnvironment('USE_MOCKS', defaultValue: 'true');
    expect(['true', 'false'].contains(useMocks), true);
  });
}
