
import 'catalogs/mumin_prayer_settings_catalog.dart';
import 'mumin_domain_localizations.dart';
import 'mumin_localizations.dart';

/// Backward-compatible prayer-settings localization bridge.
///
/// All translation resolution is delegated to the unified
/// Mumin domain catalog registry.
extension MuminPrayerSettingsLocalizations
    on MuminLocalizations {
  /// Resolves a prayer-settings translation centrally.
  String prayerSettingsText(String key) {
    return domainText(key);
  }

  /// Resolves a prayer-settings translation with parameters.
  String prayerSettingsTextWith(
    String key,
    Map<String, Object?> parameters,
  ) {
    return domainTextWith(key, parameters);
  }

  /// Checks whether the key belongs to the prayer-settings catalog.
  bool hasPrayerSettingsTranslation(String key) {
    return MuminPrayerSettingsCatalog.keys.contains(key.trim());
  }

  /// Checks whether the key exists in all three launch languages.
  bool isPrayerSettingsTranslationComplete(String key) {
    return MuminPrayerSettingsCatalog.isComplete(key);
  }

  /// Exposes the prayer-settings catalog keys.
  Set<String> get prayerSettingsTranslationKeys {
    return MuminPrayerSettingsCatalog.keys;
  }

  /// Reports whether the active prayer-settings catalog is complete.
  bool get isPrayerSettingsCatalogComplete {
    return MuminPrayerSettingsCatalog.keys.every(
      (key) => hasExplicitDomainTranslation(key),
    );
  }
}
