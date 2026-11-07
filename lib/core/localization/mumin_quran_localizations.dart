
import 'catalogs/mumin_quran_catalog.dart';
import 'catalogs/mumin_quran_reader_catalog.dart';
import 'mumin_domain_catalog_registry.dart';
import 'mumin_domain_localizations.dart';
import 'mumin_language_registry.dart';
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
  /// in every approved launch language.
  static bool isQuranTranslationComplete(String key) {
    if (!hasQuranTranslation(key)) {
      return false;
    }

    return MuminLanguageRegistry.supportedLanguageCodes.every(
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
    return Map<String, bool>.unmodifiable({
      for (final languageCode
          in MuminLanguageRegistry.supportedLanguageCodes)
        languageCode: isQuranCatalogComplete(languageCode),
    });
  }

  /// Returns all approved launch language codes.
  static List<String> get languageCodes {
    return List<String>.unmodifiable(
      MuminLanguageRegistry.supportedLanguageCodes,
    );
  }

  /// Returns every registered Quran interface key,
  /// including reader-specific keys.
  static Set<String> get quranTranslationKeys {
    return Set<String>.unmodifiable({
      ...MuminQuranCatalog.requiredKeys,
      ...MuminQuranReaderCatalog.requiredKeys,
    });
  }

  /// Checks whether every Quran interface translation is complete
  /// across all approved launch languages.
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
