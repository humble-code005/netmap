import 'package:flutter_test/flutter_test.dart';
import 'package:wifi_scanner/main.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const WifiScannerApp());
    // Verify the app renders without crashing
    expect(find.byType(WifiScannerApp), findsOneWidget);
  });
}
