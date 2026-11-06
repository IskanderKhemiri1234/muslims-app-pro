
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/mumin_domain_catalog_registry.dart';
import '../../../../core/localization/mumin_language_controller.dart';
import '../../../../core/localization/mumin_language_registry.dart';

/// Central localization access for every Quran presentation component.
///
/// This adapter reads the active language from MuminLanguageController
/// and resolves Quran interface strings through the unified domain
/// catalog registry.
///
/// Quranic verses are never translated or modified by this class.
abstract final class QuranPageLocalization {
  /// Returns the active application language code.
  static String languageCodeOf(BuildContext context) {
    return Provider.of<MuminLanguageController>(
      context,
      listen: true,
    ).languageCode;
  }

  /// Resolves a Quran interface string in the active application language.
  ///
  /// Unknown keys are returned unchanged so missing translations remain
  /// visible during development instead of silently showing unrelated text.
  static String text(
    BuildContext context,
    String key, {
    Map<String, Object?> parameters = const <String, Object?>{},
  }) {
    final languageCode = languageCodeOf(context);

    return MuminDomainCatalogRegistry.resolve(
          languageCode,
          key,
          parameters: parameters,
        ) ??
        key;
  }

  /// Resolves a Quran interface string using an explicit language code.
  ///
  /// This method is useful for non-widget services and background logic
  /// that already know the active language.
  static String textForLanguage(
    String languageCode,
    String key, {
    Map<String, Object?> parameters = const <String, Object?>{},
  }) {
    return MuminDomainCatalogRegistry.resolve(
          languageCode,
          key,
          parameters: parameters,
        ) ??
        key;
  }

  /// Returns the canonical display name of a surah.
  ///
  /// Arabic uses the canonical Arabic name.
  /// English and French use the registered transliteration.
  static String surahName(
    BuildContext context,
    int surahNumber,
  ) {
    final languageCode = languageCodeOf(context);

    return MuminDomainCatalogRegistry.surahName(
      surahNumber,
      languageCode: languageCode,
    );
  }

  /// Returns all 114 surah names in the active application language.
  static List<String> surahNames(BuildContext context) {
    final languageCode = languageCodeOf(context);

    return MuminDomainCatalogRegistry.surahNames(
      languageCode: languageCode,
    );
  }

  /// Returns the correct text direction for the active language.
  static TextDirection textDirectionOf(BuildContext context) {
    final languageCode = languageCodeOf(context);

    return MuminLanguageRegistry.isRightToLeft(languageCode)
        ? TextDirection.rtl
        : TextDirection.ltr;
  }

  /// Indicates whether the active language is Arabic.
  static bool isArabic(BuildContext context) {
    return languageCodeOf(context) == 'ar';
  }

  /// Formats a Quran interface value with the active language catalog.
  ///
  /// The caller supplies named parameters such as:
  /// {'page': 12, 'total': 604}
  static String pagePosition(
    BuildContext context, {
    required int page,
    int total = 604,
  }) {
    return text(
      context,
      'quran_page_position',
      parameters: <String, Object?>{
        'page': page,
        'total': total,
      },
    );
  }

  /// Reports whether the Quran surah metadata is structurally valid.
  static bool get hasValidSurahCatalog {
    return MuminDomainCatalogRegistry.surahCatalogIntegrity;
  }

  /// Reports whether the Quran interface catalogs are complete
  /// for all three launch languages.
  static bool get hasCompleteLaunchCatalog {
    return MuminDomainCatalogRegistry.launchIntegrity['ar'] == true &&
        MuminDomainCatalogRegistry.launchIntegrity['en'] == true &&
        MuminDomainCatalogRegistry.launchIntegrity['fr'] == true;
  }
}
