import 'package:flutter_test/flutter_test.dart';
import 'package:ethiomealkit/bootstrap/env.dart';

void main() {
  test('Env constants exist and can be referenced', () {
    // Access without calling assertRequired (which throws by design if missing)
    expect(Env.appEnv.isNotEmpty, true);
  });
}
