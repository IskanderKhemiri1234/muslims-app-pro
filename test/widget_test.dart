
import 'package:flutter_test/flutter_test.dart';
import 'package:muslims_app/main.dart';

void main() {
  testWidgets('Muslims app opens successfully', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MuslimsApp());

    expect(find.text('Muslims'), findsWidgets);
    expect(find.text('الفجر'), findsOneWidget);
    expect(find.text('الظهر'), findsOneWidget);
    expect(find.text('العصر'), findsOneWidget);
    expect(find.text('المغرب'), findsOneWidget);
    expect(find.text('العشاء'), findsOneWidget);
  });
}
