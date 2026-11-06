
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'mumin_localizations.dart';

/// Central language controller for the entire Mumin Pro application.
///
/// Responsibilities:
/// - Own the selected language.
/// - Enforce approved launch languages.
/// - Expose supported locales to Flutter.
/// - Resolve locale and text direction centrally.
/// - Provide access to the central translation engine.
/// - Persist language changes locally.
/// - Serialize writes to prevent out-of-order preferences.
///
/// Theme settings deliberately do not belong here.
final class MuminLanguageController extends ChangeNotifier {
  MuminLanguageController({
    required SharedPreferences? preferences,
    String? initialLanguageCode,
  })  : _preferences = preferences,
        _languageCode = _resolveInitialLanguage(initialLanguageCode);

  static const String preferenceKey =
      MuminLocalizations.languagePreferenceKey;

  static const String legacyPreferenceKey =
      MuminLocalizations.legacyLanguagePreferenceKey;

  final SharedPreferences? _preferences;

  String _languageCode;

  bool _isDisposed = false;

  Future<void> _pendingWrites = Future<void>.value();

  // ---------------------------------------------------------------------------
  // CURRENT LANGUAGE
  // ---------------------------------------------------------------------------

  String get languageCode => _languageCode;

  MuminLanguage get language =>
      MuminLocalizations.languageFor(_languageCode) ??
      MuminLocalizations.languageRegistry[
          MuminLocalizations.defaultLanguageCode]!;

  MuminLocalizations get localizations =>
      MuminLocalizations.fromCode(_languageCode);

  Locale get locale => Locale(languageCode);

  TextDirection get textDirection {
    return language.direction == MuminTextDirection.rtl
        ? TextDirection.rtl
        : TextDirection.ltr;
  }

  bool get isArabic => languageCode == 'ar';

  bool get isEnglish => languageCode == 'en';

  bool get isFrench => languageCode == 'fr';

  bool get isRightToLeft =>
      language.direction == MuminTextDirection.rtl;

  bool get isLeftToRight =>
      language.direction == MuminTextDirection.ltr;

  bool get canPersist => _preferences != null;

  /// Locales approved for the current release.
  ///
  /// The language registry is the single source of language metadata.
  List<Locale> get supportedLocales {
    return availableLanguages
        .map((language) => Locale(language.code))
        .toList(growable: false);
  }

  /// Languages approved for the current release.
  ///
  /// Registered future languages remain unavailable until explicitly
  /// approved for launch.
  List<MuminLanguage> get availableLanguages {
    return MuminLocalizations.languageRegistry.values
        .where((language) => language.isLaunchLanguage)
        .toList(growable: false);
  }

  bool _isApprovedLaunchLanguage(String? code) {
    final language = MuminLocalizations.languageFor(code);

    return language != null && language.isLaunchLanguage;
  }

  // ---------------------------------------------------------------------------
  // LANGUAGE SELECTION
  // ---------------------------------------------------------------------------

  /// Changes the selected language immediately.
  ///
  /// Returns false when the requested language is not approved for launch.
  /// The UI updates before the asynchronous preference write completes.
  bool setLanguage(String languageCode) {
    if (_isDisposed ||
        !_isApprovedLaunchLanguage(languageCode)) {
      debugPrint(
        'Mumin Pro: unsupported launch language: $languageCode',
      );
      return false;
    }

    final normalized =
        MuminLocalizations.normalizeLanguageCode(languageCode);

    if (!_isApprovedLaunchLanguage(normalized)) {
      return false;
    }

    if (_languageCode == normalized) {
      return true;
    }

    _languageCode = normalized;

    notifyListeners();

    _enqueueWrite(() async {
      final preferences = _preferences;

      if (preferences == null) {
        return;
      }

      final saved = await preferences.setString(
        preferenceKey,
        normalized,
      );

      // Keep the legacy preference synchronized during migration.
      final legacySaved = await preferences.setBool(
        legacyPreferenceKey,
        normalized == 'ar',
      );

      if (!saved || !legacySaved) {
        debugPrint(
          'Mumin Pro: language preference was not fully saved.',
        );
      }
    });

    return true;
  }

  /// Restores the language from persistent storage.
  ///
  /// The modern language-code preference has priority.
  /// The legacy boolean preference is used only for migration.
  Future<void> restoreLanguage() async {
    if (_isDisposed || _preferences == null) {
      return;
    }

    String? savedCode;

    try {
      savedCode = _preferences!.getString(preferenceKey);
    } catch (error, stackTrace) {
      debugPrint(
        'Mumin Pro: could not read language preference: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
    }

    if (_isApprovedLaunchLanguage(savedCode)) {
      final restored =
          MuminLocalizations.normalizeLanguageCode(savedCode);

      if (_languageCode != restored) {
        _languageCode = restored;
        notifyListeners();
      }

      return;
    }

    bool? legacyArabic;

    try {
      legacyArabic = _preferences!.getBool(legacyPreferenceKey);
    } catch (error, stackTrace) {
      debugPrint(
        'Mumin Pro: legacy language preference is invalid: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
    }

    if (legacyArabic == null) {
      return;
    }

    final migratedCode = legacyArabic ? 'ar' : 'en';

    if (_languageCode != migratedCode) {
      _languageCode = migratedCode;
      notifyListeners();
    }

    _enqueueWrite(() async {
      await _preferences!.setString(
        preferenceKey,
        migratedCode,
      );
    });
  }

  // ---------------------------------------------------------------------------
  // TRANSLATION ACCESS
  // ---------------------------------------------------------------------------

  /// Resolves a central translation and interpolates its parameters.
  String text(
    String key, {
    Map<String, Object?> parameters = const {},
  }) {
    return _interpolate(
      localizations.text(key),
      parameters,
    );
  }

  /// Resolves a central translation with an explicit fallback.
  ///
  /// The fallback is used only when neither the selected language nor
  /// the central fallback catalog contains the requested key.
  String textOr(
    String key,
    String fallback, {
    Map<String, Object?> parameters = const {},
  }) {
    final resolved = localizations.textOr(
      key,
      fallback: fallback,
    );

    return _interpolate(resolved, parameters);
  }

  String _interpolate(
    String value,
    Map<String, Object?> parameters,
  ) {
    var result = value;

    for (final entry in parameters.entries) {
      result = result.replaceAll(
        '{${entry.key}}',
        entry.value?.toString() ?? '',
      );
    }

    return result;
  }

  String prayerName(String prayerKey) {
    return localizations.prayerName(prayerKey);
  }

  // ---------------------------------------------------------------------------
  // PERSISTENCE
  // ---------------------------------------------------------------------------

  void _enqueueWrite(
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
          'Mumin Pro: language persistence failed: $error',
        );
        debugPrintStack(stackTrace: stackTrace);
      }
    });
  }

  /// Waits until all queued language writes have finished.
  Future<void> waitForPendingWrites() {
    return _pendingWrites;
  }

  // ---------------------------------------------------------------------------
  // INITIALIZATION
  // ---------------------------------------------------------------------------

  static String _resolveInitialLanguage(String? code) {
    final language = MuminLocalizations.languageFor(code);

    if (language != null && language.isLaunchLanguage) {
      return language.code;
    }

    return MuminLocalizations.defaultLanguageCode;
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
