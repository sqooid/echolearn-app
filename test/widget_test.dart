import 'package:flutter_test/flutter_test.dart';
import 'package:lang_app/app.dart';

void main() {
  testWidgets('Lingo app renders', (WidgetTester tester) async {
    await tester.pumpWidget(const LingoApp());
    expect(find.text('9:41'), findsOneWidget);
  });
}
