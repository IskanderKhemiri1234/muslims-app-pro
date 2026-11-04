import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:muslims_app/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'Muslims app opens successfully',
    (WidgetTester tester) async {
      final preferences = await SharedPreferences.getInstance();

      final settingsController = SettingsController(
        preferences: preferences,
        languageCode: 'ar',
        isDark: true,
      );

      await tester.pumpWidget(
        MuslimsApp(
          settingsController: settingsController,
        ),
      );

      await tester.pump();

      expect(find.byType(MuslimsApp), findsOneWidget);

      expect(find.byType(MaterialApp), findsOneWidget);

      expect(settingsController.languageCode, 'ar');
      expect(settingsController.isDark, isTrue);

      await tester.pumpWidget(const SizedBox.shrink());

      await tester.pump();

    },
  );
}
