
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'mumin_language_registry.dart';
import 'mumin_localizations.dart';

/// Central language controller for the entire Mumin Pro application.
///
/// The independent MuminLanguageRegistry is the single source of
/// language metadata, launch approval, locale direction and preferences.
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
      MuminLanguageRegistry.languagePreferenceKey;

  static const String legacyPreferenceKey =
      MuminLanguageRegistry.legacyLanguagePreferenceKey;

  final SharedPreferences? _preferences;

  String _languageCode;

  bool _isDisposed = false;

  Future<void> _pendingWrites = Future<void>.value();

  // ---------------------------------------------------------------------------
  // CURRENT LANGUAGE
  // ---------------------------------------------------------------------------

  String get languageCode => _languageCode;

  MuminLanguage get language =>
      MuminLanguageRegistry.launchLanguageFor(_languageCode) ??
      MuminLanguageRegistry.languages[
          MuminLanguageRegistry.defaultLanguageCode]!;

  MuminLocalizations get localizations =>
      MuminLocalizations.fromCode(_languageCode);

  Locale get locale => Locale(languageCode);

  TextDirection get textDirection =>
      language.isRightToLeft
          ? TextDirection.rtl
          : TextDirection.ltr;

  bool get isArabic => languageCode == 'ar';

  bool get isEnglish => languageCode == 'en';

  bool get isFrench => languageCode == 'fr';

  bool get isRightToLeft => language.isRightToLeft;

  bool get isLeftToRight => language.isLeftToRight;

  bool get canPersist => _preferences != null;

  /// Locales approved for the current application release.
  List<Locale> get supportedLocales =>
      MuminLanguageRegistry.availableLanguages
          .map((language) => Locale(language.code))
          .toList(growable: false);

  /// Languages approved for the current application release.
  ///
  /// Registered future languages remain unavailable until explicitly
  /// approved in the central registry.
  List<MuminLanguage> get availableLanguages =>
      MuminLanguageRegistry.availableLanguages;

  bool _isApprovedLaunchLanguage(String? code) =>
      MuminLanguageRegistry.isSupported(code);

  // ---------------------------------------------------------------------------
  // LANGUAGE SELECTION
  // ---------------------------------------------------------------------------

  /// Changes the selected language immediately.
  ///
  /// Returns false when the requested language is not approved
  /// for the current release.
  ///
  /// The interface updates before the asynchronous preference
  /// write completes.
  bool setLanguage(String languageCode) {
    if (_isDisposed ||
        !_isApprovedLaunchLanguage(languageCode)) {
      debugPrint(
        'Mumin Pro: unsupported launch language: $languageCode',
      );
      return false;
    }

    final normalized =
        MuminLanguageRegistry.normalizeLanguageCode(languageCode);

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

  // ---------------------------------------------------------------------------
  // LANGUAGE RESTORATION AND MIGRATION
  // ---------------------------------------------------------------------------

  /// Restores the language from persistent local storage.
  ///
  /// The modern language-code preference has priority.
  /// The legacy boolean preference is used only for migration.
  Future<void> restoreLanguage() async {
    if (_isDisposed) {
      return;
    }

    final preferences = _preferences;

    if (preferences == null) {
      return;
    }

    String? savedCode;

    try {
      savedCode = preferences.getString(preferenceKey);
    } catch (error, stackTrace) {
      debugPrint(
        'Mumin Pro: could not read language preference: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
    }

    if (_isApprovedLaunchLanguage(savedCode)) {
      final restored =
          MuminLanguageRegistry.normalizeLanguageCode(savedCode);

      if (_languageCode != restored) {
        _languageCode = restored;
        notifyListeners();
      }

      return;
    }

    bool? legacyArabic;

    try {
      legacyArabic = preferences.getBool(legacyPreferenceKey);
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
      await preferences.setString(
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
  /// The fallback is used only when neither the selected language
  /// nor the central fallback catalog contains the requested key.
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

  /// Resolves a prayer name through the central translation engine.
  String prayerName(String prayerKey) =>
      localizations.prayerName(prayerKey);

  // ---------------------------------------------------------------------------
  // PERSISTENCE
  // ---------------------------------------------------------------------------

  /// Serializes preference writes to preserve their order.
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
  Future<void> waitForPendingWrites() => _pendingWrites;

  // ---------------------------------------------------------------------------
  // INITIALIZATION
  // ---------------------------------------------------------------------------

  static String _resolveInitialLanguage(String? code) {
    return MuminLanguageRegistry.normalizeLanguageCode(code);
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
