import 'package:flutter_test/flutter_test.dart';
import 'package:agroconnect/main.dart';

void main() {
  testWidgets('AgroConnect Landing Page smoke test', (
    WidgetTester tester,
  ) async {
    // 1. Build our app and trigger a frame.
    // Note: Since we use Firebase.initializeApp() in main, we pump AgroConnectApp
    await tester.pumpWidget(const AgroConnectApp());

    // 2. Verify that AgroConnect title exists.
    expect(find.text('AgroConnect'), findsOneWidget);

    // 3. Verify that the Get Started button exists.
    expect(find.text('Get Started'), findsOneWidget);
  });
}
