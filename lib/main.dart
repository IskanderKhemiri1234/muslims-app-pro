
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

/// Loads persistent settings before creating the application providers.
///
/// If local storage is unavailable, the application still starts with safe
/// defaults. A storage failure must never prevent access to prayer features.
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

    // Read each value independently. A malformed preference should not
    // prevent the other settings from being restored.
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

    if (savedLanguageCode != null &&
        MuminLocalizations.supportedLanguageCodes.contains(
          savedLanguageCode.trim().toLowerCase(),
        )) {
      initialLanguage = savedLanguageCode.trim().toLowerCase();
    } else if (legacyArabicSetting != null) {
      // Backward compatibility with installations that stored only
      // app_language_ar before the three-language selector was introduced.
      initialLanguage = legacyArabicSetting ? 'ar' : 'en';
    } else {
      initialLanguage = 'ar';
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
          // Defensive fallback. _initializeSettings normally catches storage
          // failures, but this prevents an unexpected initialization error
          // from leaving the user on an endless loading screen.
          return MuminApp(
            settingsController: SettingsController(
              preferences: null,
              languageCode: 'ar',
              isDark: true,
            ),
          );
        }

        return const _StartupScreen();
      },
    );
  }
}

/// Central application settings state.
///
/// The controller owns the selected language and theme. Widgets observe
/// changes through Provider, while persistence remains encapsulated here.
class SettingsController extends ChangeNotifier {
  SettingsController({
    required SharedPreferences? preferences,
    required String languageCode,
    required bool isDark,
  })  : _preferences = preferences,
        _languageCode =
            MuminLocalizations.fromCode(languageCode).languageCode,
        _isDark = isDark;

  static const String languageCodeKey = 'app_language_code';
  static const String legacyArabicKey = 'app_language_ar';
  static const String darkModeKey = 'app_theme_dark';

  final SharedPreferences? _preferences;

  String _languageCode;
  bool _isDark;
  bool _isDisposed = false;

  // Serializing writes prevents a slower previous write from overwriting
  // a more recent language or theme selection.
  Future<void> _pendingWrites = Future<void>.value();

  String get languageCode => _languageCode;

  bool get isArabic => _languageCode == 'ar';

  bool get isDark => _isDark;

  Locale get locale => Locale(_languageCode);

  ThemeMode get themeMode =>
      _isDark ? ThemeMode.dark : ThemeMode.light;

  TextDirection get textDirection =>
      isArabic ? TextDirection.rtl : TextDirection.ltr;

  MuminLocalizations get localizations =>
      MuminLocalizations.fromCode(_languageCode);

  bool get canPersistSettings => _preferences != null;

  /// Selects one of the supported application languages.
  ///
  /// The visible state updates immediately. Saving happens asynchronously
  /// and failures are logged without interrupting the current session.
  void setLanguage(String languageCode) {
    final normalized =
        MuminLocalizations.fromCode(languageCode).languageCode;

    // Reject unsupported input instead of silently switching the user
    // to the fallback language.
    if (!MuminLocalizations.supportedLanguageCodes.contains(
      languageCode.trim().toLowerCase(),
    )) {
      debugPrint('Mumin Pro: unsupported language selection: $languageCode');
      return;
    }

    if (_languageCode == normalized || _isDisposed) {
      return;
    }

    _languageCode = normalized;
    notifyListeners();

    _enqueuePreferenceWrite(() async {
      final preferences = _preferences;
      if (preferences == null) return;

      final languageSaved = await preferences.setString(
        languageCodeKey,
        normalized,
      );

      // Keep the old boolean key synchronized for older code paths.
      final legacySaved = await preferences.setBool(
        legacyArabicKey,
        normalized == 'ar',
      );

      if (!languageSaved || !legacySaved) {
        debugPrint('Mumin Pro: language preferences were not fully saved.');
      }
    });
  }

  /// Toggles between light and dark themes.
  void toggleTheme() {
    setDarkMode(!_isDark);
  }

  void setDarkMode(bool isDark) {
    if (_isDark == isDark || _isDisposed) {
      return;
    }

    _isDark = isDark;
    notifyListeners();

    _enqueuePreferenceWrite(() async {
      final preferences = _preferences;
      if (preferences == null) return;

      final saved = await preferences.setBool(
        darkModeKey,
        isDark,
      );

      if (!saved) {
        debugPrint('Mumin Pro: theme preference was not saved.');
      }
    });
  }

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

  /// Allows tests or controlled shutdown flows to wait for queued writes.
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
        final current = settings.languageCode;

        return Directionality(
          textDirection: settings.textDirection,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  settings.localizations.text('select_language'),
                  textAlign: TextAlign.start,
                  style: Theme.of(sheetContext).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                for (final code in _languageOrder)
                  _LanguageOption(
                    languageCode: code,
                    selected: current == code,
                    onTap: () {
                      settings.setLanguage(code);
                      Navigator.of(sheetContext).pop();
                    },
                  ),
              ],
            ),
          ),
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
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            localeResolutionCallback: (deviceLocale, supportedLocales) {
              // The explicit user selection takes precedence over the
              // device locale. The device locale is only a safe fallback.
              for (final supportedLocale in supportedLocales) {
                if (supportedLocale.languageCode == settings.languageCode) {
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

              return const Locale('en');
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

/// A language row with native and English names.
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
    final localizations = MuminLocalizations.fromCode(languageCode);
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
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
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

/// Minimal branded startup screen shown while preferences are restored.
class _StartupScreen extends StatelessWidget {
  const _StartupScreen();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: MuminTheme.dark,
      home: Scaffold(
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
                'Mumin Pro',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
    );
  }
}
