import 'package:flutter_test/flutter_test.dart';
import 'package:physiqo/main.dart';

void main() {
  testWidgets('Physiqo App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const PhysiqoApp());

    // Verify that the logo text "Physiqo" is present on the Home screen.
    expect(find.text('Physiqo'), findsOneWidget);
  });
}
