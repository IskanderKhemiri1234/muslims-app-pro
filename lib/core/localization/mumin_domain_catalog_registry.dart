
import 'catalogs/mumin_prayer_settings_catalog.dart';
import 'catalogs/mumin_qibla_catalog.dart';
import 'catalogs/mumin_quran_catalog.dart';
import 'mumin_language_registry.dart';

/// Mumin Pro — Unified Domain Catalog Registry.
///
/// Provides one resolution layer for feature-specific translation catalogs.
/// Each feature owns its own translation data, while this registry owns:
/// - Language normalization.
/// - Catalog selection.
/// - Arabic fallback.
/// - Parameter interpolation.
/// - Translation coverage diagnostics.
///
/// Quranic Arabic content is never stored or modified here.
abstract final class MuminDomainCatalogRegistry {
  static const String _quranPrefix = 'quran_';
  static const String _qiblaPrefix = 'qibla_';
  static const String _prayerSettingsPrefix = 'prayer_settings_';
  static const String _calculationPrefix = 'calculation_';

  static String normalizeLanguageCode(String? languageCode) {
    return MuminLanguageRegistry.normalizeLanguageCode(languageCode);
  }

  /// Returns whether a key belongs to a registered domain catalog.
  static bool containsKey(String key) {
    final normalized = key.trim();

    if (normalized.isEmpty) return false;

    if (normalized.startsWith(_quranPrefix)) {
      return MuminQuranCatalog.requiredKeys.contains(normalized);
    }

    if (normalized.startsWith(_qiblaPrefix)) {
      return MuminQiblaCatalog.requiredKeys.contains(normalized);
    }

    if (normalized.startsWith(_prayerSettingsPrefix) ||
        normalized.startsWith(_calculationPrefix)) {
      return MuminPrayerSettingsCatalog.keys.contains(normalized);
    }

    return false;
  }

  /// Resolves a domain key for the selected launch language.
  ///
  /// Returns null when the key does not belong to a domain catalog.
  /// Missing translations in a registered catalog use Arabic fallback.
  static String? resolve(
    String? languageCode,
    String key, {
    Map<String, Object?> parameters =
        const <String, Object?>{},
  }) {
    final normalizedKey = key.trim();

    if (normalizedKey.isEmpty ||
        !containsKey(normalizedKey)) {
      return null;
    }

    final language = normalizeLanguageCode(languageCode);
    final fallbackLanguage =
        MuminLanguageRegistry.fallbackLanguageCode;

    final selectedCatalog = _catalogFor(
      language,
      normalizedKey,
    );

    final fallbackCatalog = _catalogFor(
      fallbackLanguage,
      normalizedKey,
    );

    var value = selectedCatalog?[normalizedKey] ??
        fallbackCatalog?[normalizedKey];

    if (value == null || value.trim().isEmpty) {
      return null;
    }

    for (final entry in parameters.entries) {
      value = value.replaceAll(
        '{${entry.key}}',
        entry.value?.toString() ?? '',
      );
    }

    return value;
  }

  static Map<String, String>? _catalogFor(
    String languageCode,
    String key,
  ) {
    if (key.startsWith(_quranPrefix)) {
      return MuminQuranCatalog.forLanguage(languageCode);
    }

    if (key.startsWith(_qiblaPrefix)) {
      return MuminQiblaCatalog.forLanguage(languageCode);
    }

    if (key.startsWith(_prayerSettingsPrefix) ||
        key.startsWith(_calculationPrefix)) {
      return MuminPrayerSettingsCatalog.forLanguage(
        languageCode,
      );
    }

    return null;
  }

  /// All registered domain keys, without duplicates.
  static Set<String> get allKeys {
    return Set<String>.unmodifiable({
      ...MuminQuranCatalog.requiredKeys,
      ...MuminQiblaCatalog.requiredKeys,
      ...MuminPrayerSettingsCatalog.keys,
    });
  }

  /// Returns whether a key is explicitly translated in a language.
  static bool hasTranslation(
    String? languageCode,
    String key,
  ) {
    final normalizedKey = key.trim();

    if (!containsKey(normalizedKey)) return false;

    final language = normalizeLanguageCode(languageCode);
    final catalog = _catalogFor(language, normalizedKey);

    return catalog?[normalizedKey]?.trim().isNotEmpty == true;
  }

  /// Checks whether every registered domain key is translated.
  static bool isCompleteFor(String? languageCode) {
    final language = normalizeLanguageCode(languageCode);

    return allKeys.every(
      (key) => hasTranslation(language, key),
    );
  }

  /// Returns missing domain keys for one launch language.
  static List<String> missingKeysFor(
    String? languageCode,
  ) {
    final language = normalizeLanguageCode(languageCode);

    return List<String>.unmodifiable(
      allKeys.where(
        (key) => !hasTranslation(language, key),
      ),
    );
  }

  /// Domain catalog coverage for each launch language.
  static Map<String, double> get coverage {
    final keys = allKeys;

    if (keys.isEmpty) {
      return const <String, double>{
        'ar': 1,
        'en': 1,
        'fr': 1,
      };
    }

    return Map<String, double>.unmodifiable({
      for (final language in MuminLanguageRegistry
          .supportedLanguageCodes)
        language: keys
                .where(
                  (key) => hasTranslation(language, key),
                )
                .length /
            keys.length,
    });
  }

  /// Per-language integrity report for launch diagnostics.
  static Map<String, bool> get launchIntegrity {
    return Map<String, bool>.unmodifiable({
      for (final language in MuminLanguageRegistry
          .supportedLanguageCodes)
        language: isCompleteFor(language),
    });
  }
}
