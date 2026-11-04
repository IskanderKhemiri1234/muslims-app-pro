import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/prayer_times/presentation/controllers/prayer_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final settingsController = await _initializeSettings();

  runApp(
    MuslimsApp(
      settingsController: settingsController,
    ),
  );
}

Future<SettingsController> _initializeSettings() async {
  SharedPreferences? preferences;

  try {
    preferences = await SharedPreferences.getInstance();
  } catch (error, stackTrace) {
    debugPrint('Settings initialization failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }

  final savedLanguageCode =
      preferences?.getString('app_language_code');

  final legacyArabicSetting =
      preferences?.getBool('app_language_ar');

  final String initialLanguage;

  if (savedLanguageCode == 'ar' ||
      savedLanguageCode == 'en' ||
      savedLanguageCode == 'fr') {
    initialLanguage = savedLanguageCode;
  } else if (legacyArabicSetting != null) {
    initialLanguage = legacyArabicSetting ? 'ar' : 'en';
  } else {
    initialLanguage = 'ar';
  }

  final initialDarkMode =
      preferences?.getBool('app_theme_dark') ?? true;

  return SettingsController(
    preferences: preferences,
    languageCode: initialLanguage,
    isDark: initialDarkMode,
  );
}

class SettingsController extends ChangeNotifier {
  SettingsController({
    required SharedPreferences? preferences,
    required String languageCode,
    required bool isDark,
  })  : _preferences = preferences,
        _languageCode = _normalizeLanguage(languageCode),
        _isDark = isDark;

  static const String _languageCodeKey = 'app_language_code';
  static const String _legacyArabicKey = 'app_language_ar';
  static const String _darkModeKey = 'app_theme_dark';

  final SharedPreferences? _preferences;

  String _languageCode;
  bool _isDark;

  Future<void> _pendingWrites = Future<void>.value();

  static String _normalizeLanguage(String? languageCode) {
    switch (languageCode) {
      case 'ar':
      case 'en':
      case 'fr':
        return languageCode!;
      default:
        return 'ar';
    }
  }

  String get languageCode => _languageCode;

  bool get isArabic => _languageCode == 'ar';

  bool get isDark => _isDark;

  ThemeMode get themeMode =>
      _isDark ? ThemeMode.dark : ThemeMode.light;

  Locale get locale => Locale(_languageCode);

  TextDirection get textDirection =>
      isArabic ? TextDirection.rtl : TextDirection.ltr;

  void toggleLanguage() {
    setLanguage(isArabic ? 'en' : 'ar');
  }

  void setLanguage(String languageCode) {
    if (languageCode != 'ar' &&
        languageCode != 'en' &&
        languageCode != 'fr') {
      return;
    }

    if (_languageCode == languageCode) {
      return;
    }

    _languageCode = languageCode;

    notifyListeners();

    _queuePreferenceWrite(() async {
      final preferences = _preferences;

      if (preferences == null) {
        return;
      }

      await preferences.setString(
        _languageCodeKey,
        languageCode,
      );

      // Keep the legacy preference synchronized.
      await preferences.setBool(
        _legacyArabicKey,
        languageCode == 'ar',
      );
    });
  }

  void toggleTheme() {
    setDarkMode(!_isDark);
  }

  void setDarkMode(bool isDark) {
    if (_isDark == isDark) {
      return;
    }

    _isDark = isDark;

    notifyListeners();

    _queuePreferenceWrite(() async {
      final preferences = _preferences;

      if (preferences == null) {
        return;
      }

      await preferences.setBool(
        _darkModeKey,
        isDark,
      );
    });
  }

  void _queuePreferenceWrite(
    Future<void> Function() operation,
  ) {
    _pendingWrites = _pendingWrites.then((_) async {
      try {
        await operation();
      } catch (error, stackTrace) {
        debugPrint('Could not save application settings: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    });
  }
}

class MuslimsApp extends StatefulWidget {
  const MuslimsApp({
    required this.settingsController,
    super.key,
  });

  final SettingsController settingsController;

  @override
  State<MuslimsApp> createState() => _MuslimsAppState();
}

class _MuslimsAppState extends State<MuslimsApp> {
  @override
  void dispose() {
    widget.settingsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<PrayerController>(
          create: (_) => PrayerController(),
        ),
        ChangeNotifierProvider<SettingsController>.value(
          value: widget.settingsController,
        ),
      ],
      child: Consumer<SettingsController>(
        builder: (context, settings, child) {
          return MaterialApp(
            title: 'Muslims Pro',
            debugShowCheckedModeBanner: false,

            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: settings.themeMode,

            locale: settings.locale,

            supportedLocales: const [
              Locale('ar'),
              Locale('en'),
              Locale('fr'),
            ],

            localizationsDelegates:
                GlobalMaterialLocalizations.delegates,

            home: PrayerHomePage(
              isArabic: settings.isArabic,
              onLanguageToggle: settings.toggleLanguage,
              isDark: settings.isDark,
              onThemeToggle: settings.toggleTheme,
            ),
          );
        },
      ),
    );
  }
}
