
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'mumin_localizations.dart';

/// Central language controller for the entire Mumin Pro application.
///
/// Responsibilities:
/// - Own the selected language.
/// - Enforce the official language registry.
/// - Expose only approved launch languages to Flutter.
/// - Resolve locale and text direction from central metadata.
/// - Provide the central translation engine.
/// - Persist language changes locally.
/// - Serialize writes to avoid out-of-order preferences.
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

  /// Languages exposed to Flutter in the current release.
  ///
  /// The registry is the source of truth. A language can be registered
  /// for future development without becoming available to users until
  /// it is explicitly marked as a launch language.
  List<Locale> get supportedLocales {
    return MuminLocalizations.languageRegistry.values
        .where((language) => language.isLaunchLanguage)
        .map((language) => Locale(language.code))
        .toList(growable: false);
  }

  /// Registered languages approved for the current release.
  List<MuminLanguage> get availableLanguages {
    return MuminLocalizations.languageRegistry.values
        .where((language) => language.isLaunchLanguage)
        .toList(growable: false);
  }

  // ---------------------------------------------------------------------------
  // LANGUAGE SELECTION
  // ---------------------------------------------------------------------------

  /// Changes the selected language immediately.
  ///
  /// Returns false when the requested language is not registered.
  /// The UI updates before the asynchronous preference write completes.
  bool setLanguage(String languageCode) {
    if (_isDisposed) {
      return false;
    }

    if (!MuminLocalizations.isSupported(languageCode)) {
      debugPrint(
        'Mumin Pro: unsupported language: $languageCode',
      );
      return false;
    }

    final normalized =
        MuminLocalizations.normalizeLanguageCode(languageCode);

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

      // Keep the old Arabic/English preference synchronized
      // while older screens are being migrated.
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
  /// The old boolean preference is used only for migration.
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

    if (MuminLocalizations.isSupported(savedCode)) {
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

  String text(
    String key, {
    Map<String, Object?> parameters = const {},
  }) {
    return localizations.textWith(
      key,
      parameters,
    );
  }

  String textOr(
    String key,
    String fallback, {
    Map<String, Object?> parameters = const {},
  }) {
    return localizations.textOr(
      key,
      fallback,
      parameters: parameters,
    );
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
    if (MuminLocalizations.isSupported(code)) {
      return MuminLocalizations.normalizeLanguageCode(code);
    }

    return MuminLocalizations.defaultLanguageCode;
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
