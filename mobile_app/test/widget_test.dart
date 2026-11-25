import 'package:flutter_test/flutter_test.dart';
import 'package:paddyusdt_app/main.dart';

void main() {
  testWidgets('PaddyusdtApp renders login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const PaddyusdtApp());
    expect(find.text('Paddyusdt'), findsOneWidget);
  });
}
