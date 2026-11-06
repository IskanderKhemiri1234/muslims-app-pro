
import 'catalogs/mumin_qibla_catalog.dart';
import 'mumin_localizations.dart';

/// Provides the Qibla Atlas catalog through the active central locale.
///
/// Feature widgets should use this extension instead of maintaining
/// their own Arabic/English/French translation maps.
extension MuminQiblaLocalizations on MuminLocalizations {
  String qiblaText(String key) {
    return MuminQiblaCatalog.text(languageCode, key);
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
