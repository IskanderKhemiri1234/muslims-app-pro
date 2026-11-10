
/// Mumin Pro — Quran Reader Interface Catalog.
///
/// Contains reader-specific interface labels only.
/// It never stores or modifies Quranic verses.
abstract final class MuminQuranReaderCatalog {
  static const Map<String, Map<String, String>> _catalogs = {
    'ar': {
      'quran_delete': 'حذف',
      'quran_saved_verses_title': 'الآيات المحفوظة',
      'quran_saved_verses_empty_title': 'لا توجد آيات محفوظة',
      'quran_saved_verses_empty_hint':
          'اضغط على آية داخل المصحف واختر حفظ الآية',
      'quran_surah_label': 'سورة',
      'quran_ayah_number': 'الآية',
      'quran_page_number': 'صفحة',
      'quran_bookmark_saved_message': 'تم حفظ الصفحة في العلامات المرجعية',
      'quran_bookmark_removed_message': 'تم حذف العلامة المرجعية',
      'quran_bookmarks_title': 'علاماتي المرجعية',
      'quran_bookmarks_empty_title': 'لا توجد علامات مرجعية',
      'quran_bookmarks_empty_hint':
          'احفظ الصفحات المهمة للعودة إليها لاحقاً',
      'quran_current_page': 'الصفحة الحالية',
      'quran_open_page': 'الانتقال إلى الصفحة',
      'quran_delete_bookmark': 'حذف العلامة',
      'quran_index_title': 'فهرس المصحف',
      'quran_surahs_tab': 'السور',
      'quran_juz_tab': 'الأجزاء',
      'quran_juz_number': 'الجزء {number}',
      'quran_juz_page': 'صفحة {page}',
      'quran_journey_title': 'رحلتك مع القرآن',
      'quran_mushaf_page_count': '604 صفحة',
      'quran_current_khatma_progress': 'إنجاز الختمة الحالية',
      'quran_completed_pages_count': '{count} صفحة مكتملة',
      'quran_completed_khatmas_count': '{count} ختمة مكتملة',
      'quran_daily_reading_title': 'وردك اليومي',
      'quran_daily_pages_progress': '{read} من {target} صفحات',
      'quran_current_page_title': 'الصفحة {page}',
      'quran_open_full_mushaf': 'فتح المصحف كاملاً',
      'quran_reader_open_hint': 'اضغط لفتح صفحة القرآن كاملة',
      'quran_save_ayah_action': 'حفظ الآية',
      'quran_previous_short': 'السابقة',
      'quran_next_short': 'التالية',
      'quran_remove_page_bookmark': 'إزالة العلامة',
      'quran_save_page_bookmark': 'حفظ الصفحة',
      'quran_bookmarks_short': 'العلامات',
      'quran_verses_short': 'الآيات',
      'quran_go_to_short': 'انتقال',
      'quran_page_position': 'الصفحة {page} من {total}',
      'quran_hide_controls': 'إخفاء أدوات القراءة',
      'quran_show_controls': 'إظهار أدوات القراءة',

      'quran_theme_day': 'الزمرد الملكي',
      'quran_theme_night': 'ليالي سماوية',
      'quran_theme_warm_paper': 'العاج الملكي',
      'quran_back': 'رجوع',
      'quran_reader_title': 'المصحف الشريف',
      'quran_page_read_completed': 'تمت قراءة هذه الصفحة',
      'quran_page_read_question': 'هل قرأت هذه الصفحة؟',
      'quran_undo': 'تراجع',
      'quran_mark_read': 'تمت القراءة',
    },
    'en': {
      'quran_delete': 'Delete',
      'quran_saved_verses_title': 'Saved verses',
      'quran_saved_verses_empty_title': 'No saved verses',
      'quran_saved_verses_empty_hint':
          'Tap a verse in the Mushaf and choose Save verse',
      'quran_surah_label': 'Surah',
      'quran_ayah_number': 'Verse',
      'quran_page_number': 'Page',
      'quran_bookmark_saved_message': 'Page added to bookmarks',
      'quran_bookmark_removed_message': 'Bookmark removed',
      'quran_bookmarks_title': 'My bookmarks',
      'quran_bookmarks_empty_title': 'No bookmarks yet',
      'quran_bookmarks_empty_hint':
          'Save important pages to return to them later',
      'quran_current_page': 'Current page',
      'quran_open_page': 'Go to page',
      'quran_delete_bookmark': 'Delete bookmark',
      'quran_index_title': 'Mushaf index',
      'quran_surahs_tab': 'Surahs',
      'quran_juz_tab': 'Juz',
      'quran_juz_number': 'Juz {number}',
      'quran_juz_page': 'Page {page}',
      'quran_journey_title': 'Your Quran journey',
      'quran_mushaf_page_count': '604 pages',
      'quran_current_khatma_progress': 'Current khatm progress',
      'quran_completed_pages_count': '{count} pages completed',
      'quran_completed_khatmas_count': '{count} khatms completed',
      'quran_daily_reading_title': 'Your daily reading',
      'quran_daily_pages_progress': '{read} of {target} pages',
      'quran_current_page_title': 'Page {page}',
      'quran_open_full_mushaf': 'Open full Mushaf',
      'quran_reader_open_hint': 'Tap to open the full Quran page',
      'quran_save_ayah_action': 'Save verse',
      'quran_previous_short': 'Previous',
      'quran_next_short': 'Next',
      'quran_remove_page_bookmark': 'Remove bookmark',
      'quran_save_page_bookmark': 'Save page',
      'quran_bookmarks_short': 'Bookmarks',
      'quran_verses_short': 'Verses',
      'quran_go_to_short': 'Go to',
      'quran_page_position': 'Page {page} of {total}',
      'quran_hide_controls': 'Hide reading controls',
      'quran_show_controls': 'Show reading controls',

      'quran_theme_day': 'Royal emerald',
      'quran_theme_night': 'Celestial midnight',
      'quran_theme_warm_paper': 'Royal ivory',
      'quran_back': 'Back',
      'quran_reader_title': 'Quran Reader',
      'quran_page_read_completed': 'Page completed',
      'quran_page_read_question': 'Have you read this page?',
      'quran_undo': 'Undo',
      'quran_mark_read': 'Mark as read',
    },
    'fr': {
      'quran_delete': 'Supprimer',
      'quran_saved_verses_title': 'Versets enregistrés',
      'quran_saved_verses_empty_title': 'Aucun verset enregistré',
      'quran_saved_verses_empty_hint':
          'Touchez un verset dans le Mushaf et choisissez Enregistrer',
      'quran_surah_label': 'Sourate',
      'quran_ayah_number': 'Verset',
      'quran_page_number': 'Page',
      'quran_bookmark_saved_message': 'Page ajoutée aux signets',
      'quran_bookmark_removed_message': 'Signet supprimé',
      'quran_bookmarks_title': 'Mes signets',
      'quran_bookmarks_empty_title': 'Aucun signet pour le moment',
      'quran_bookmarks_empty_hint':
          'Enregistrez les pages importantes pour les retrouver plus tard',
      'quran_current_page': 'Page actuelle',
      'quran_open_page': 'Aller à la page',
      'quran_delete_bookmark': 'Supprimer le signet',
      'quran_index_title': 'Index du Mushaf',
      'quran_surahs_tab': 'Sourates',
      'quran_juz_tab': 'Juz',
      'quran_juz_number': 'Juz {number}',
      'quran_juz_page': 'Page {page}',
      'quran_journey_title': 'Votre parcours coranique',
      'quran_mushaf_page_count': '604 pages',
      'quran_current_khatma_progress': 'Progression actuelle',
      'quran_completed_pages_count': '{count} pages terminées',
      'quran_completed_khatmas_count': '{count} lectures complètes',
      'quran_daily_reading_title': 'Votre lecture quotidienne',
      'quran_daily_pages_progress': '{read} sur {target} pages',
      'quran_current_page_title': 'Page {page}',
      'quran_open_full_mushaf': 'Ouvrir le Mushaf complet',
      'quran_reader_open_hint':
          'Touchez pour ouvrir la page complète du Coran',
      'quran_save_ayah_action': 'Enregistrer le verset',
      'quran_previous_short': 'Précédente',
      'quran_next_short': 'Suivante',
      'quran_remove_page_bookmark': 'Supprimer le signet',
      'quran_save_page_bookmark': 'Enregistrer la page',
      'quran_bookmarks_short': 'Signets',
      'quran_verses_short': 'Versets',
      'quran_go_to_short': 'Aller à',
      'quran_page_position': 'Page {page} sur {total}',
      'quran_hide_controls': 'Masquer les commandes de lecture',
      'quran_show_controls': 'Afficher les commandes de lecture',

      'quran_theme_day': 'Émeraude royale',
      'quran_theme_night': 'Nuit céleste',
      'quran_theme_warm_paper': 'Ivoire royal',
      'quran_back': 'Retour',
      'quran_reader_title': 'Lecture du Coran',
      'quran_page_read_completed': 'Page lue',
      'quran_page_read_question': 'Avez-vous lu cette page ?',
      'quran_undo': 'Annuler',
      'quran_mark_read': 'Marquer comme lue',
    },
  };

  static const Set<String> requiredKeys = {
    'quran_delete',
    'quran_saved_verses_title',
    'quran_saved_verses_empty_title',
    'quran_saved_verses_empty_hint',
    'quran_surah_label',
    'quran_ayah_number',
    'quran_page_number',
    'quran_bookmark_saved_message',
    'quran_bookmark_removed_message',
    'quran_bookmarks_title',
    'quran_bookmarks_empty_title',
    'quran_bookmarks_empty_hint',
    'quran_current_page',
    'quran_open_page',
    'quran_delete_bookmark',
    'quran_index_title',
    'quran_surahs_tab',
    'quran_juz_tab',
    'quran_juz_number',
    'quran_juz_page',
    'quran_journey_title',
    'quran_mushaf_page_count',
    'quran_current_khatma_progress',
    'quran_completed_pages_count',
    'quran_completed_khatmas_count',
    'quran_daily_reading_title',
    'quran_daily_pages_progress',
    'quran_current_page_title',
    'quran_open_full_mushaf',
    'quran_reader_open_hint',
    'quran_save_ayah_action',
    'quran_previous_short',
    'quran_next_short',
    'quran_remove_page_bookmark',
    'quran_save_page_bookmark',
    'quran_bookmarks_short',
    'quran_verses_short',
    'quran_go_to_short',
    'quran_page_position',
    'quran_hide_controls',
    'quran_show_controls',
    'quran_theme_day',
    'quran_theme_night',
    'quran_theme_warm_paper',
    'quran_back',
    'quran_reader_title',
    'quran_page_read_completed',
    'quran_page_read_question',
    'quran_undo',
    'quran_mark_read',
  };

  static const List<String> launchLanguageCodes = [
    'ar',
    'en',
    'fr',
  ];

  static Map<String, String> forLanguage(String languageCode) {
    final normalized =
        languageCode.trim().toLowerCase().split('-').first;
    return _catalogs[normalized] ?? _catalogs['ar']!;
  }

  static String text(
    String languageCode,
    String key, {
    Map<String, Object?> parameters = const {},
  }) {
    final normalizedKey = key.trim();
    if (normalizedKey.isEmpty) return '';

    final selected = forLanguage(languageCode);
    final fallback = _catalogs['ar']!;

    final resolvedValue =
        selected[normalizedKey] ?? fallback[normalizedKey];

    if (resolvedValue == null) return normalizedKey;

    var value = resolvedValue;

    for (final entry in parameters.entries) {
      value = value.replaceAll(
        '{${entry.key}}',
        entry.value?.toString() ?? '',
      );
    }

    return value;
  }

  static bool isCompleteFor(String languageCode) {
    final catalog = _catalogs[
      languageCode.trim().toLowerCase().split('-').first
    ];

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
}
