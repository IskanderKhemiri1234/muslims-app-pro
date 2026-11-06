
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/design_system/mumin_theme.dart';
import 'core/localization/mumin_localizations.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/prayer_times/presentation/controllers/prayer_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MuminBootstrap());
}

/// Restores persistent settings before starting the application.
class MuminBootstrap extends StatefulWidget {
  const MuminBootstrap({super.key});

  @override
  State<MuminBootstrap> createState() => _MuminBootstrapState();
}

class _MuminBootstrapState extends State<MuminBootstrap> {
  late final Future<SettingsController> _settingsFuture;

  @override
  void initState() {
    super.initState();
    _settingsFuture = _initializeSettings();
  }

  Future<SettingsController> _initializeSettings() async {
    SharedPreferences? preferences;

    try {
      preferences = await SharedPreferences.getInstance();
    } catch (error, stackTrace) {
      debugPrint('Mumin Pro: settings storage is unavailable: $error');
      debugPrintStack(stackTrace: stackTrace);
    }

    String? savedLanguageCode;
    bool? legacyArabicSetting;
    bool? savedDarkMode;

    if (preferences != null) {
      try {
        savedLanguageCode =
            preferences.getString(SettingsController.languageCodeKey);
      } catch (error, stackTrace) {
        debugPrint('Mumin Pro: language preference could not be read: $error');
        debugPrintStack(stackTrace: stackTrace);
      }

      try {
        legacyArabicSetting =
            preferences.getBool(SettingsController.legacyArabicKey);
      } catch (error, stackTrace) {
        debugPrint('Mumin Pro: legacy language preference is invalid: $error');
        debugPrintStack(stackTrace: stackTrace);
      }

      try {
        savedDarkMode =
            preferences.getBool(SettingsController.darkModeKey);
      } catch (error, stackTrace) {
        debugPrint('Mumin Pro: theme preference could not be read: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    }

    final String initialLanguage;

    if (MuminLocalizations.isSupported(savedLanguageCode)) {
      initialLanguage =
          MuminLocalizations.normalizeLanguageCode(savedLanguageCode);
    } else if (legacyArabicSetting != null) {
      initialLanguage = legacyArabicSetting ? 'ar' : 'en';
    } else {
      initialLanguage = MuminLocalizations.defaultLanguageCode;
    }

    return SettingsController(
      preferences: preferences,
      languageCode: initialLanguage,
      isDark: savedDarkMode ?? true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SettingsController>(
      future: _settingsFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return MuminApp(
            settingsController: snapshot.data!,
          );
        }

        if (snapshot.hasError) {
          return MuminApp(
            settingsController: SettingsController(
              preferences: null,
              languageCode: MuminLocalizations.defaultLanguageCode,
              isDark: true,
            ),
          );
        }

        return const _StartupScreen();
      },
    );
  }
}

/// Central application settings controller.
class SettingsController extends ChangeNotifier {
  SettingsController({
    required SharedPreferences? preferences,
    required String languageCode,
    required bool isDark,
  })  : _preferences = preferences,
        _languageCode =
            MuminLocalizations.normalizeLanguageCode(languageCode),
        _isDark = isDark;

  static const String languageCodeKey =
      MuminLocalizations.languagePreferenceKey;

  static const String legacyArabicKey = 'app_language_ar';

  static const String darkModeKey = 'app_theme_dark';

  final SharedPreferences? _preferences;

  String _languageCode;
  bool _isDark;
  bool _isDisposed = false;

  Future<void> _pendingWrites = Future<void>.value();

  String get languageCode => _languageCode;

  bool get isArabic => _languageCode == 'ar';

  bool get isEnglish => _languageCode == 'en';

  bool get isFrench => _languageCode == 'fr';

  bool get isDark => _isDark;

  Locale get locale => Locale(_languageCode);

  ThemeMode get themeMode =>
      _isDark ? ThemeMode.dark : ThemeMode.light;

  TextDirection get textDirection =>
      isArabic ? TextDirection.rtl : TextDirection.ltr;

  MuminLocalizations get localizations =>
      MuminLocalizations.fromCode(_languageCode);

  bool get canPersistSettings => _preferences != null;

  /// Changes the language immediately and persists it asynchronously.
  ///
  /// Region-specific codes are accepted when their language is supported.
  void setLanguage(String languageCode) {
    if (_isDisposed || !MuminLocalizations.isSupported(languageCode)) {
      debugPrint(
        'Mumin Pro: unsupported language selection: $languageCode',
      );
      return;
    }

    final normalized =
        MuminLocalizations.normalizeLanguageCode(languageCode);

    if (_languageCode == normalized) {
      return;
    }

    _languageCode = normalized;
    notifyListeners();

    _enqueuePreferenceWrite(() async {
      final preferences = _preferences;

      if (preferences == null) {
        return;
      }

      final languageSaved = await preferences.setString(
        languageCodeKey,
        normalized,
      );

      final legacySaved = await preferences.setBool(
        legacyArabicKey,
        normalized == 'ar',
      );

      if (!languageSaved || !legacySaved) {
        debugPrint(
          'Mumin Pro: language preferences were not fully saved.',
        );
      }
    });
  }

  /// Toggles the application theme.
  void toggleTheme() {
    setDarkMode(!_isDark);
  }

  /// Sets the application theme explicitly.
  void setDarkMode(bool isDark) {
    if (_isDisposed || _isDark == isDark) {
      return;
    }

    _isDark = isDark;
    notifyListeners();

    _enqueuePreferenceWrite(() async {
      final preferences = _preferences;

      if (preferences == null) {
        return;
      }

      final saved = await preferences.setBool(
        darkModeKey,
        isDark,
      );

      if (!saved) {
        debugPrint('Mumin Pro: theme preference was not saved.');
      }
    });
  }

  /// Serializes preference writes to preserve their order.
  void _enqueuePreferenceWrite(
    Future<void> Function() operation,
  ) {
    _pendingWrites = _pendingWrites.then((_) async {
      try {
        await operation();
      } catch (error, stackTrace) {
        debugPrint('Mumin Pro: could not save settings: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    });
  }

  /// Waits for all queued preference writes.
  Future<void> waitForPendingWrites() => _pendingWrites;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}

/// Root application widget.
class MuminApp extends StatefulWidget {
  const MuminApp({
    required this.settingsController,
    super.key,
  });

  final SettingsController settingsController;

  @override
  State<MuminApp> createState() => _MuminAppState();
}

class _MuminAppState extends State<MuminApp> {
  static const List<String> _languageOrder = <String>[
    'ar',
    'en',
    'fr',
  ];

  @override
  void dispose() {
    widget.settingsController.dispose();
    super.dispose();
  }

  Future<void> _showLanguagePicker(
    BuildContext context,
    SettingsController settings,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: false,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (sheetContext) {
        return Consumer<SettingsController>(
          builder: (context, currentSettings, child) {
            final localizations = currentSettings.localizations;

            return Directionality(
              textDirection: currentSettings.textDirection,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      localizations.selectLanguage,
                      textAlign: TextAlign.start,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    for (final code in _languageOrder)
                      _LanguageOption(
                        languageCode: code,
                        selected: currentSettings.languageCode == code,
                        onTap: () {
                          currentSettings.setLanguage(code);
                          Navigator.of(sheetContext).pop();
                        },
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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
          final localizations = settings.localizations;

          return MaterialApp(
            title: localizations.appName,
            debugShowCheckedModeBanner: false,
            theme: MuminTheme.light,
            darkTheme: MuminTheme.dark,
            themeMode: settings.themeMode,
            locale: settings.locale,
            supportedLocales: MuminLocalizations.supportedLanguageCodes
                .map((code) => Locale(code))
                .toList(growable: false),
            localizationsDelegates:
                GlobalMaterialLocalizations.delegates,
            localeResolutionCallback: (deviceLocale, supportedLocales) {
              for (final supportedLocale in supportedLocales) {
                if (supportedLocale.languageCode ==
                    settings.languageCode) {
                  return supportedLocale;
                }
              }

              if (deviceLocale != null) {
                for (final supportedLocale in supportedLocales) {
                  if (supportedLocale.languageCode ==
                      deviceLocale.languageCode) {
                    return supportedLocale;
                  }
                }
              }

              return Locale(
                MuminLocalizations.defaultLanguageCode,
              );
            },
            home: PrayerHomePage(
              isArabic: settings.isArabic,
              onLanguageToggle: () {
                _showLanguagePicker(context, settings);
              },
              isDark: settings.isDark,
              onThemeToggle: settings.toggleTheme,
            ),
          );
        },
      ),
    );
  }
}

/// Language selector row.
class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.languageCode,
    required this.selected,
    required this.onTap,
  });

  final String languageCode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final localizations =
        MuminLocalizations.fromCode(languageCode);

    final colorScheme = Theme.of(context).colorScheme;

    final nativeName = localizations.languageNativeName;
    final englishName = localizations.languageEnglishName;

    return Semantics(
      button: true,
      selected: selected,
      label: '$nativeName, $englishName',
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        leading: CircleAvatar(
          radius: 17,
          backgroundColor: selected
              ? colorScheme.primary.withValues(alpha: 0.14)
              : colorScheme.surfaceContainerHighest,
          child: Text(
            languageCode.toUpperCase(),
            style: TextStyle(
              color: selected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        title: Text(
          nativeName,
          style: TextStyle(
            fontWeight:
                selected ? FontWeight.w800 : FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          englishName,
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: selected
            ? Icon(
                Icons.check_circle_rounded,
                color: colorScheme.secondary,
              )
            : Icon(
                Icons.circle_outlined,
                color: colorScheme.outline,
              ),
      ),
    );
  }
}

/// Branded startup screen displayed while preferences are restored.
class _StartupScreen extends StatelessWidget {
  const _StartupScreen();

  @override
  Widget build(BuildContext context) {
    final localizations =
        MuminLocalizations.fromCode(
      MuminLocalizations.defaultLanguageCode,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
        Locale('fr'),
      ],
      localizationsDelegates:
          GlobalMaterialLocalizations.delegates,
      theme: MuminTheme.dark,
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: const Color(0xFF075B46),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: const Color(0xFFD8B66A),
                      width: 1.2,
                    ),
                  ),
                  child: const Icon(
                    Icons.mosque_rounded,
                    color: Color(0xFFD8B66A),
                    size: 34,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  localizations.appName,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 22),
                const SizedBox(
                  width: 25,
                  height: 25,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Color(0xFFD8B66A),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
