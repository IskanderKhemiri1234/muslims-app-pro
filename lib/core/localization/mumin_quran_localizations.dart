
import 'catalogs/mumin_quran_catalog.dart';
import 'catalogs/mumin_quran_reader_catalog.dart';
import 'mumin_domain_catalog_registry.dart';
import 'mumin_domain_localizations.dart';
import 'mumin_localizations.dart';

/// Central Quran interface localization bridge.
///
/// Only interface labels are localized.
/// Quranic Arabic text is never translated or modified.
extension MuminQuranLocalizations on MuminLocalizations {
  /// Resolves any registered Quran interface key centrally.
  String quranText(String key) {
    return domainText(key);
  }

  /// Resolves a Quran interface key with interpolation.
  String quranTextWith(
    String key,
    Map<String, Object?> parameters,
  ) {
    return domainTextWith(key, parameters);
  }

  /// Checks whether a key belongs to either Quran interface catalog.
  bool hasQuranTranslation(String key) {
    final normalizedKey = key.trim();

    return MuminQuranCatalog.requiredKeys.contains(normalizedKey) ||
        MuminQuranReaderCatalog.requiredKeys.contains(normalizedKey);
  }

  /// Checks explicit translation coverage in all launch languages.
  bool isQuranTranslationComplete(String key) {
    final normalizedKey = key.trim();

    if (!hasQuranTranslation(normalizedKey)) {
      return false;
    }

    return MuminQuranCatalog.launchLanguageCodes.every(
      (code) => MuminDomainCatalogRegistry.hasTranslation(
        code,
        normalizedKey,
      ),
    );
  }

  /// Checks the combined Quran catalogs for the active language.
  bool get isQuranCatalogComplete {
    return quranTranslationKeys.every(
      (key) => MuminDomainCatalogRegistry.hasTranslation(
        languageCode,
        key,
      ),
    );
  }

  /// Combined integrity report for Arabic, English and French.
  Map<String, bool> get quranCatalogIntegrity {
    return Map<String, bool>.unmodifiable({
      for (final code in MuminQuranCatalog.launchLanguageCodes)
        code: quranTranslationKeys.every(
          (key) => MuminDomainCatalogRegistry.hasTranslation(
            code,
            key,
          ),
        ),
    });
  }

  /// Supported Quran catalog language codes.
  List<String> get quranCatalogLanguageCodes {
    return List<String>.unmodifiable(
      MuminQuranCatalog.launchLanguageCodes,
    );
  }

  /// Combined keys from the main Quran and reader catalogs.
  Set<String> get quranTranslationKeys {
    return Set<String>.unmodifiable({
      ...MuminQuranCatalog.requiredKeys,
      ...MuminQuranReaderCatalog.requiredKeys,
    });
  }
}
