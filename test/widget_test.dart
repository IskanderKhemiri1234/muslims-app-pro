
import 'package:flutter_test/flutter_test.dart';
import 'package:muslims_app/main.dart';

void main() {
  testWidgets('Muslims app opens successfully', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MuslimsApp());

    expect(find.byType(MuslimsApp), findsOneWidget);
  });
}
