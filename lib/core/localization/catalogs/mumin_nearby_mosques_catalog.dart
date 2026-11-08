
/// Mumin Pro — Nearby Mosques Localization Catalog.
///
/// Interface translations for worldwide mosque discovery.
/// Mosque names and addresses remain source-provided data.
abstract final class MuminNearbyMosquesCatalog {
  static const Map<String, Map<String, String>> _catalogs = {
    'ar': {
      'nearby_mosques_title': 'المساجد القريبة',
      'nearby_mosques_subtitle': 'اكتشف المساجد في أي منطقة من العالم',
      'nearby_mosques_search_area': 'البحث في هذه المنطقة',
      'nearby_mosques_search_hint': 'ابحث باسم المسجد أو المدينة...',
      'nearby_mosques_move_map': 'حرّك الخريطة إلى المنطقة المطلوبة',
      'nearby_mosques_select_area': 'حدد المنطقة التي تريد البحث فيها',
      'nearby_mosques_searching': 'جارٍ البحث عن المساجد...',
      'nearby_mosques_empty': 'لم نعثر على مساجد مسجلة في هذه المنطقة',
      'nearby_mosques_error': 'تعذر تحميل المساجد. حاول مرة أخرى.',
      'nearby_mosques_partial': 'بعض أجزاء المنطقة لم يكتمل البحث فيها',
      'nearby_mosques_retry': 'إعادة المحاولة',
      'nearby_mosquesunnamed': 'مسجد دون اسم مسجل',
      'nearby_mosques_prayer_room': 'غرفة صلاة',
      'nearby_mosques_musalla': 'مصلى',
      'nearby_mosques_address': 'العنوان',
      'nearby_mosques_distance': 'المسافة',
      'nearby_mosques_source_notice':
          'البيانات من OpenStreetMap. قد لا تكون جميع المساجد مسجلة.',
      'nearby_mosques_privacy_notice':
          'عند الضغط على البحث، تُرسل حدود المنطقة المحددة إلى خادم البحث العام.',
      'nearby_mosques_open_map': 'عرض الخريطة',
      'nearby_mosques_list': 'القائمة',
      'nearby_mosques_results': 'النتائج',
      'nearby_mosques_location_unavailable': 'الموقع غير متوفر في البيانات',
    },
    'en': {
      'nearby_mosques_title': 'Nearby Mosques',
      'nearby_mosques_subtitle': 'Discover mosques anywhere in the world',
      'nearby_mosques_search_area': 'Search this area',
      'nearby_mosques_search_hint': 'Search by mosque or city name...',
      'nearby_mosques_move_map': 'Move the map to your desired area',
      'nearby_mosques_select_area': 'Choose an area to search',
      'nearby_mosques_searching': 'Searching for mosques...',
      'nearby_mosques_empty': 'No registered mosques found in this area',
      'nearby_mosques_error': 'Could not load mosques. Try again.',
      'nearby_mosques_partial': 'Some parts of this area could not be searched',
      'nearby_mosques_retry': 'Retry',
      'nearby_mosquesunnamed': 'Unnamed mosque',
      'nearby_mosques_prayer_room': 'Prayer room',
      'nearby_mosques_musalla': 'Musalla',
      'nearby_mosques_address': 'Address',
      'nearby_mosques_distance': 'Distance',
      'nearby_mosques_source_notice':
          'Data from OpenStreetMap. Not every mosque may be registered.',
      'nearby_mosques_privacy_notice':
          'When you tap search, the selected area boundaries are sent to a public search server.',
      'nearby_mosques_open_map': 'Map',
      'nearby_mosques_list': 'List',
      'nearby_mosques_results': 'Results',
      'nearby_mosques_location_unavailable': 'Location unavailable in the data',
    },
    'fr': {
      'nearby_mosques_title': 'Mosquées à proximité',
      'nearby_mosques_subtitle': 'Découvrez des mosquées partout dans le monde',
      'nearby_mosques_search_area': 'Rechercher dans cette zone',
      'nearby_mosques_search_hint': 'Rechercher par mosquée ou ville...',
      'nearby_mosques_move_map': 'Déplacez la carte vers la zone souhaitée',
      'nearby_mosques_select_area': 'Choisissez une zone à rechercher',
      'nearby_mosques_searching': 'Recherche des mosquées...',
      'nearby_mosques_empty': 'Aucune mosquée enregistrée dans cette zone',
      'nearby_mosques_error': 'Impossible de charger les mosquées. Réessayez.',
      'nearby_mosques_partial': 'Certaines parties de la zone n’ont pas pu être explorées',
      'nearby_mosques_retry': 'Réessayer',
      'nearby_mosquesunnamed': 'Mosquée sans nom enregistré',
      'nearby_mosques_prayer_room': 'Salle de prière',
      'nearby_mosques_musalla': 'Musalla',
      'nearby_mosques_address': 'Adresse',
      'nearby_mosques_distance': 'Distance',
      'nearby_mosques_source_notice':
          'Données OpenStreetMap. Toutes les mosquées ne sont pas nécessairement enregistrées.',
      'nearby_mosques_privacy_notice':
          'Lorsque vous appuyez sur rechercher, les limites de la zone sélectionnée sont envoyées à un serveur public.',
      'nearby_mosques_open_map': 'Carte',
      'nearby_mosques_list': 'Liste',
      'nearby_mosques_results': 'Résultats',
      'nearby_mosques_location_unavailable': 'Emplacement indisponible dans les données',
    },
  };

  static const Set<String> requiredKeys = {
    'nearby_mosques_title',
    'nearby_mosques_subtitle',
    'nearby_mosques_search_area',
    'nearby_mosques_search_hint',
    'nearby_mosques_move_map',
    'nearby_mosques_select_area',
    'nearby_mosques_searching',
    'nearby_mosques_empty',
    'nearby_mosques_error',
    'nearby_mosques_partial',
    'nearby_mosques_retry',
    'nearby_mosquesunnamed',
    'nearby_mosques_prayer_room',
    'nearby_mosques_musalla',
    'nearby_mosques_address',
    'nearby_mosques_distance',
    'nearby_mosques_source_notice',
    'nearby_mosques_privacy_notice',
    'nearby_mosques_open_map',
    'nearby_mosques_list',
    'nearby_mosques_results',
    'nearby_mosques_location_unavailable',
  };

  static Map<String, String> forLanguage(String languageCode) {
    final code = languageCode.trim().toLowerCase().split(RegExp('[-_]')).first;
    return _catalogs[code] ?? _catalogs['ar']!;
  }

  static bool isCompleteFor(String languageCode) {
    final catalog = forLanguage(languageCode);
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
