
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/mumin_domain_catalog_registry.dart';
import '../../../../core/localization/mumin_language_controller.dart';
import '../../../../core/localization/mumin_language_registry.dart';

/// Central localization adapter for Quran presentation.
///
/// This class translates interface messages only.
/// It never translates or modifies Quranic verses or canonical
/// Arabic Quran data.
abstract final class QuranPageLocalization {
  static final RegExp _pageReadPattern =
      RegExp(r'^تم تسجيل قراءة الصفحة (\d+)$');

  static final RegExp _ayahSavedPattern =
      RegExp(r'^تم حفظ الآية (\d+) من سورة (.+)$');

  static String languageCodeOf(BuildContext context) {
    return Provider.of<MuminLanguageController>(
      context,
      listen: true,
    ).languageCode;
  }

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

  /// Converts legacy Arabic feedback identifiers into catalog messages.
  ///
  /// Dynamic values are preserved and passed as interpolation parameters.
  static String feedback(
    BuildContext context,
    String sourceMessage,
  ) {
    final languageCode = languageCodeOf(context);
    final message = sourceMessage.trim();

    final pageMatch = _pageReadPattern.firstMatch(message);

    if (pageMatch != null) {
      return textForLanguage(
        languageCode,
        'quran_page_marked_read',
        parameters: <String, Object?>{
          'page': pageMatch.group(1)!,
        },
      );
    }

    final ayahMatch = _ayahSavedPattern.firstMatch(message);

    if (ayahMatch != null) {
      return textForLanguage(
        languageCode,
        'quran_ayah_saved',
        parameters: <String, Object?>{
          'ayah': ayahMatch.group(1)!,
          'surah': ayahMatch.group(2)!.trim(),
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
      // Unknown messages remain visible until explicitly catalogued.
      return message;
    }

    return textForLanguage(languageCode, key);
  }

  /// Returns the canonical surah name for the selected language.
  static String surahName(
    BuildContext context,
    int surahNumber,
  ) {
    return MuminDomainCatalogRegistry.surahName(
      surahNumber,
      languageCode: languageCodeOf(context),
    );
  }

  static List<String> surahNames(BuildContext context) {
    return MuminDomainCatalogRegistry.surahNames(
      languageCode: languageCodeOf(context),
    );
  }

  static TextDirection textDirectionOf(BuildContext context) {
    return MuminLanguageRegistry.isRightToLeft(
      languageCodeOf(context),
    )
        ? TextDirection.rtl
        : TextDirection.ltr;
  }

  static bool isArabic(BuildContext context) {
    return languageCodeOf(context) == 'ar';
  }

  static bool get hasValidSurahCatalog {
    return MuminDomainCatalogRegistry.surahCatalogIntegrity;
  }

  static bool get hasCompleteLaunchCatalog {
    final integrity = MuminDomainCatalogRegistry.launchIntegrity;

    return integrity['ar'] == true &&
        integrity['en'] == true &&
        integrity['fr'] == true;
  }
}
