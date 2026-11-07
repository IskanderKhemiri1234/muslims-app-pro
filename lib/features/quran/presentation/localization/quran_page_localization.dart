
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/mumin_domain_catalog_registry.dart';
import '../../../../core/localization/mumin_language_controller.dart';
import '../../../../core/localization/mumin_language_registry.dart';

/// Central localization access for every Quran presentation component.
///
/// Quranic verses and canonical Arabic Quran data are never translated
/// or modified by this adapter.
abstract final class QuranPageLocalization {
  static final RegExp _pageReadPattern =
      RegExp(r'^تم تسجيل قراءة الصفحة (\d+)$');

  /// Returns the active application language code.
  static String languageCodeOf(BuildContext context) {
    return Provider.of<MuminLanguageController>(
      context,
      listen: true,
    ).languageCode;
  }

  /// Resolves a Quran interface string in the active application language.
  static String text(
    BuildContext context,
    String key, {
    Map<String, Object?> parameters = const <String, Object?>{},
  }) {
    return textForLanguage(
      languageCodeOf(context),
      key,
      parameters: parameters,
    );
  }

  /// Resolves a Quran interface string using an explicit language code.
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

  /// Localizes legacy Quran feedback messages without changing
  /// the reading, bookmark, or progress operations that produce them.
  ///
  /// The source strings are used only as compatibility identifiers.
  /// Displayed text always comes from the central Quran catalogs.
  static String feedback(
    BuildContext context,
    String sourceMessage,
  ) {
    final languageCode = languageCodeOf(context);
    final message = sourceMessage.trim();

    final pageReadMatch = _pageReadPattern.firstMatch(message);

    if (pageReadMatch != null) {
      return textForLanguage(
        languageCode,
        'quran_page_marked_read',
        parameters: <String, Object?>{
          'page': pageReadMatch.group(1)!,
        },
      );
    }

    const messageKeys = <String, String>{
      'تعذر تحميل بيانات القراءة المحفوظة':
          'quran_saved_reading_data_error',
      'تعذر تحديث الورد اليومي':
          'quran_daily_reading_update_error',
      'تعذر حفظ موضع القراءة':
          'quran_reading_position_save_error',
      'تعذر حفظ تقدم القراءة. حاول مرة أخرى.':
          'quran_page_mark_read_error',
      'تم إلغاء تسجيل قراءة الصفحة':
          'quran_page_read_mark_removed',
      'تعذر تحديث سجل القراءة':
          'quran_reading_record_update_error',
      'بيانات الآية غير صالحة':
          'quran_invalid_ayah_data',
      'هذه الآية محفوظة بالفعل':
          'quran_ayah_already_saved',
      'تعذر حفظ الآية':
          'quran_ayah_save_error',
      'تم حذف علامة الآية':
          'quran_ayah_bookmark_removed',
      'تعذر حذف علامة الآية':
          'quran_ayah_bookmark_remove_error',
      'تم حفظ الصفحة في العلامات المرجعية':
          'quran_page_bookmark_saved',
      'تم حذف العلامة المرجعية':
          'quran_page_bookmark_removed',
      'تعذر حفظ العلامة المرجعية':
          'quran_page_bookmark_save_error',
      'تعذر حذف العلامة المرجعية':
          'quran_page_bookmark_remove_error',
    };

    final key = messageKeys[message];

    if (key == null) {
      // Do not silently replace an unknown message with an unrelated
      // translation. Keep it visible so it can be catalogued correctly.
      return message;
    }

    return textForLanguage(languageCode, key);
  }

  /// Returns the canonical display name of a surah.
  ///
  /// Arabic uses the canonical Arabic name.
  /// English and French use the registered transliteration.
  static String surahName(
    BuildContext context,
    int surahNumber,
  ) {
    return MuminDomainCatalogRegistry.surahName(
      surahNumber,
      languageCode: languageCodeOf(context),
    );
  }

  /// Returns all 114 surah names in the active application language.
  static List<String> surahNames(BuildContext context) {
    return MuminDomainCatalogRegistry.surahNames(
      languageCode: languageCodeOf(context),
    );
  }

  /// Returns the correct text direction for the active language.
  static TextDirection textDirectionOf(BuildContext context) {
    return MuminLanguageRegistry.isRightToLeft(
      languageCodeOf(context),
    )
        ? TextDirection.rtl
        : TextDirection.ltr;
  }

  /// Indicates whether the active language is Arabic.
  static bool isArabic(BuildContext context) {
    return languageCodeOf(context) == 'ar';
  }

  /// Formats a Quran interface page position.
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
    final integrity = MuminDomainCatalogRegistry.launchIntegrity;

    return integrity['ar'] == true &&
        integrity['en'] == true &&
        integrity['fr'] == true;
  }
}
