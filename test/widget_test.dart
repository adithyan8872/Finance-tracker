import 'package:flutter_test/flutter_test.dart';
import 'package:finance/app.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const FinanceTrackerApp());
  });
}
