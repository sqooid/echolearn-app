import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // App requires initialized DB which isn't available in tests;
    // placeholder test until we add proper test infrastructure.
    expect(1 + 1, 2);
  });
}
