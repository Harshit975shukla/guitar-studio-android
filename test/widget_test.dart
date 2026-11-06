import 'package:flutter_test/flutter_test.dart';
import 'package:guitar_studio/main.dart';

void main() {
  testWidgets('GuitarStudioApp boots smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const GuitarStudioApp());
    expect(find.text('LIVE STUDIO'), findsOneWidget);
  });
}
