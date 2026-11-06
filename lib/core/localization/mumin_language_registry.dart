
/// Mumin Pro — Independent Language Registry.
///
/// This file is the single source of truth for language metadata.
///
/// Responsibilities:
/// - Register available languages.
/// - Define native and English language names.
/// - Define text direction.
/// - Separate registered languages from launch-approved languages.
/// - Resolve language codes and locale tags.
/// - Provide centralized default and fallback policies.
///
/// Launch languages:
/// - Arabic (ar)
/// - English (en)
/// - French (fr)
///
/// Future languages can be registered here with
/// `isLaunchLanguage: false`.
/// They will remain unavailable to the launch application until
/// their translations and release requirements are completed.

enum MuminTextDirection {
  rtl,
  ltr,
}

/// Immutable metadata describing one application language.
final class MuminLanguage {
  const MuminLanguage({
    required this.code,
    required this.nativeName,
    required this.englishName,
    required this.direction,
    required this.isLaunchLanguage,
  });

  /// ISO 639-1 language code.
  final String code;

  /// Language name in its own writing system.
  final String nativeName;

  /// English language name.
  final String englishName;

  /// Writing direction used by the application.
  final MuminTextDirection direction;

  /// Whether this language is approved for the current release.
  final bool isLaunchLanguage;

  bool get isRightToLeft =>
      direction == MuminTextDirection.rtl;

  bool get isLeftToRight =>
      direction == MuminTextDirection.ltr;

  /// Locale identifier currently used by Mumin Pro.
  String get localeTag => code;
}

/// Central and independent registry for Mumin Pro languages.
abstract final class MuminLanguageRegistry {
  // ---------------------------------------------------------------------------
  // CENTRAL POLICY
  // ---------------------------------------------------------------------------

  /// Default application language for new installations.
  static const String defaultLanguageCode = 'ar';

  /// Language used when a translation is missing.
  static const String fallbackLanguageCode = 'ar';

  /// Current persistent language preference.
  static const String languagePreferenceKey =
      'app_language_code';

  /// Legacy preference retained for migration compatibility.
  static const String legacyLanguagePreferenceKey =
      'app_language_ar';

  // ---------------------------------------------------------------------------
  // SINGLE SOURCE OF LANGUAGE METADATA
  // ---------------------------------------------------------------------------

  /// All registered languages.
  ///
  /// Future languages may be registered here without making them
  /// available in the current release.
  static const Map<String, MuminLanguage> languages =
      <String, MuminLanguage>{
    'ar': MuminLanguage(
      code: 'ar',
      nativeName: 'العربية',
      englishName: 'Arabic',
      direction: MuminTextDirection.rtl,
      isLaunchLanguage: true,
    ),
    'en': MuminLanguage(
      code: 'en',
      nativeName: 'English',
      englishName: 'English',
      direction: MuminTextDirection.ltr,
      isLaunchLanguage: true,
    ),
    'fr': MuminLanguage(
      code: 'fr',
      nativeName: 'Français',
      englishName: 'French',
      direction: MuminTextDirection.ltr,
      isLaunchLanguage: true,
    ),
  };

  // ---------------------------------------------------------------------------
  // DERIVED LANGUAGE COLLECTIONS
  // ---------------------------------------------------------------------------

  /// Every registered language, including future non-launch languages.
  static List<MuminLanguage> get registeredLanguages =>
      languages.values.toList(growable: false);

  /// Languages approved for the current application release.
  static List<MuminLanguage> get availableLanguages =>
      languages.values
          .where((language) => language.isLaunchLanguage)
          .toList(growable: false);

  /// Codes of all registered languages.
  static List<String> get registeredLanguageCodes =>
      languages.keys.toList(growable: false);

  /// Codes approved for the current release.
  static List<String> get supportedLanguageCodes =>
      availableLanguages
          .map((language) => language.code)
          .toList(growable: false);

  /// Native names derived from the central registry.
  static Map<String, String> get languageNativeNames =>
      Map<String, String>.unmodifiable({
        for (final language in languages.values)
          language.code: language.nativeName,
      });

  /// English names derived from the central registry.
  static Map<String, String> get languageEnglishNames =>
      Map<String, String>.unmodifiable({
        for (final language in languages.values)
          language.code: language.englishName,
      });

  // ---------------------------------------------------------------------------
  // LANGUAGE CODE NORMALIZATION
  // ---------------------------------------------------------------------------

  /// Extracts the primary language code from a locale identifier.
  ///
  /// Examples:
  /// - ar
  /// - ar-MA
  /// - ar_MA
  /// - en-US
  /// - fr-FR
  static String? extractLanguageCode(String? input) {
    if (input == null || input.trim().isEmpty) {
      return null;
    }

    final normalized = input
        .trim()
        .replaceAll('_', '-')
        .toLowerCase();

    final parts = normalized.split('-');

    if (parts.isEmpty || parts.first.isEmpty) {
      return null;
    }

    return parts.first;
  }

  /// Returns true if a language exists in the registry.
  ///
  /// This includes future languages that are not yet approved
  /// for the current release.
  static bool isRegistered(String? code) {
    final normalized = extractLanguageCode(code);

    return normalized != null &&
        languages.containsKey(normalized);
  }

  /// Returns true only for languages approved for this release.
  static bool isSupported(String? code) {
    final language = languageFor(code);

    return language != null && language.isLaunchLanguage;
  }

  /// Resolves any registered language.
  ///
  /// Non-launch languages can be resolved internally, but must
  /// not be exposed to the current release UI.
  static MuminLanguage? languageFor(String? code) {
    final normalized = extractLanguageCode(code);

    if (normalized == null) {
      return null;
    }

    return languages[normalized];
  }

  /// Resolves a language only when it is approved for launch.
  static MuminLanguage? launchLanguageFor(String? code) {
    final language = languageFor(code);

    if (language == null || !language.isLaunchLanguage) {
      return null;
    }

    return language;
  }

  /// Normalizes a registered language code.
  ///
  /// Falls back to Arabic only when the code is unknown.
  static String normalizeRegisteredLanguageCode(String? code) {
    final language = languageFor(code);

    return language?.code ?? defaultLanguageCode;
  }

  /// Normalizes a code for the current release.
  ///
  /// A future registered language is intentionally rejected here
  /// until it is approved for launch.
  static String normalizeLanguageCode(String? code) {
    final language = launchLanguageFor(code);

    return language?.code ?? defaultLanguageCode;
  }

  // ---------------------------------------------------------------------------
  // DIRECTION AND LOCALE RESOLUTION
  // ---------------------------------------------------------------------------

  /// Returns the registered direction or the default direction.
  static MuminTextDirection directionFor(String? code) {
    return languageFor(code)?.direction ??
        languages[defaultLanguageCode]!.direction;
  }

  /// Returns true when the selected language is right-to-left.
  static bool isRightToLeft(String? code) {
    return directionFor(code) == MuminTextDirection.rtl;
  }

  /// Returns true when the selected language is left-to-right.
  static bool isLeftToRight(String? code) {
    return directionFor(code) == MuminTextDirection.ltr;
  }

  /// Resolves the locale tag for a registered language.
  static String localeTagFor(String? code) {
    return languageFor(code)?.localeTag ??
        defaultLanguageCode;
  }
}
