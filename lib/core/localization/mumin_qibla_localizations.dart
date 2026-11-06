
import 'catalogs/mumin_qibla_catalog.dart';
import 'mumin_domain_localizations.dart';
import 'mumin_localizations.dart';

/// Backward-compatible Qibla localization bridge.
///
/// All text resolution is delegated to the unified domain registry.
extension MuminQiblaLocalizations on MuminLocalizations {
  String qiblaText(String key) {
    return domainText(key);
  }

  String qiblaTextWith(
    String key,
    Map<String, Object?> parameters,
  ) {
    return domainTextWith(key, parameters);
  }

  bool hasQiblaTranslation(String key) {
    return hasExplicitDomainTranslation(key);
  }

  bool get isQiblaCatalogComplete {
    return MuminQiblaCatalog.isCompleteFor(languageCode);
  }

  Map<String, bool> get qiblaCatalogIntegrity {
    return MuminQiblaCatalog.launchCatalogIntegrity;
  }

  List<String> get qiblaCatalogLanguageCodes {
    return MuminQiblaCatalog.languageCodes;
  }
}
