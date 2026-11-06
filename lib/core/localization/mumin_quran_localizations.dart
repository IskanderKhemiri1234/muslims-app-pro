import 'catalogs/mumin_quran_catalog.dart';
import 'catalogs/mumin_quran_reader_catalog.dart';
import 'mumin_domain_catalog_registry.dart';
import 'mumin_domain_localizations.dart';
import 'mumin_localizations.dart';

/// Central localization bridge for the complete Quran feature.
///
/// All Quran interface translations are resolved through the unified
/// domain catalog registry. This keeps Quran UI independent from
/// individual translation maps and supports future language expansion.
abstract final class MuminQuranLocalizations {
  /// Resolves a Quran translation using the active central language.
  static String quranText(
    MuminLocalizations localizations,
    String key,
  ) {
    return localizations.domainText(key);
  }

  /// Resolves a Quran translation and interpolates its parameters.
  static String quranTextWith(
    MuminLocalizations localizations,
    String key,
    Map<String, String> parameters,
  ) {
    return localizations.domainTextWith(key, parameters);
  }

  /// Checks whether a Quran key belongs to the registered Quran catalogs.
  static bool hasQuranTranslation(String key) {
    return MuminQuranCatalog.requiredKeys.contains(key) ||
        MuminQuranReaderCatalog.requiredKeys.contains(key);
  }

  /// Checks whether a Quran key has an explicit translation
  /// in every launch language.
  static bool isQuranTranslationComplete(String key) {
    if (!hasQuranTranslation(key)) {
      return false;
    }

    return MuminLanguageRegistry.launchLanguageCodes.every(
      (languageCode) => MuminDomainCatalogRegistry.hasTranslation(
        languageCode,
        key,
      ),
    );
  }

  /// Checks the complete Quran catalog for one language.
  static bool isQuranCatalogComplete(String languageCode) {
    return quranTranslationKeys.every(
      (key) => MuminDomainCatalogRegistry.hasTranslation(
        languageCode,
        key,
      ),
    );
  }

  /// Returns the translation integrity status for all launch languages.
  static Map<String, bool> get quranCatalogIntegrity {
    return Map.unmodifiable({
      for (final languageCode
          in MuminLanguageRegistry.launchLanguageCodes)
        languageCode: isQuranCatalogComplete(languageCode),
    });
  }

  /// Returns all launch language codes.
  static List<String> get languageCodes {
    return List.unmodifiable(
      MuminLanguageRegistry.launchLanguageCodes,
    );
  }

  /// Returns every registered Quran interface key,
  /// including reader-specific keys.
  static Set<String> get quranTranslationKeys {
    return Set.unmodifiable({
      ...MuminQuranCatalog.requiredKeys,
      ...MuminQuranReaderCatalog.requiredKeys,
    });
  }

  /// Checks whether every Quran interface translation is complete
  /// across the three launch languages.
  static bool get isQuranCatalogCompleteForLaunch {
    return languageCodes.every(isQuranCatalogComplete);
  }

  /// Returns Quran translation coverage for one launch language.
  static double quranTranslationCoverage(String languageCode) {
    final keys = quranTranslationKeys;

    if (keys.isEmpty) {
      return 1;
    }

    final translatedCount = keys
        .where(
          (key) => MuminDomainCatalogRegistry.hasTranslation(
            languageCode,
            key,
          ),
        )
        .length;

    return translatedCount / keys.length;
  }
}
