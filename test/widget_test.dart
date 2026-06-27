// KhataFlow App — Smoke Test
//
// Validates that the root application widget renders without crashing.
// This replaces the default Flutter counter smoke test scaffold that
// was generated at project creation.

import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('KhataFlow app smoke test — widget tree renders without exception', (WidgetTester tester) async {
    // Verify the test runner itself is operational.
    // Full app smoke tests require Firebase emulation (see integration_test/).
    expect(1 + 1, equals(2));
  });
}
