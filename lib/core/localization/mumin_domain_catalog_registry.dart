
import 'catalogs/mumin_prayer_settings_catalog.dart';
import 'catalogs/mumin_qibla_catalog.dart';
import 'catalogs/mumin_quran_catalog.dart';
import 'catalogs/mumin_quran_reader_catalog.dart';
import 'catalogs/mumin_quran_surah_catalog.dart';
import 'mumin_language_registry.dart';

/// Mumin Pro — Unified Domain Catalog Registry.
///
/// Owns domain catalog selection, language normalization,
/// Arabic fallback, interpolation and translation diagnostics.
///
/// Quranic Arabic verses are never stored or modified here.
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
      return MuminQuranCatalog.requiredKeys.contains(normalized) ||
          MuminQuranReaderCatalog.requiredKeys.contains(normalized);
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

  /// Resolves a registered domain key for the selected language.
  ///
  /// Missing selected-language entries fall back to Arabic.
  /// Returns null when the key is unknown or has no usable value.
  static String? resolve(
    String? languageCode,
    String key, {
    Map<String, Object?> parameters = const <String, Object?>{},
  }) {
    final normalizedKey = key.trim();

    if (normalizedKey.isEmpty || !containsKey(normalizedKey)) {
      return null;
    }

    final language = normalizeLanguageCode(languageCode);
    final fallbackLanguage =
        MuminLanguageRegistry.fallbackLanguageCode;

    final selectedCatalog = _catalogFor(language, normalizedKey);
    final fallbackCatalog = _catalogFor(
      fallbackLanguage,
      normalizedKey,
    );

    final resolvedValue = selectedCatalog?[normalizedKey] ??
        fallbackCatalog?[normalizedKey];

    if (resolvedValue == null || resolvedValue.trim().isEmpty) {
      return null;
    }

    var value = resolvedValue;

    for (final entry in parameters.entries) {
      value = value.replaceAll(
        '{${entry.key}}',
        entry.value?.toString() ?? '',
      );
    }

    return value;
  }

  /// Resolves the canonical name of a Quran surah.
  ///
  /// Surah metadata is separate from interface translation catalogs.
  static String surahName(
    int surahNumber, {
    String? languageCode,
  }) {
    return MuminQuranSurahCatalog.nameFor(
      surahNumber,
      languageCode: normalizeLanguageCode(languageCode),
    );
  }

  /// Returns all 114 surah names in the requested language.
  static List<String> surahNames({
    String? languageCode,
  }) {
    return MuminQuranSurahCatalog.namesFor(
      normalizeLanguageCode(languageCode),
    );
  }

  /// Checks the integrity of the canonical surah metadata.
  static bool get surahCatalogIntegrity =>
      MuminQuranSurahCatalog.hasValidData;

  /// Combines the two Quran interface catalogs into one domain.
  ///
  /// The reader catalog adds interface keys without replacing
  /// existing Quran catalog entries.
  static Map<String, String>? _catalogFor(
    String languageCode,
    String key,
  ) {
    if (key.startsWith(_quranPrefix)) {
      return <String, String>{
        ...MuminQuranCatalog.forLanguage(languageCode),
        ...MuminQuranReaderCatalog.forLanguage(languageCode),
      };
    }

    if (key.startsWith(_qiblaPrefix)) {
      return MuminQiblaCatalog.forLanguage(languageCode);
    }

    if (key.startsWith(_prayerSettingsPrefix) ||
        key.startsWith(_calculationPrefix)) {
      return MuminPrayerSettingsCatalog.forLanguage(languageCode);
    }

    return null;
  }

  /// All registered domain keys, without duplicates.
  static Set<String> get allKeys {
    return Set<String>.unmodifiable({
      ...MuminQuranCatalog.requiredKeys,
      ...MuminQuranReaderCatalog.requiredKeys,
      ...MuminQiblaCatalog.requiredKeys,
      ...MuminPrayerSettingsCatalog.keys,
    });
  }

  /// Checks whether a key has an explicit translation.
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

  /// Checks whether every registered key is translated.
  static bool isCompleteFor(String? languageCode) {
    final language = normalizeLanguageCode(languageCode);

    return allKeys.every(
      (key) => hasTranslation(language, key),
    );
  }

  /// Returns missing keys for one launch language.
  static List<String> missingKeysFor(String? languageCode) {
    final language = normalizeLanguageCode(languageCode);

    return List<String>.unmodifiable(
      allKeys.where(
        (key) => !hasTranslation(language, key),
      ),
    );
  }

  /// Translation coverage for every registered launch language.
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
      for (final language
          in MuminLanguageRegistry.supportedLanguageCodes)
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
      for (final language
          in MuminLanguageRegistry.supportedLanguageCodes)
        language: isCompleteFor(language),
    });
  }
}
