
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/prayer_times/presentation/controllers/prayer_controller.dart';

/// Application entry point.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final settingsController = await _initializeSettings();

  runApp(
    MuslimsApp(
      settingsController: settingsController,
    ),
  );
}

/// Loads application settings safely before rendering the application.
Future<SettingsController> _initializeSettings() async {
  try {
    final preferences = await SharedPreferences.getInstance();

    return SettingsController(
      preferences: preferences,
      initialArabic: preferences.getBool('app_language_ar') ?? true,
      initialDark: preferences.getBool('app_theme_dark') ?? true,
    );
  } catch (error, stackTrace) {
    debugPrint('Settings initialization failed: $error');
    debugPrintStack(stackTrace: stackTrace);

    // The application can still start with safe default settings.
    return SettingsController(
      preferences: null,
      initialArabic: true,
      initialDark: true,
    );
  }
}

// ============================================================
// APPLICATION SETTINGS
// ============================================================

/// Centralized settings controller.
///
/// Responsible for:
/// - Application language
/// - Light / dark appearance
/// - Persistent settings
/// - Notifying dependent widgets
class SettingsController extends ChangeNotifier {
  SettingsController({
    required SharedPreferences? preferences,
    required bool initialArabic,
    required bool initialDark,
  })  : _preferences = preferences,
        _isArabic = initialArabic,
        _isDark = initialDark;

  static const String _languageKey = 'app_language_ar';
  static const String _themeKey = 'app_theme_dark';

  final SharedPreferences? _preferences;

  bool _isArabic;
  bool _isDark;

  Future<void> _pendingWrites = Future<void>.value();

  bool get isArabic => _isArabic;

  bool get isDark => _isDark;

  ThemeMode get themeMode {
    return _isDark ? ThemeMode.dark : ThemeMode.light;
  }

  Locale get locale {
    return Locale(_isArabic ? 'ar' : 'en');
  }

  TextDirection get textDirection {
    return _isArabic ? TextDirection.rtl : TextDirection.ltr;
  }

  /// Switches between Arabic and English.
  void toggleLanguage() {
    setLanguage(isArabic: !_isArabic);
  }

  /// Sets the application language explicitly.
  void setLanguage({required bool isArabic}) {
    if (_isArabic == isArabic) return;

    _isArabic = isArabic;

    notifyListeners();

    _saveSetting(
      _languageKey,
      _isArabic,
    );
  }

  /// Switches between light and dark appearance.
  void toggleTheme() {
    setDarkMode(isDark: !_isDark);
  }

  /// Sets the application appearance explicitly.
  void setDarkMode({required bool isDark}) {
    if (_isDark == isDark) return;

    _isDark = isDark;

    notifyListeners();

    _saveSetting(
      _themeKey,
      _isDark,
    );
  }

  /// Serializes preference writes to avoid overlapping updates.
  void _saveSetting(String key, bool value) {
    final preferences = _preferences;

    if (preferences == null) return;

    _pendingWrites = _pendingWrites.then((_) async {
      try {
        await preferences.setBool(key, value);
      } catch (error, stackTrace) {
        debugPrint('Could not save setting "$key": $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    });
  }
}

// ============================================================
// APPLICATION ROOT
// ============================================================

class MuslimsApp extends StatelessWidget {
  const MuslimsApp({
    super.key,
    required this.settingsController,
  });

  final SettingsController settingsController;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<PrayerController>(
          create: (_) => PrayerController(),
        ),

        ChangeNotifierProvider<SettingsController>.value(
          value: settingsController,
        ),
      ],
      child: Consumer<SettingsController>(
        builder: (context, settings, child) {
          return MaterialApp(
            // Application identity.
            title: 'Muslims Pro',
            debugShowCheckedModeBanner: false,

            // Appearance.
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: settings.themeMode,

            // Localization.
            locale: settings.locale,
            supportedLocales: const [
              Locale('ar'),
              Locale('en'),
            ],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,

            // Smooth theme transitions.
            themeAnimationDuration: const Duration(
              milliseconds: 300,
            ),
            themeAnimationCurve: Curves.easeInOut,

            // Preserve the existing home page API.
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
