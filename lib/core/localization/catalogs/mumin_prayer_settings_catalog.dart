
/// Mumin Pro — Prayer Settings Translation Catalog.
///
/// This catalog contains presentation strings only.
/// Prayer calculation logic and Adhan configuration remain
/// in the prayer feature and are not modified here.
///
/// Launch languages:
/// - Arabic: ar
/// - English: en
/// - French: fr
///
/// All prayer-settings UI translations must be resolved through
/// MuminLocalizations. This catalog is merged into the central
/// translation engine in the localization integration stage.
abstract final class MuminPrayerSettingsCatalog {
  static const Map<String, String> ar = {
    'prayer_settings_title': 'إعدادات الصلاة',
    'prayer_settings_intro_title': 'صلاتك في وقتها',
    'prayer_settings_intro_description':
        'خصص مواقيت الصلاة لتناسب موقعك وطريقة الحساب التي تتبعها.',
    'prayer_settings_calculation_section':
        'طريقة حساب المواقيت',
    'prayer_settings_calculation_description':
        'اختر طريقة الحساب المعتمدة في منطقتك.',
    'prayer_settings_calculation_label': 'طريقة الحساب',
    'prayer_settings_asr_section': 'طريقة حساب صلاة العصر',
    'prayer_settings_asr_description':
        'يحدد هذا الاختيار وقت صلاة العصر.',
    'prayer_settings_madhab_label': 'المذهب',
    'prayer_settings_madhab_shafi_group':
        'الشافعي والمالكي والحنبلي',
    'prayer_settings_madhab_hanafi': 'الحنفي',
    'prayer_settings_information':
        'تختلف مواقيت الصلاة حسب الموقع الجغرافي وطريقة الحساب. للحصول على نتائج أدق، اختر الطريقة التي تعتمدها الجهة الإسلامية الموثوقة في منطقتك.',
    'prayer_settings_timezone_title':
        'المنطقة الزمنية المكتشفة',
    'prayer_settings_auto_save':
        'الإعدادات تحفظ تلقائيًا',

    'calculation_muslim_world_league':
        'رابطة العالم الإسلامي',
    'calculation_egyptian':
        'الهيئة المصرية العامة للمساحة',
    'calculation_karachi':
        'جامعة العلوم الإسلامية - كراتشي',
    'calculation_umm_al_qura':
        'أم القرى - مكة المكرمة',
    'calculation_dubai': 'دبي',
    'calculation_qatar': 'قطر',
    'calculation_kuwait': 'الكويت',
    'calculation_singapore': 'سنغافورة',
    'calculation_north_america': 'أمريكا الشمالية',
    'calculation_turkey': 'تركيا',
    'calculation_tehran': 'طهران',
    'calculation_other': 'إعدادات مخصصة',
  };

  static const Map<String, String> en = {
    'prayer_settings_title': 'Prayer Settings',
    'prayer_settings_intro_title': 'Prayer, on time',
    'prayer_settings_intro_description':
        'Customize prayer times for your location and preferred calculation method.',
    'prayer_settings_calculation_section':
        'Prayer Calculation Method',
    'prayer_settings_calculation_description':
        'Choose the calculation method used in your region.',
    'prayer_settings_calculation_label':
        'Calculation method',
    'prayer_settings_asr_section': 'Asr Calculation',
    'prayer_settings_asr_description':
        'This setting determines the Asr prayer time.',
    'prayer_settings_madhab_label': 'Madhab',
    'prayer_settings_madhab_shafi_group':
        'Shafi, Maliki and Hanbali',
    'prayer_settings_madhab_hanafi': 'Hanafi',
    'prayer_settings_information':
        'Prayer times vary according to geographical location and calculation method. For accurate results, choose the method recommended by a trusted Islamic authority in your region.',
    'prayer_settings_timezone_title':
        'Detected time zone',
    'prayer_settings_auto_save':
        'Settings are saved automatically',

    'calculation_muslim_world_league':
        'Muslim World League',
    'calculation_egyptian':
        'Egyptian General Authority',
    'calculation_karachi':
        'University of Islamic Sciences, Karachi',
    'calculation_umm_al_qura':
        'Umm Al-Qura University',
    'calculation_dubai': 'Dubai',
    'calculation_qatar': 'Qatar',
    'calculation_kuwait': 'Kuwait',
    'calculation_singapore': 'Singapore',
    'calculation_north_america': 'North America',
    'calculation_turkey': 'Turkey',
    'calculation_tehran': 'Tehran',
    'calculation_other': 'Custom settings',
  };

  static const Map<String, String> fr = {
    'prayer_settings_title': 'Réglages de prière',
    'prayer_settings_intro_title': 'La prière à l’heure',
    'prayer_settings_intro_description':
        'Personnalisez les horaires selon votre position et la méthode de calcul choisie.',
    'prayer_settings_calculation_section':
        'Méthode de calcul des horaires',
    'prayer_settings_calculation_description':
        'Choisissez la méthode de calcul utilisée dans votre région.',
    'prayer_settings_calculation_label':
        'Méthode de calcul',
    'prayer_settings_asr_section':
        'Calcul de la prière d’Al-Asr',
    'prayer_settings_asr_description':
        'Ce réglage détermine l’heure de la prière d’Al-Asr.',
    'prayer_settings_madhab_label': 'École juridique',
    'prayer_settings_madhab_shafi_group':
        'Chaféite, malikite et hanbalite',
    'prayer_settings_madhab_hanafi': 'Hanafite',
    'prayer_settings_information':
        'Les horaires de prière varient selon la position géographique et la méthode de calcul. Pour plus de précision, choisissez la méthode recommandée par une autorité islamique fiable de votre région.',
    'prayer_settings_timezone_title':
        'Fuseau horaire détecté',
    'prayer_settings_auto_save':
        'Les réglages sont enregistrés automatiquement',

    'calculation_muslim_world_league':
        'Ligue islamique mondiale',
    'calculation_egyptian':
        'Autorité générale égyptienne',
    'calculation_karachi':
        'Université des sciences islamiques de Karachi',
    'calculation_umm_al_qura':
        'Université Umm Al-Qura',
    'calculation_dubai': 'Dubaï',
    'calculation_qatar': 'Qatar',
    'calculation_kuwait': 'Koweït',
    'calculation_singapore': 'Singapour',
    'calculation_north_america': 'Amérique du Nord',
    'calculation_turkey': 'Turquie',
    'calculation_tehran': 'Téhéran',
    'calculation_other': 'Réglages personnalisés',
  };

  /// Returns the catalog associated with an approved launch language.
  ///
  /// Unknown language codes safely fall back to Arabic.
  static Map<String, String> forLanguage(String? languageCode) {
    switch (languageCode?.trim().toLowerCase()) {
      case 'en':
        return en;
      case 'fr':
        return fr;
      case 'ar':
      default:
        return ar;
    }
  }

  /// Keys belonging to this domain catalog.
  static Set<String> get keys =>
      Set<String>.unmodifiable(ar.keys);

  /// Returns true when all three launch catalogs contain a key.
  static bool isComplete(String key) {
    final normalized = key.trim();

    if (normalized.isEmpty) {
      return false;
    }

    return ar.containsKey(normalized) &&
        en.containsKey(normalized) &&
        fr.containsKey(normalized);
  }
}
