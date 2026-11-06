
/// Centralized Qibla and Atlas translations for Mumin Pro.
///
/// The launch release supports Arabic, English and French.
/// This catalog contains interface text only; landmark content is
/// resolved separately from the localized landmark data.
abstract final class MuminQiblaCatalog {
  static const Map<String, Map<String, String>> _catalogs = {
    'ar': {
      'qibla_atlas_search_title': 'البحث في أطلس القبلة',
      'qibla_atlas_search_hint': 'ابحث عن مسجد أو معلم أو مدينة...',
      'qibla_atlas_search_loading': 'جارٍ البحث في المعالم...',
      'qibla_atlas_search_empty': 'لا توجد نتائج مطابقة لبحثك.',
      'qibla_atlas_search_error': 'تعذر إتمام البحث. حاول مرة أخرى.',
      'qibla_landmark_details': 'تفاصيل المعلم',
      'qibla_landmark_no_description': 'لا يتوفر وصف موثق لهذا المعلم حالياً.',
      'qibla_landmark_location': 'الموقع الجغرافي',
      'qibla_landmark_coordinates': 'الإحداثيات',
      'qibla_landmark_country': 'رمز الدولة',
      'qibla_landmark_close': 'إغلاق',
      'qibla_landmark_search_semantics': 'البحث عن المعالم في أطلس القبلة',
    },
    'en': {
      'qibla_atlas_search_title': 'Search the Qibla Atlas',
      'qibla_atlas_search_hint': 'Search for a mosque, landmark or city...',
      'qibla_atlas_search_loading': 'Searching landmarks...',
      'qibla_atlas_search_empty': 'No matching results were found.',
      'qibla_atlas_search_error': 'Search could not be completed. Try again.',
      'qibla_landmark_details': 'Landmark details',
      'qibla_landmark_no_description':
          'No verified description is currently available for this landmark.',
      'qibla_landmark_location': 'Geographic location',
      'qibla_landmark_coordinates': 'Coordinates',
      'qibla_landmark_country': 'Country code',
      'qibla_landmark_close': 'Close',
      'qibla_landmark_search_semantics':
          'Search landmarks in the Qibla Atlas',
    },
    'fr': {
      'qibla_atlas_search_title': 'Rechercher dans l’Atlas de la Qibla',
      'qibla_atlas_search_hint': 'Rechercher une mosquée, un monument ou une ville...',
      'qibla_atlas_search_loading': 'Recherche des monuments...',
      'qibla_atlas_search_empty': 'Aucun résultat correspondant trouvé.',
      'qibla_atlas_search_error':
          'La recherche n’a pas abouti. Veuillez réessayer.',
      'qibla_landmark_details': 'Détails du monument',
      'qibla_landmark_no_description':
          'Aucune description vérifiée n’est actuellement disponible pour ce monument.',
      'qibla_landmark_location': 'Emplacement géographique',
      'qibla_landmark_coordinates': 'Coordonnées',
      'qibla_landmark_country': 'Code du pays',
      'qibla_landmark_close': 'Fermer',
      'qibla_landmark_search_semantics':
          'Rechercher des monuments dans l’Atlas de la Qibla',
    },
  };

  static const String defaultLanguageCode = 'ar';

  static const Set<String> requiredKeys = {
    'qibla_atlas_search_title',
    'qibla_atlas_search_hint',
    'qibla_atlas_search_loading',
    'qibla_atlas_search_empty',
    'qibla_atlas_search_error',
    'qibla_landmark_details',
    'qibla_landmark_no_description',
    'qibla_landmark_location',
    'qibla_landmark_coordinates',
    'qibla_landmark_country',
    'qibla_landmark_close',
    'qibla_landmark_search_semantics',
  };

  static Map<String, String> forLanguage(String languageCode) {
    final normalized = languageCode.trim().toLowerCase().split('-').first;
    return _catalogs[normalized] ?? _catalogs[defaultLanguageCode]!;
  }

  static String text(String languageCode, String key) {
    final normalizedKey = key.trim();

    if (normalizedKey.isEmpty) return '';

    final selected = forLanguage(languageCode);
    final fallback = _catalogs[defaultLanguageCode]!;

    return selected[normalizedKey] ??
        fallback[normalizedKey] ??
        fallback['qibla_landmark_no_description']!;
  }

  static List<String> get languageCodes =>
      List<String>.unmodifiable(_catalogs.keys);

  static bool isCompleteFor(String languageCode) {
    final catalog = _catalogs[languageCode.trim().toLowerCase().split('-').first];

    if (catalog == null) return false;

    return requiredKeys.every(
      (key) => catalog[key]?.trim().isNotEmpty == true,
    );
  }

  static Map<String, bool> get launchCatalogIntegrity =>
      Map<String, bool>.unmodifiable({
        for (final code in ['ar', 'en', 'fr'])
          code: isCompleteFor(code),
      });
}
