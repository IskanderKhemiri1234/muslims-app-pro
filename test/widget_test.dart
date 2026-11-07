
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:muslims_app/main.dart';
import 'package:muslims_app/core/localization/mumin_language_controller.dart';

const MethodChannel _notificationsChannel = MethodChannel(
  'dexterous.com/flutter/local_notifications',
);

const MethodChannel _countdownChannel = MethodChannel(
  'com.iskander.muslimspro/prayer_countdown',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    AndroidFlutterLocalNotificationsPlugin.registerWith();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});

    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    messenger.setMockMethodCallHandler(
      _notificationsChannel,
      (MethodCall call) async {
        switch (call.method) {
          case 'initialize':
            return true;

          case 'areNotificationsEnabled':
            return true;

          case 'requestNotificationsPermission':
            return true;

          case 'canScheduleExactNotifications':
            return true;

          case 'createNotificationChannel':
            return true;

          case 'pendingNotificationRequests':
          case 'getActiveNotifications':
          case 'getNotificationChannels':
            return <Map<String, Object?>>[];

          case 'getNotificationAppLaunchDetails':
            return null;

          default:
            return null;
        }
      },
    );

    messenger.setMockMethodCallHandler(
      _countdownChannel,
      (MethodCall call) async {
        switch (call.method) {
          case 'syncPrayerCountdown':
          case 'cancelPrayerCountdown':
            return null;

          default:
            return null;
        }
      },
    );
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;

    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    messenger.setMockMethodCallHandler(
      _notificationsChannel,
      null,
    );

    messenger.setMockMethodCallHandler(
      _countdownChannel,
      null,
    );
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
