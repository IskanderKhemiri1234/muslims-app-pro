
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:muslims_app/main.dart';
import 'package:muslims_app/core/localization/mumin_language_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'Mumin Pro opens with central Arabic language and dark theme',
    (WidgetTester tester) async {
      final preferences = await SharedPreferences.getInstance();

      final languageController = MuminLanguageController(
        preferences: preferences,
        initialLanguageCode: 'ar',
      );

      final settingsController = SettingsController(
        preferences: preferences,
        isDark: true,
      );

      await tester.pumpWidget(
        MuminApp(
          languageController: languageController,
          settingsController: settingsController,
        ),
      );

      await tester.pump();

      expect(find.byType(MuminApp), findsOneWidget);
      expect(find.byType(MaterialApp), findsOneWidget);

      expect(languageController.languageCode, 'ar');
      expect(languageController.locale, const Locale('ar'));
      expect(
        languageController.textDirection,
        TextDirection.rtl,
      );

      expect(settingsController.isDark, isTrue);
      expect(settingsController.themeMode, ThemeMode.dark);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );
}
