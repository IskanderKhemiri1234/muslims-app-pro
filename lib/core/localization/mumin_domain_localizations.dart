
import 'mumin_domain_catalog_registry.dart';
import 'mumin_localizations.dart';

/// Unified access point for feature-specific localization catalogs.
///
/// Features should use this extension instead of importing individual
/// domain catalogs directly.
///
/// Resolution:
/// 1. Registered domain catalog.
/// 2. Arabic fallback handled by the domain registry.
/// 3. Existing central application localization engine.
extension MuminDomainLocalizations on MuminLocalizations {
  /// Resolves a domain key, falling back to the central app catalog.
  String domainText(String key) {
    return MuminDomainCatalogRegistry.resolve(
          languageCode,
          key,
        ) ??
        text(key);
  }

  /// Resolves a domain key with named parameter interpolation.
  String domainTextWith(
    String key,
    Map<String, Object?> parameters,
  ) {
    return MuminDomainCatalogRegistry.resolve(
          languageCode,
          key,
          parameters: parameters,
        ) ??
        textWith(key, parameters);
  }

  /// Checks whether the key belongs to a registered feature catalog.
  bool hasDomainKey(String key) {
    return MuminDomainCatalogRegistry.containsKey(key);
  }

  /// Checks whether the active language has an explicit translation.
  ///
  /// Arabic fallback does not count as a translation in another language.
  bool hasExplicitDomainTranslation(String key) {
    return MuminDomainCatalogRegistry.hasTranslation(
      languageCode,
      key,
    );
  }

  /// Reports whether every registered domain key is translated.
  bool get areDomainCatalogsComplete {
    return MuminDomainCatalogRegistry.isCompleteFor(
      languageCode,
    );
  }

  /// Returns untranslated domain keys for the active language.
  List<String> get missingDomainTranslationKeys {
    return MuminDomainCatalogRegistry.missingKeysFor(
      languageCode,
    );
  }

  /// Translation coverage across all registered feature catalogs.
  static Map<String, double> get domainTranslationCoverage {
    return MuminDomainCatalogRegistry.coverage;
  }

  /// Per-language launch catalog integrity.
  static Map<String, bool> get domainLaunchIntegrity {
    return MuminDomainCatalogRegistry.launchIntegrity;
  }
}
