
import 'catalogs/mumin_prayer_settings_catalog.dart';
import 'mumin_localizations.dart';

/// Prayer-settings localization bridge.
///
/// Keeps the prayer-settings catalog independent while exposing
/// its translations through the central MuminLocalizations instance.
///
/// Resolution order:
/// 1. Active launch language.
/// 2. Arabic domain fallback.
/// 3. Central engine fallback for unknown keys.
extension MuminPrayerSettingsLocalizations
    on MuminLocalizations {
  /// Resolves a prayer-settings translation.
  String prayerSettingsText(String key) {
    final normalizedKey = key.trim();

    if (normalizedKey.isEmpty) {
      return '';
    }

    final selectedCatalog =
        MuminPrayerSettingsCatalog.forLanguage(languageCode);

    final selectedTranslation = selectedCatalog[normalizedKey];

    if (selectedTranslation != null) {
      return selectedTranslation;
    }

    final arabicFallback =
        MuminPrayerSettingsCatalog.ar[normalizedKey];

    if (arabicFallback != null) {
      return arabicFallback;
    }

    return text(normalizedKey);
  }

  /// Checks whether a key belongs to the prayer-settings catalog.
  bool hasPrayerSettingsTranslation(String key) {
    return MuminPrayerSettingsCatalog.keys.contains(
      key.trim(),
    );
  }

  /// Reports whether the key is translated in all launch languages.
  bool isPrayerSettingsTranslationComplete(String key) {
    return MuminPrayerSettingsCatalog.isComplete(key);
  }

  /// Exposes the immutable set of prayer-settings translation keys.
  Set<String> get prayerSettingsTranslationKeys =>
      MuminPrayerSettingsCatalog.keys;
}
