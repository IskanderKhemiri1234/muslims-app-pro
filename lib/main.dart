
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audio_service/audio_service.dart';

import 'core/design_system/mumin_theme.dart';
import 'core/localization/mumin_language_controller.dart';
import 'core/localization/mumin_localizations.dart';
import 'core/localization/mumin_localizations_delegate.dart';
import 'core/notifications/mumin_notification_preferences.dart';

import 'features/adhan/data/services/mumin_adhan_audio_handler.dart';
import 'features/adhan/data/services/mumin_adhan_asset_playback_service.dart';
import 'features/adhan/data/services/mumin_adhan_notification_service.dart';
import 'features/adhan/data/services/mumin_adhan_prayer_recording_preferences.dart';
import 'features/adhan/data/services/mumin_adhan_recording_playback_service.dart';

import 'features/home/presentation/pages/home_page.dart';
import 'features/prayer_times/presentation/controllers/prayer_controller.dart';

/// Initialized only by the real application entry point.
///
/// Widget tests can construct MuminApp directly without initializing
/// platform audio services.
late final MuminAdhanAudioHandler muminAdhanAudioHandler;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  muminAdhanAudioHandler =
      await AudioService.init<MuminAdhanAudioHandler>(
    builder: MuminAdhanAudioHandler.new,
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.iskander.muslimspro.adhan',
      androidNotificationChannelName: 'Mumin Pro Adhan',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );

  runApp(const MuminBootstrap());
}

/// Restores application preferences before creating the application.
class MuminBootstrap extends StatefulWidget {
  const MuminBootstrap({super.key});

  @override
  State<MuminBootstrap> createState() => _MuminBootstrapState();
}

class _MuminBootstrapState extends State<MuminBootstrap> {
  late final Future<_MuminBootstrapData> _bootstrapFuture;

  @override
  void initState() {
    super.initState();
    _bootstrapFuture = _initializeApplication();
  }

  Future<_MuminBootstrapData> _initializeApplication() async {
    SharedPreferences? preferences;

    try {
      preferences = await SharedPreferences.getInstance();
    } catch (error, stackTrace) {
      debugPrint(
        'Mumin Pro: preference storage is unavailable: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
    }

    String? savedLanguageCode;
    bool? legacyArabicSetting;
    bool? savedDarkMode;

    if (preferences != null) {
      try {
        savedLanguageCode = preferences.getString(
          MuminLanguageController.preferenceKey,
        );
      } catch (error, stackTrace) {
        debugPrint(
          'Mumin Pro: language preference could not be read: $error',
        );
        debugPrintStack(stackTrace: stackTrace);
      }

      try {
        legacyArabicSetting = preferences.getBool(
          MuminLanguageController.legacyPreferenceKey,
        );
      } catch (error, stackTrace) {
        debugPrint(
          'Mumin Pro: legacy language preference is invalid: $error',
        );
        debugPrintStack(stackTrace: stackTrace);
      }

      try {
        savedDarkMode = preferences.getBool(
          SettingsController.darkModeKey,
        );
      } catch (error, stackTrace) {
        debugPrint(
          'Mumin Pro: theme preference could not be read: $error',
        );
        debugPrintStack(stackTrace: stackTrace);
      }
    }

    final String initialLanguageCode;

    if (MuminLocalizations.isSupported(savedLanguageCode)) {
      initialLanguageCode =
          MuminLocalizations.normalizeLanguageCode(
        savedLanguageCode,
      );
    } else if (legacyArabicSetting != null) {
      initialLanguageCode =
          legacyArabicSetting ? 'ar' : 'en';
    } else {
      initialLanguageCode =
          MuminLocalizations.defaultLanguageCode;
    }

    final languageController = MuminLanguageController(
      preferences: preferences,
      initialLanguageCode: initialLanguageCode,
    );

    final settingsController = SettingsController(
      preferences: preferences,
      isDark: savedDarkMode ?? true,
    );

    // Migrate old installations to the central language preference.
    if (preferences != null &&
        !MuminLocalizations.isSupported(savedLanguageCode)) {
      languageController.setLanguage(initialLanguageCode);
    }

    return _MuminBootstrapData(
      languageController: languageController,
      settingsController: settingsController,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_MuminBootstrapData>(
      future: _bootstrapFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return MuminApp(
            languageController: snapshot.data!.languageController,
            settingsController: snapshot.data!.settingsController,
            audioHandler: muminAdhanAudioHandler,
          );
        }

        if (snapshot.hasError) {
          debugPrint(
            'Mumin Pro: application initialization failed: '
            '${snapshot.error}',
          );

          return MuminApp(
            languageController: MuminLanguageController(
              preferences: null,
            ),
            settingsController: SettingsController(
              preferences: null,
              isDark: true,
            ),
            audioHandler: muminAdhanAudioHandler,
          );
        }

        return const _StartupScreen();
      },
    );
  }
}

class _MuminBootstrapData {
  const _MuminBootstrapData({
    required this.languageController,
    required this.settingsController,
  });

  final MuminLanguageController languageController;
  final SettingsController settingsController;
}

/// Theme preferences only.
///
/// Language state is exclusively owned by MuminLanguageController.
class SettingsController extends ChangeNotifier {
  SettingsController({
    required SharedPreferences? preferences,
    required bool isDark,
  })  : _preferences = preferences,
        _isDark = isDark;

  static const String darkModeKey = 'app_theme_dark';

  final SharedPreferences? _preferences;

  bool _isDark;
  bool _isDisposed = false;

  Future<void> _pendingWrites = Future<void>.value();

  bool get isDark => _isDark;

  ThemeMode get themeMode =>
      _isDark ? ThemeMode.dark : ThemeMode.light;

  bool get canPersistSettings => _preferences != null;

  void toggleTheme() {
    setDarkMode(!_isDark);
  }

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
        debugPrint(
          'Mumin Pro: theme preference was not saved.',
        );
      }
    });
  }

  void _enqueuePreferenceWrite(
    Future<void> Function() operation,
  ) {
    _pendingWrites = _pendingWrites.then((_) async {
      if (_isDisposed) {
        return;
      }

      try {
        await operation();
      } catch (error, stackTrace) {
        debugPrint(
          'Mumin Pro: could not save theme settings: $error',
        );
        debugPrintStack(stackTrace: stackTrace);
      }
    });
  }

  Future<void> waitForPendingWrites() => _pendingWrites;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}

/// Root application widget.
///
/// Audio is optional here because widget tests and previews must be able
/// to construct the application without invoking platform audio plugins.
class MuminApp extends StatefulWidget {
  const MuminApp({
    required this.languageController,
    required this.settingsController,
    this.audioHandler,
    super.key,
  });

  final MuminLanguageController languageController;
  final SettingsController settingsController;
  final MuminAdhanAudioHandler? audioHandler;

  @override
  State<MuminApp> createState() => _MuminAppState();
}

class _MuminAppState extends State<MuminApp> {
  @override
  void dispose() {
    widget.languageController.dispose();
    widget.settingsController.dispose();
    super.dispose();
  }

  Future<void> _showLanguagePicker(
    BuildContext context,
    MuminLanguageController languageController,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: false,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (sheetContext) {
        return Consumer<MuminLanguageController>(
          builder: (context, languages, child) {
            final localizations = languages.localizations;

            return Directionality(
              textDirection: languages.textDirection,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  24,
                ),
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
                    for (final language
                        in languages.availableLanguages)
                      _LanguageOption(
                        language: language,
                        selected:
                            languages.languageCode == language.code,
                        onTap: () {
                          final changed =
                              languageController.setLanguage(
                            language.code,
                          );

                          if (changed) {
                            Navigator.of(sheetContext).pop();
                          }
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
    final audioHandler = widget.audioHandler;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<PrayerController>(
          create: (_) => PrayerController(),
        ),

        Provider<MuminNotificationPreferences>(
          create: (_) => MuminNotificationPreferences(),
        ),

        Provider<MuminAdhanNotificationService>(
          create: (_) => MuminAdhanNotificationService(),
        ),

        Provider<MuminAdhanPrayerRecordingPreferences>(
          create: (_) => MuminAdhanPrayerRecordingPreferences(),
        ),

        // Register audio-dependent services only when the real
        // application has initialized its audio handler.
        if (audioHandler != null) ...[
          Provider<MuminAdhanAudioHandler>.value(
            value: audioHandler,
          ),

          Provider<MuminAdhanRecordingPlaybackService>(
            create: (context) =>
                MuminAdhanRecordingPlaybackService(
              audioHandler:
                  context.read<MuminAdhanAudioHandler>(),
            ),
          ),

          Provider<MuminAdhanAssetPlaybackService>(
            create: (context) =>
                MuminAdhanAssetPlaybackService(
              audioHandler:
                  context.read<MuminAdhanAudioHandler>(),
            ),
          ),
        ],

        ChangeNotifierProvider<MuminLanguageController>.value(
          value: widget.languageController,
        ),

        ChangeNotifierProvider<SettingsController>.value(
          value: widget.settingsController,
        ),
      ],
      child: Consumer2<
          MuminLanguageController,
          SettingsController>(
        builder: (context, languages, settings, child) {
          final localizations = languages.localizations;

          return MaterialApp(
            title: localizations.appName,
            debugShowCheckedModeBanner: false,
            theme: MuminTheme.light,
            darkTheme: MuminTheme.dark,
            themeMode: settings.themeMode,
            locale: languages.locale,
            supportedLocales: languages.supportedLocales,
            localizationsDelegates: const [
              MuminLocalizationsDelegate(),
              ...GlobalMaterialLocalizations.delegates,
            ],
            localeResolutionCallback:
                (deviceLocale, supportedLocales) {
              for (final supportedLocale in supportedLocales) {
                if (supportedLocale.languageCode ==
                    languages.languageCode) {
                  return supportedLocale;
                }
              }

              return const Locale(
                MuminLocalizations.defaultLanguageCode,
              );
            },
            builder: (context, child) {
              return Directionality(
                textDirection: languages.textDirection,
                child: child ?? const SizedBox.shrink(),
              );
            },
            home: PrayerHomePage(
              onLanguageToggle: () {
                _showLanguagePicker(context, languages);
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
    required this.language,
    required this.selected,
    required this.onTap,
  });

  final MuminLanguage language;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      selected: selected,
      label: '${language.nativeName}, ${language.englishName}',
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        leading: CircleAvatar(
          radius: 17,
          backgroundColor: selected
              ? colorScheme.primary.withValues(alpha: 0.14)
              : colorScheme.surfaceContainerHighest,
          child: Text(
            language.code.toUpperCase(),
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
          language.nativeName,
          style: TextStyle(
            fontWeight:
                selected ? FontWeight.w800 : FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          language.englishName,
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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
        Locale('fr'),
      ],
      localizationsDelegates: const [
        MuminLocalizationsDelegate(),
        ...GlobalMaterialLocalizations.delegates,
      ],
      theme: MuminTheme.dark,
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: _StartupContent(),
      ),
    );
  }
}

class _StartupContent extends StatelessWidget {
  const _StartupContent();

  @override
  Widget build(BuildContext context) {
    final localizations = MuminLocalizations.fromCode(
      MuminLocalizations.defaultLanguageCode,
    );

    return Scaffold(
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
    );
  }
}
