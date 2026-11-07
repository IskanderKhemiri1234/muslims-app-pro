
/// Central Quran interface catalog for Mumin Pro.
///
/// Interface labels and feedback messages only.
/// Never store, translate, or modify Quranic verses here.
abstract final class MuminQuranCatalog {
  static const String defaultLanguageCode = 'ar';

  static const Map<String, Map<String, String>> _catalogs = {
    'ar': {
      'quran_title': 'القرآن الكريم',
      'quran_madinah_mushaf': 'مصحف المدينة المنورة',
      'quran_page': 'الصفحة',
      'quran_of': 'من',
      'quran_daily_reading': 'الورد اليومي',
      'quran_daily_target': 'الهدف اليومي',
      'quran_pages': 'صفحات',
      'quran_pages_read': 'صفحات مقروءة',
      'quran_continue_reading': 'متابعة القراءة',
      'quran_last_read_position': 'آخر موضع قراءة',
      'quran_reading_progress': 'تقدم القراءة',
      'quran_khatma_progress': 'تقدم الختمة',
      'quran_completed_khatmas': 'الختمات المكتملة',
      'quran_khatma': 'ختمة',
      'quran_khatma_completed_title': 'مبارك! أتممت ختمة القرآن',
      'quran_khatma_completed_message':
          'الحمد لله، أتممت قراءة صفحات المصحف الـ604. هذه ختمتك رقم {count}.',
      'quran_praise_allah': 'الحمد لله',
      'quran_mark_page_read': 'هل أتممت قراءة هذه الصفحة؟',
      'quran_page_read': 'تم تسجيل قراءة هذه الصفحة',
      'quran_mark_read': 'تسجيل',
      'quran_undo': 'تراجع',
      'quran_previous_page': 'الصفحة السابقة',
      'quran_next_page': 'الصفحة التالية',
      'quran_previous': 'السابقة',
      'quran_next': 'التالية',
      'quran_bookmark': 'حفظ الصفحة',
      'quran_remove_bookmark': 'إزالة العلامة',
      'quran_bookmarks': 'العلامات المرجعية',
      'quran_saved_verses': 'الآيات المحفوظة',
      'quran_save_verse': 'حفظ الآية',
      'quran_save': 'حفظ',
      'quran_index': 'الفهرس',
      'quran_verses': 'الآيات',
      'quran_go_to_page': 'انتقال',
      'quran_go_to_page_title': 'الانتقال إلى صفحة',
      'quran_enter_page_number': 'أدخل رقم الصفحة',
      'quran_open_reader': 'اضغط لفتح صفحة القرآن كاملة',
      'quran_hide_reading_controls': 'إخفاء أدوات القراءة',
      'quran_show_reading_controls': 'إظهار أدوات القراءة',
      'quran_back': 'العودة',
      'quran_close': 'إغلاق',
      'quran_empty_bookmarks': 'لا توجد علامات مرجعية محفوظة بعد.',
      'quran_empty_verse_bookmarks': 'لا توجد آيات محفوظة بعد.',
      'quran_bookmark_already_exists': 'هذه الصفحة محفوظة بالفعل.',
      'quran_verse_already_exists': 'هذه الآية محفوظة بالفعل.',
      'quran_invalid_verse': 'بيانات الآية غير صالحة.',
      'quran_invalid_page': 'رقم الصفحة غير صالح.',
      'quran_loading_error': 'تعذر تحميل بيانات القراءة المحفوظة.',
      'quran_progress_save_error':
          'تعذر حفظ تقدم القراءة. حاول مرة أخرى.',
      'quran_progress_update_error': 'تعذر تحديث سجل القراءة.',
      'quran_daily_update_error': 'تعذر تحديث الورد اليومي.',
      'quran_position_save_error': 'تعذر حفظ موضع القراءة.',
      'quran_verse_save_error': 'تعذر حفظ الآية.',
      'quran_verse_remove_error': 'تعذر إزالة الآية المحفوظة.',
      'quran_page_saved': 'تم تسجيل قراءة الصفحة {page}.',
      'quran_page_read_undone': 'تم إلغاء تسجيل قراءة الصفحة.',
      'quran_verse_saved': 'تم حفظ الآية {ayah} من سورة {surah}.',
      'quran_no_translation':
          'ترجمة معاني القرآن غير متاحة بهذه اللغة حالياً.',
      'quran_translation_label': 'ترجمة معاني القرآن',
      'quran_translation_disclaimer':
          'النص المعروض ترجمة لمعاني الآيات وليس بديلاً عن النص القرآني العربي.',
      'quran_tafsir': 'التفسير',
      'quran_tafsir_unavailable': 'التفسير غير متاح لهذه الآية حالياً.',

      // Quran page feedback.
      'quran_saved_reading_data_error':
          'تعذر تحميل بيانات القراءة المحفوظة.',
      'quran_daily_reading_update_error':
          'تعذر تحديث الورد اليومي.',
      'quran_reading_position_save_error':
          'تعذر حفظ موضع القراءة.',
      'quran_page_marked_read': 'تم تسجيل قراءة الصفحة {page}.',
      'quran_page_mark_read_error':
          'تعذر حفظ تقدم القراءة. حاول مرة أخرى.',
      'quran_page_read_mark_removed': 'تم إلغاء تسجيل قراءة الصفحة.',
      'quran_reading_record_update_error':
          'تعذر تحديث سجل القراءة.',
      'quran_khatma_congratulations':
          'مبارك! أتممت ختمة القرآن',
      'quran_khatma_completion_message':
          'الحمد لله، أتممت قراءة صفحات المصحف الـ604. هذه ختمتك رقم {count}.',
      'quran_invalid_ayah_data': 'بيانات الآية غير صالحة.',
      'quran_ayah_already_saved': 'هذه الآية محفوظة بالفعل.',
      'quran_ayah_saved':
          'تم حفظ الآية {ayah} من سورة {surah}.',
      'quran_ayah_save_error': 'تعذر حفظ الآية.',
      'quran_ayah_bookmark_removed': 'تم حذف علامة الآية.',
      'quran_ayah_bookmark_remove_error':
          'تعذر حذف علامة الآية.',
      'quran_page_bookmark_saved':
          'تم حفظ الصفحة في العلامات المرجعية.',
      'quran_page_bookmark_removed':
          'تم حذف العلامة المرجعية.',
      'quran_page_bookmark_save_error':
          'تعذر حفظ العلامة المرجعية.',
      'quran_page_bookmark_remove_error':
          'تعذر حذف العلامة المرجعية.',
    },

    'en': {
      'quran_title': 'The Holy Quran',
      'quran_madinah_mushaf': 'Madinah Mushaf',
      'quran_page': 'Page',
      'quran_of': 'of',
      'quran_daily_reading': 'Daily reading',
      'quran_daily_target': 'Daily target',
      'quran_pages': 'pages',
      'quran_pages_read': 'Pages read',
      'quran_continue_reading': 'Continue reading',
      'quran_last_read_position': 'Last reading position',
      'quran_reading_progress': 'Reading progress',
      'quran_khatma_progress': 'Khatm progress',
      'quran_completed_khatmas': 'Completed khatms',
      'quran_khatma': 'Khatm',
      'quran_khatma_completed_title': 'Congratulations! Quran completed',
      'quran_khatma_completed_message':
          'Alhamdulillah, you completed all 604 Mushaf pages. This is your khatm number {count}.',
      'quran_praise_allah': 'Alhamdulillah',
      'quran_mark_page_read': 'Have you finished reading this page?',
      'quran_page_read': 'This page is marked as read',
      'quran_mark_read': 'Mark read',
      'quran_undo': 'Undo',
      'quran_previous_page': 'Previous page',
      'quran_next_page': 'Next page',
      'quran_previous': 'Previous',
      'quran_next': 'Next',
      'quran_bookmark': 'Save page',
      'quran_remove_bookmark': 'Remove bookmark',
      'quran_bookmarks': 'Bookmarks',
      'quran_saved_verses': 'Saved verses',
      'quran_save_verse': 'Save verse',
      'quran_save': 'Save',
      'quran_index': 'Index',
      'quran_verses': 'Verses',
      'quran_go_to_page': 'Go to',
      'quran_go_to_page_title': 'Go to page',
      'quran_enter_page_number': 'Enter page number',
      'quran_open_reader': 'Tap to open the full Quran page',
      'quran_hide_reading_controls': 'Hide reading controls',
      'quran_show_reading_controls': 'Show reading controls',
      'quran_back': 'Back',
      'quran_close': 'Close',
      'quran_empty_bookmarks': 'No bookmarks have been saved yet.',
      'quran_empty_verse_bookmarks': 'No verses have been saved yet.',
      'quran_bookmark_already_exists': 'This page is already bookmarked.',
      'quran_verse_already_exists': 'This verse is already saved.',
      'quran_invalid_verse': 'The verse information is invalid.',
      'quran_invalid_page': 'The page number is invalid.',
      'quran_loading_error': 'Unable to load your saved reading data.',
      'quran_progress_save_error':
          'Unable to save reading progress. Please try again.',
      'quran_progress_update_error': 'Unable to update the reading record.',
      'quran_daily_update_error': 'Unable to update the daily reading target.',
      'quran_position_save_error': 'Unable to save the reading position.',
      'quran_verse_save_error': 'Unable to save the verse.',
      'quran_verse_remove_error': 'Unable to remove the saved verse.',
      'quran_page_saved': 'Page {page} marked as read.',
      'quran_page_read_undone': 'The page reading mark was removed.',
      'quran_verse_saved': 'Verse {ayah} from Surah {surah} was saved.',
      'quran_no_translation':
          'A Quran meaning translation is not currently available in this language.',
      'quran_translation_label': 'Quran meaning translation',
      'quran_translation_disclaimer':
          'This is a translation of the meanings, not a replacement for the Arabic Quranic text.',
      'quran_tafsir': 'Tafsir',
      'quran_tafsir_unavailable':
          'Tafsir is not currently available for this verse.',

      // Quran page feedback.
      'quran_saved_reading_data_error':
          'Unable to load your saved reading data.',
      'quran_daily_reading_update_error':
          'Unable to update the daily reading target.',
      'quran_reading_position_save_error':
          'Unable to save the reading position.',
      'quran_page_marked_read': 'Page {page} marked as read.',
      'quran_page_mark_read_error':
          'Unable to save reading progress. Please try again.',
      'quran_page_read_mark_removed':
          'The page reading mark was removed.',
      'quran_reading_record_update_error':
          'Unable to update the reading record.',
      'quran_khatma_congratulations':
          'Congratulations! You completed the Quran.',
      'quran_khatma_completion_message':
          'Alhamdulillah, you completed all 604 Mushaf pages. This is your khatm number {count}.',
      'quran_invalid_ayah_data': 'The verse information is invalid.',
      'quran_ayah_already_saved': 'This verse is already saved.',
      'quran_ayah_saved':
          'Verse {ayah} from Surah {surah} was saved.',
      'quran_ayah_save_error': 'Unable to save the verse.',
      'quran_ayah_bookmark_removed': 'The verse bookmark was removed.',
      'quran_ayah_bookmark_remove_error':
          'Unable to remove the verse bookmark.',
      'quran_page_bookmark_saved':
          'Page added to bookmarks.',
      'quran_page_bookmark_removed':
          'The page bookmark was removed.',
      'quran_page_bookmark_save_error':
          'Unable to save the page bookmark.',
      'quran_page_bookmark_remove_error':
          'Unable to remove the page bookmark.',
    },

    'fr': {
      'quran_title': 'Le Saint Coran',
      'quran_madinah_mushaf': 'Mushaf de Médine',
      'quran_page': 'Page',
      'quran_of': 'sur',
      'quran_daily_reading': 'Lecture quotidienne',
      'quran_daily_target': 'Objectif quotidien',
      'quran_pages': 'pages',
      'quran_pages_read': 'Pages lues',
      'quran_continue_reading': 'Continuer la lecture',
      'quran_last_read_position': 'Dernière position de lecture',
      'quran_reading_progress': 'Progression de lecture',
      'quran_khatma_progress': 'Progression de la lecture complète',
      'quran_completed_khatmas': 'Lectures complètes terminées',
      'quran_khatma': 'Lecture complète',
      'quran_khatma_completed_title': 'Félicitations ! Coran terminé',
      'quran_khatma_completed_message':
          'Alhamdulillah, vous avez lu les 604 pages du Mushaf. Ceci est votre lecture complète numéro {count}.',
      'quran_praise_allah': 'Alhamdulillah',
      'quran_mark_page_read': 'Avez-vous terminé la lecture de cette page ?',
      'quran_page_read': 'La lecture de cette page est enregistrée',
      'quran_mark_read': 'Enregistrer',
      'quran_undo': 'Annuler',
      'quran_previous_page': 'Page précédente',
      'quran_next_page': 'Page suivante',
      'quran_previous': 'Précédente',
      'quran_next': 'Suivante',
      'quran_bookmark': 'Enregistrer la page',
      'quran_remove_bookmark': 'Supprimer le signet',
      'quran_bookmarks': 'Signets',
      'quran_saved_verses': 'Versets enregistrés',
      'quran_save_verse': 'Enregistrer le verset',
      'quran_save': 'Enregistrer',
      'quran_index': 'Index',
      'quran_verses': 'Versets',
      'quran_go_to_page': 'Aller à',
      'quran_go_to_page_title': 'Aller à la page',
      'quran_enter_page_number': 'Saisir le numéro de page',
      'quran_open_reader': 'Touchez pour ouvrir la page complète du Coran',
      'quran_hide_reading_controls': 'Masquer les commandes de lecture',
      'quran_show_reading_controls': 'Afficher les commandes de lecture',
      'quran_back': 'Retour',
      'quran_close': 'Fermer',
      'quran_empty_bookmarks': 'Aucun signet enregistré pour le moment.',
      'quran_empty_verse_bookmarks': 'Aucun verset enregistré pour le moment.',
      'quran_bookmark_already_exists': 'Cette page est déjà enregistrée.',
      'quran_verse_already_exists': 'Ce verset est déjà enregistré.',
      'quran_invalid_verse': 'Les informations du verset sont invalides.',
      'quran_invalid_page': 'Le numéro de page est invalide.',
      'quran_loading_error':
          'Impossible de charger les données de lecture enregistrées.',
      'quran_progress_save_error':
          'Impossible d’enregistrer la progression. Veuillez réessayer.',
      'quran_progress_update_error':
          'Impossible de mettre à jour l’historique de lecture.',
      'quran_daily_update_error':
          'Impossible de mettre à jour l’objectif quotidien.',
      'quran_position_save_error':
          'Impossible d’enregistrer la position de lecture.',
      'quran_verse_save_error': 'Impossible d’enregistrer le verset.',
      'quran_verse_remove_error':
          'Impossible de supprimer le verset enregistré.',
      'quran_page_saved': 'Page {page} marquée comme lue.',
      'quran_page_read_undone': 'Le statut de lecture de la page a été annulé.',
      'quran_verse_saved':
          'Le verset {ayah} de la sourate {surah} a été enregistré.',
      'quran_no_translation':
          'La traduction du sens du Coran n’est pas disponible dans cette langue pour le moment.',
      'quran_translation_label': 'Traduction du sens du Coran',
      'quran_translation_disclaimer':
          'Il s’agit d’une traduction du sens des versets, et non d’un remplacement du texte coranique arabe.',
      'quran_tafsir': 'Tafsir',
      'quran_tafsir_unavailable':
          'Le tafsir n’est pas disponible pour ce verset pour le moment.',

      // Quran page feedback.
      'quran_saved_reading_data_error':
          'Impossible de charger les données de lecture enregistrées.',
      'quran_daily_reading_update_error':
          'Impossible de mettre à jour l’objectif quotidien.',
      'quran_reading_position_save_error':
          'Impossible d’enregistrer la position de lecture.',
      'quran_page_marked_read': 'Page {page} marquée comme lue.',
      'quran_page_mark_read_error':
          'Impossible d’enregistrer la progression. Veuillez réessayer.',
      'quran_page_read_mark_removed':
          'Le statut de lecture de la page a été annulé.',
      'quran_reading_record_update_error':
          'Impossible de mettre à jour l’historique de lecture.',
      'quran_khatma_congratulations':
          'Félicitations ! Vous avez terminé le Coran.',
      'quran_khatma_completion_message':
          'Alhamdulillah, vous avez lu les 604 pages du Mushaf. Ceci est votre lecture complète numéro {count}.',
      'quran_invalid_ayah_data': 'Les informations du verset sont invalides.',
      'quran_ayah_already_saved': 'Ce verset est déjà enregistré.',
      'quran_ayah_saved':
          'Le verset {ayah} de la sourate {surah} a été enregistré.',
      'quran_ayah_save_error': 'Impossible d’enregistrer le verset.',
      'quran_ayah_bookmark_removed':
          'Le signet du verset a été supprimé.',
      'quran_ayah_bookmark_remove_error':
          'Impossible de supprimer le signet du verset.',
      'quran_page_bookmark_saved':
          'Page ajoutée aux signets.',
      'quran_page_bookmark_removed':
          'Le signet de la page a été supprimé.',
      'quran_page_bookmark_save_error':
          'Impossible d’enregistrer le signet de la page.',
      'quran_page_bookmark_remove_error':
          'Impossible de supprimer le signet de la page.',
    },
  };

  static const Set<String> requiredKeys = {
    'quran_title',
    'quran_madinah_mushaf',
    'quran_page',
    'quran_of',
    'quran_daily_reading',
    'quran_daily_target',
    'quran_pages',
    'quran_pages_read',
    'quran_continue_reading',
    'quran_last_read_position',
    'quran_reading_progress',
    'quran_khatma_progress',
    'quran_completed_khatmas',
    'quran_khatma',
    'quran_khatma_completed_title',
    'quran_khatma_completed_message',
    'quran_praise_allah',
    'quran_mark_page_read',
    'quran_page_read',
    'quran_mark_read',
    'quran_undo',
    'quran_previous_page',
    'quran_next_page',
    'quran_previous',
    'quran_next',
    'quran_bookmark',
    'quran_remove_bookmark',
    'quran_bookmarks',
    'quran_saved_verses',
    'quran_save_verse',
    'quran_save',
    'quran_index',
    'quran_verses',
    'quran_go_to_page',
    'quran_go_to_page_title',
    'quran_enter_page_number',
    'quran_open_reader',
    'quran_hide_reading_controls',
    'quran_show_reading_controls',
    'quran_back',
    'quran_close',
    'quran_empty_bookmarks',
    'quran_empty_verse_bookmarks',
    'quran_bookmark_already_exists',
    'quran_verse_already_exists',
    'quran_invalid_verse',
    'quran_invalid_page',
    'quran_loading_error',
    'quran_progress_save_error',
    'quran_progress_update_error',
    'quran_daily_update_error',
    'quran_position_save_error',
    'quran_verse_save_error',
    'quran_verse_remove_error',
    'quran_page_saved',
    'quran_page_read_undone',
    'quran_verse_saved',
    'quran_no_translation',
    'quran_translation_label',
    'quran_translation_disclaimer',
    'quran_tafsir',
    'quran_tafsir_unavailable',
    'quran_saved_reading_data_error',
    'quran_daily_reading_update_error',
    'quran_reading_position_save_error',
    'quran_page_marked_read',
    'quran_page_mark_read_error',
    'quran_page_read_mark_removed',
    'quran_reading_record_update_error',
    'quran_khatma_congratulations',
    'quran_khatma_completion_message',
    'quran_invalid_ayah_data',
    'quran_ayah_already_saved',
    'quran_ayah_saved',
    'quran_ayah_save_error',
    'quran_ayah_bookmark_removed',
    'quran_ayah_bookmark_remove_error',
    'quran_page_bookmark_saved',
    'quran_page_bookmark_removed',
    'quran_page_bookmark_save_error',
    'quran_page_bookmark_remove_error',
  };

  static const List<String> launchLanguageCodes = [
    'ar',
    'en',
    'fr',
  ];

  static Map<String, String> forLanguage(String languageCode) {
    final normalized = _normalizeLanguageCode(languageCode);
    return _catalogs[normalized] ?? _catalogs[defaultLanguageCode]!;
  }

  static String text(
    String languageCode,
    String key, {
    Map<String, String> parameters = const {},
  }) {
    final normalizedKey = key.trim();
    if (normalizedKey.isEmpty) return '';

    final selected = forLanguage(languageCode);
    final fallback = _catalogs[defaultLanguageCode]!;

    var value = selected[normalizedKey] ?? fallback[normalizedKey];
    if (value == null) return normalizedKey;

    for (final entry in parameters.entries) {
      value = value.replaceAll(
        '{${entry.key}}',
        entry.value,
      );
    }

    return value;
  }

  static bool isCompleteFor(String languageCode) {
    final normalized = _normalizeLanguageCode(languageCode);
    final catalog = _catalogs[normalized];
    if (catalog == null) return false;

    return requiredKeys.every(
      (key) => catalog[key]?.trim().isNotEmpty == true,
    );
  }

  static Map<String, bool> get launchCatalogIntegrity {
    return Map<String, bool>.unmodifiable({
      for (final code in launchLanguageCodes)
        code: isCompleteFor(code),
    });
  }

  static Map<String, int> get missingTranslationCounts {
    return Map<String, int>.unmodifiable({
      for (final code in launchLanguageCodes)
        code: requiredKeys
            .where((key) => _catalogs[code]?[key]?.trim().isNotEmpty != true)
            .length,
    });
  }

  static List<String> get missingKeysFor(String languageCode) {
    final normalized = _normalizeLanguageCode(languageCode);
    final catalog = _catalogs[normalized]!;
    return List<String>.unmodifiable(
      requiredKeys.where(
        (key) => catalog[key]?.trim().isNotEmpty != true,
      ),
    );
  }

  static String _normalizeLanguageCode(String languageCode) {
    final normalized = languageCode.trim().toLowerCase().split('-').first;
    return launchLanguageCodes.contains(normalized)
        ? normalized
        : defaultLanguageCode;
  }
}
