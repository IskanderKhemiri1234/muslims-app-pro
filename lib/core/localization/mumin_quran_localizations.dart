
import 'catalogs/mumin_quran_catalog.dart';
import 'mumin_domain_localizations.dart';
import 'mumin_localizations.dart';

/// Central Quran interface localization bridge.
///
/// Quranic Arabic text is never translated or modified by this bridge.
/// Only reader interface labels and messages are localized.
extension MuminQuranLocalizations on MuminLocalizations {
  /// Resolves a Quran interface string through the unified domain engine.
  String quranText(String key) {
    return domainText(key);
  }

  /// Resolves a Quran interface string with interpolation parameters.
  String quranTextWith(
    String key,
    Map<String, Object?> parameters,
  ) {
    return domainTextWith(key, parameters);
  }

  /// Checks whether a key belongs to the Quran interface catalog.
  bool hasQuranTranslation(String key) {
    return MuminQuranCatalog.requiredKeys.contains(key.trim());
  }

  /// Checks whether the key is explicitly translated in all launch languages.
  bool isQuranTranslationComplete(String key) {
    final normalizedKey = key.trim();

    if (!MuminQuranCatalog.requiredKeys.contains(normalizedKey)) {
      return false;
    }

    return MuminQuranCatalog.launchLanguageCodes.every(
      (code) => MuminQuranCatalog
          .forLanguage(code)[normalizedKey]
          ?.trim()
          .isNotEmpty == true,
    );
  }

  /// Reports whether the active Quran catalog is complete.
  bool get isQuranCatalogComplete {
    return MuminQuranCatalog.isCompleteFor(languageCode);
  }

  /// Exposes Quran catalog integrity for all launch languages.
  Map<String, bool> get quranCatalogIntegrity {
    return MuminQuranCatalog.launchCatalogIntegrity;
  }

  /// Exposes the supported Quran catalog language codes.
  List<String> get quranCatalogLanguageCodes {
    return List<String>.unmodifiable(
      MuminQuranCatalog.launchLanguageCodes,
    );
  }

  /// Exposes the Quran interface translation keys.
  Set<String> get quranTranslationKeys {
    return MuminQuranCatalog.requiredKeys;
  }
}
