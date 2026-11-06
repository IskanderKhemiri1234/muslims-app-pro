
/// Centralized interface translations for Mumin Pro.
///
/// This class intentionally has no Flutter dependency.
/// It can be reused by screens, controllers and presentation widgets
/// without coupling them to MaterialApp or a specific localization delegate.
///
/// Localization strategy:
/// 1. Use the selected language.
/// 2. Fall back to English when a translation is missing.
/// 3. Return the original key as a final safe fallback.
///
/// The domain layer must pass stable localization keys instead of
/// presentation-ready error messages.
final class MuminLocalizations {
  const MuminLocalizations._(this.languageCode);

  factory MuminLocalizations.fromCode(String? code) {
    final normalized = _normalizeLanguageCode(code);

    return MuminLocalizations._(
      supportedLanguageCodes.contains(normalized)
          ? normalized!
          : 'en',
    );
  }

  /// Languages supported by the current release.
  static const List<String> supportedLanguageCodes = <String>[
    'ar',
    'en',
    'fr',
  ];

  final String languageCode;

  bool get isArabic => languageCode == 'ar';

  bool get isFrench => languageCode == 'fr';

  bool get isEnglish => languageCode == 'en';

  bool get isRightToLeft => isArabic;

  // ---------------------------------------------------------------------------
  // LANGUAGE INFORMATION
  // ---------------------------------------------------------------------------

  String get languageNativeName {
    switch (languageCode) {
      case 'ar':
        return 'العربية';

      case 'fr':
        return 'Français';

      default:
        return 'English';
    }
  }

  String get languageEnglishName {
    switch (languageCode) {
      case 'ar':
        return 'Arabic';

      case 'fr':
        return 'French';

      default:
        return 'English';
    }
  }

  static String? _normalizeLanguageCode(String? code) {
    final normalized = code
        ?.trim()
        .toLowerCase()
        .split(RegExp('[-_]'))
        .first;

    if (normalized == null || normalized.isEmpty) {
      return null;
    }

    return normalized;
  }

  // ---------------------------------------------------------------------------
  // CORE TRANSLATION ENGINE
  // ---------------------------------------------------------------------------

  /// Resolves a translation using the selected language.
  ///
  /// Missing translations automatically fall back to English.
  /// Unknown keys are returned unchanged to avoid null values or crashes.
  String text(String key) {
    final normalizedKey = key.trim();

    if (normalizedKey.isEmpty) {
      return '';
    }

    final current = _translations[languageCode]!;
    final english = _translations['en']!;

    return current[normalizedKey] ??
        english[normalizedKey] ??
        normalizedKey;
  }

  /// Resolves a translation with a caller-provided fallback.
  ///
  /// Useful for optional labels and dynamically supplied content.
  String textOr(
    String key, {
    required String fallback,
  }) {
    final current = _translations[languageCode]!;
    final english = _translations['en']!;

    return current[key] ?? english[key] ?? fallback;
  }

  /// Indicates whether a key exists in the selected language.
  ///
  /// This checks the selected language only, not the English fallback.
  bool hasTranslation(String key) {
    return _translations[languageCode]!.containsKey(key);
  }

  /// Indicates whether a key exists in any supported dictionary.
  bool knowsKey(String key) {
    for (final translations in _translations.values) {
      if (translations.containsKey(key)) {
        return true;
      }
    }

    return false;
  }

  /// Resolves a domain error code without importing domain classes.
  ///
  /// Example:
  /// text(error.localizationKey)
  String error(String localizationKey) {
    return text(localizationKey);
  }

  // ---------------------------------------------------------------------------
  // APPLICATION
  // ---------------------------------------------------------------------------

  String get appName => text('app_name');

  String get tagline => text('tagline');

  String get quickAccess => text('quick_access');

  String get dailyEssentials => text('daily_essentials');

  String get prayerTimes => text('prayer_times');

  String get nextPrayer => text('next_prayer');

  String get location => text('location');

  String get updateLocation => text('update_location');

  String get updatingLocation => text('updating_location');

  String get loadingPrayerTimes => text('loading_prayer_times');

  String get prayerTimesUnavailable => text('prayer_times_unavailable');

  String get retry => text('retry');

  String get retrying => text('retrying');

  String get lightMode => text('light_mode');

  String get darkMode => text('dark_mode');

  String get quran => text('quran');

  String get qibla => text('qibla');

  String get adhkar => text('adhkar');

  String get tasbih => text('tasbih');

  String get calendar => text('calendar');

  String get settings => text('settings');

  String get comingSoon => text('coming_soon');

  String get letPrayerIlluminateYourDay =>
      text('let_prayer_illuminate_your_day');

  // ---------------------------------------------------------------------------
  // PRAYER AND LOCATION STATES
  // ---------------------------------------------------------------------------

  String get gettingLocation => text('getting_location');

  String get locationPermissionRequired =>
      text('location_permission_required');

  String get retryLocation => text('retry_location');

  String get locationUnavailable => text('location_unavailable');

  String get locationPermissionDenied =>
      text('location_permission_denied');

  String get locationPermissionPermanentlyDenied =>
      text('location_permission_permanently_denied');

  String get locationServicesDisabled =>
      text('location_services_disabled');

  String get locationTemporarilyUnavailable =>
      text('location_temporarily_unavailable');

  String get locationUpdated => text('location_updated');

  String get locationUpdateFailed => text('location_update_failed');

  String get locationSaved => text('location_saved');

  String get locationSaveFailed => text('location_save_failed');

  String get timezoneResolving => text('timezone_resolving');

  String get timezoneUnavailable => text('timezone_unavailable');

  String get timezoneUpdated => text('timezone_updated');

  String get prayerCalculationInProgress =>
      text('prayer_calculation_in_progress');

  String get prayerCalculationFailed =>
      text('prayer_calculation_failed');

  String get prayerScheduleRefreshed =>
      text('prayer_schedule_refreshed');

  String get prayerScheduleRefreshFailed =>
      text('prayer_schedule_refresh_failed');

  String get prayerSettingsUpdated =>
      text('prayer_settings_updated');

  String get prayerSettingsUpdateFailed =>
      text('prayer_settings_update_failed');

  String get prayerTimesReady => text('prayer_times_ready');

  String get prayerTimesNeedLocation =>
      text('prayer_times_need_location');

  String get offlineMode => text('offline_mode');

  String get offlineModeDescription =>
      text('offline_mode_description');

  String get unexpectedError => text('unexpected_error');

  String get somethingWentWrong => text('something_went_wrong');

  String get tryAgainInAMoment => text('try_again_in_a_moment');

  String get operationCancelled => text('operation_cancelled');

  String get settingsSaved => text('settings_saved');

  String get settingsSaveFailed => text('settings_save_failed');

  // ---------------------------------------------------------------------------
  // PRAYER RULES ERRORS
  // ---------------------------------------------------------------------------

  String get prayerRulesInvalidConfigurationSize =>
      text('prayer_rules_invalid_configuration_size');

  String get prayerRulesInvalidJson =>
      text('prayer_rules_invalid_json');

  String get prayerRulesInvalidConfigurationRoot =>
      text('prayer_rules_invalid_configuration_root');

  String get prayerRulesUnsupportedSchema =>
      text('prayer_rules_unsupported_schema');

  String get prayerRulesInvalidVersion =>
      text('prayer_rules_invalid_version');

  String get prayerRulesInvalidProfiles =>
      text('prayer_rules_invalid_profiles');

  String get prayerRulesInvalidProfile =>
      text('prayer_rules_invalid_profile');

  String get prayerRulesInvalidProfileId =>
      text('prayer_rules_invalid_profile_id');

  String get prayerRulesInvalidCountryCode =>
      text('prayer_rules_invalid_country_code');

  String get prayerRulesInvalidCalculationSettings =>
      text('prayer_rules_invalid_calculation_settings');

  String get prayerRulesDuplicateProfileId =>
      text('prayer_rules_duplicate_profile_id');

  String get prayerRulesDuplicateCountryProfile =>
      text('prayer_rules_duplicate_country_profile');

  String get prayerRulesUnknownCalculationMethod =>
      text('prayer_rules_unknown_calculation_method');

  String get prayerRulesUnknownMadhab =>
      text('prayer_rules_unknown_madhab');

  // ---------------------------------------------------------------------------
  // PRAYER NAMES
  // ---------------------------------------------------------------------------

  String prayerName(String prayerKey) {
    final normalized = prayerKey.trim().toLowerCase();

    const prayerKeys = <String>{
      'fajr',
      'sunrise',
      'dhuhr',
      'asr',
      'maghrib',
      'isha',
    };

    if (!prayerKeys.contains(normalized)) {
      return text('unavailable');
    }

    return text('prayer_$normalized');
  }

  // ---------------------------------------------------------------------------
  // TRANSLATION DICTIONARIES
  // ---------------------------------------------------------------------------

  static const Map<String, Map<String, String>> _translations =
      <String, Map<String, String>>{
    // =======================================================================
    // ARABIC
    // =======================================================================

    'ar': <String, String>{
      'app_name': 'Mumin Pro',
      'tagline': 'رفيقك لعبادة أكثر طمأنينة',

      'quick_access': 'الوصول السريع',
      'daily_essentials': 'كل ما تحتاجه في يومك',

      'prayer_times': 'مواقيت الصلاة',
      'next_prayer': 'الصلاة القادمة',

      'location': 'الموقع',
      'update_location': 'تحديث موقعي الحالي',
      'updating_location': 'جارٍ تحديث موقعك بكل عناية...',
      'loading_prayer_times': 'نهيّئ لك مواقيت الصلاة...',
      'prayer_times_unavailable': 'مواقيت الصلاة غير متاحة حالياً',

      'retry': 'إعادة المحاولة',
      'retrying': 'جارٍ المحاولة من جديد...',

      'light_mode': 'الوضع الفاتح',
      'dark_mode': 'الوضع الداكن',

      'quran': 'القرآن الكريم',
      'qibla': 'اتجاه القبلة',
      'adhkar': 'الأذكار',
      'tasbih': 'التسبيح',
      'calendar': 'التقويم الهجري',
      'settings': 'الإعدادات',

      'coming_soon': 'هذه الميزة ستتوفر قريباً',
      'let_prayer_illuminate_your_day': 'صلاتك نور يومك',

      'unavailable': 'غير متاح',

      // Prayer names.
      'prayer_fajr': 'الفجر',
      'prayer_sunrise': 'الشروق',
      'prayer_dhuhr': 'الظهر',
      'prayer_asr': 'العصر',
      'prayer_maghrib': 'المغرب',
      'prayer_isha': 'العشاء',

      // Existing feature states.
      'adhan_in_development': 'خدمة الأذان قيد التطوير',
      'adhkar_in_development': 'قسم الأذكار قيد التطوير',
      'getting_location': 'جارٍ تحديد موقعك...',
      'location_permission_required': 'نحتاج إلى إذن الموقع لعرض المواقيت الدقيقة',
      'retry_location': 'المحاولة مجدداً لتحديد الموقع',

      // Location states.
      'location_unavailable': 'لم نتمكن من تحديد موقعك حالياً',
      'location_permission_denied': 'لم يُسمح بالوصول إلى الموقع. يمكنك تفعيل الإذن للمتابعة',
      'location_permission_permanently_denied': 'إذن الموقع مغلق من إعدادات الجهاز. فعّله متى رغبت في استخدام المواقيت المحلية',
      'location_services_disabled': 'خدمة تحديد الموقع متوقفة. فعّلها لنحدد مواقيت مدينتك',
      'location_temporarily_unavailable': 'إشارة الموقع غير مستقرة الآن. حاول مرة أخرى بعد لحظات',
      'location_updated': 'تم تحديث موقعك بنجاح',
      'location_update_failed': 'Your location could not be updated. Your previous location is still preserved',
      'location_saved': 'تم حفظ موقعك لهذا الجهاز',
      'location_save_failed': 'تم تحديث الموقع، لكن تعذر حفظه على الجهاز',

      // Timezone states.
      'timezone_resolving': 'نحدد منطقتك الزمنية لضبط المواقيت بدقة...',
      'timezone_unavailable': 'تعذر تحديد المنطقة الزمنية لهذا الموقع. حاول تحديث موقعك',
      'timezone_updated': 'تم ضبط المنطقة الزمنية المحلية',

      // Prayer calculation states.
      'prayer_calculation_in_progress': 'نحسب المواقيت وفق موقعك وإعداداتك...',
      'prayer_calculation_failed': 'تعذر حساب المواقيت الآن. تحقق من الموقع وإعدادات الحساب',
      'prayer_schedule_refreshed': 'تم تحديث مواقيت الصلاة',
      'prayer_schedule_refresh_failed': 'تعذر تحديث المواقيت. سنحتفظ بآخر بيانات صالحة',
      'prayer_settings_updated': 'تم تحديث طريقة حساب الصلاة',
      'prayer_settings_update_failed': 'لم نتمكن من تطبيق إعدادات الحساب. أعد المحاولة',
      'prayer_times_ready': 'مواقيت الصلاة جاهزة',
      'prayer_times_need_location': 'حدد موقعك أولاً لعرض مواقيت الصلاة المحلية',

      // General system states.
      'offline_mode': 'أنت في وضع عدم الاتصال',
      'offline_mode_description': 'يمكنك متابعة استخدام البيانات المحفوظة على جهازك',
      'unexpected_error': 'حدث أمر غير متوقع',
      'something_went_wrong': 'لم تسر الأمور كما ينبغي، ونحن نعمل على مساعدتك',
      'try_again_in_a_moment': 'امنحنا لحظة ثم حاول مجدداً',
      'operation_cancelled': 'تم إلغاء العملية',
      'settings_saved': 'تم حفظ إعداداتك',
      'settings_save_failed': 'تعذر حفظ الإعدادات على الجهاز',

      // Prayer rules configuration errors.
      'prayer_rules_invalid_configuration_size': 'ملف إعدادات الحساب غير صالح أو يتجاوز الحجم المسموح',
      'prayer_rules_invalid_json': 'تعذر قراءة ملف إعدادات الحساب. قد يكون تنسيقه غير صحيح',
      'prayer_rules_invalid_configuration_root': 'بنية ملف إعدادات الحساب غير مكتملة',
      'prayer_rules_unsupported_schema': 'إصدار بنية إعدادات الحساب غير مدعوم',
      'prayer_rules_invalid_version': 'إصدار إعدادات الحساب غير صالح أو أقدم من الإصدار الحالي',
      'prayer_rules_invalid_profiles': 'قائمة إعدادات الدول غير مكتملة أو غير صالحة',
      'prayer_rules_invalid_profile': 'أحد ملفات إعدادات الحساب غير صالح',
      'prayer_rules_invalid_profile_id': 'معرّف ملف إعدادات الحساب غير صالح',
      'prayer_rules_invalid_country_code': 'رمز الدولة في إعدادات الحساب غير صالح',
      'prayer_rules_invalid_calculation_settings': 'إعدادات طريقة الحساب أو المذهب غير مكتملة',
      'prayer_rules_duplicate_profile_id': 'يوجد أكثر من ملف يحمل معرّف الإعداد نفسه',
      'prayer_rules_duplicate_country_profile': 'توجد إعدادات مكررة للدولة نفسها',
      'prayer_rules_unknown_calculation_method': 'طريقة الحساب المحددة غير معروفة أو غير مدعومة',
      'prayer_rules_unknown_madhab': 'المذهب المحدد غير مدعوم في إعدادات الحساب الحالية',
    },

    // =======================================================================
    // ENGLISH
    // =======================================================================

    'en': <String, String>{
      'app_name': 'Mumin Pro',
      'tagline': 'Your companion for a more mindful daily practice',

      'quick_access': 'Quick access',
      'daily_essentials': 'Your daily essentials',

      'prayer_times': 'Prayer times',
      'next_prayer': 'Next prayer',

      'location': 'Location',
      'update_location': 'Update my location',
      'updating_location': 'Refreshing your location...',
      'loading_prayer_times': 'Preparing your prayer times...',
      'prayer_times_unavailable': 'Prayer times are temporarily unavailable',

      'retry': 'Try again',
      'retrying': 'Trying again...',

      'light_mode': 'Light mode',
      'dark_mode': 'Dark mode',

      'quran': 'Quran',
      'qibla': 'Qibla direction',
      'adhkar': 'Adhkar',
      'tasbih': 'Tasbih',
      'calendar': 'Hijri calendar',
      'settings': 'Settings',

      'coming_soon': 'This feature will be available soon',
      'let_prayer_illuminate_your_day': 'Let prayer illuminate your day',

      'unavailable': 'Unavailable',

      // Prayer names.
      'prayer_fajr': 'Fajr',
      'prayer_sunrise': 'Sunrise',
      'prayer_dhuhr': 'Dhuhr',
      'prayer_asr': 'Asr',
      'prayer_maghrib': 'Maghrib',
      'prayer_isha': 'Isha',

      // Existing feature states.
      'adhan_in_development': 'Adhan service is under development',
      'adhkar_in_development': 'Adhkar section is under development',
      'getting_location': 'Finding your location...',
      'location_permission_required': 'Location access is needed to show accurate local prayer times',
      'retry_location': 'Try locating again',

      // Location states.
      'location_unavailable': 'We could not determine your location right now',
      'location_permission_denied': 'Location access was not granted. You can enable permission to continue',
      'location_permission_permanently_denied': 'Location permission is disabled in your device settings. Enable it whenever you want local prayer times',
      'location_services_disabled': 'Location services are turned off. Enable them to find your local prayer times',
      'location_temporarily_unavailable': 'Your location signal is unavailable right now. Please try again shortly',
      'location_updated': 'Your location has been updated',
      'location_update_failed': 'Your location could not be updated. Your previous location is still محفوظ',
      'location_saved': 'Your location has been saved on this device',
      'location_save_failed': 'Your location was updated, but could not be saved on this device',

      // Timezone states.
      'timezone_resolving': 'Finding your local time zone to keep prayer times accurate...',
      'timezone_unavailable': 'We could not determine the time zone for this location. Try updating your location',
      'timezone_updated': 'Your local time zone has been applied',

      // Prayer calculation states.
      'prayer_calculation_in_progress': 'Calculating prayer times using your location and preferences...',
      'prayer_calculation_failed': 'We could not calculate prayer times right now. Check your location and calculation settings',
      'prayer_schedule_refreshed': 'Your prayer schedule has been refreshed',
      'prayer_schedule_refresh_failed': 'Your prayer times could not be refreshed. Your last valid schedule is being kept',
      'prayer_settings_updated': 'Your prayer calculation settings have been updated',
      'prayer_settings_update_failed': 'We could not apply those calculation settings. Please try again',
      'prayer_times_ready': 'Your prayer times are ready',
      'prayer_times_need_location': 'Set your location to see local prayer times',

      // General system states.
      'offline_mode': 'You are offline',
      'offline_mode_description': 'You can continue using the information already saved on your device',
      'unexpected_error': 'Something unexpected happened',
      'something_went_wrong': 'Something did not go as expected. We are here to help',
      'try_again_in_a_moment': 'Please wait a moment and try again',
      'operation_cancelled': 'The operation was cancelled',
      'settings_saved': 'Your settings have been saved',
      'settings_save_failed': 'Your settings could not be saved on this device',

      // Prayer rules configuration errors.
      'prayer_rules_invalid_configuration_size': 'The prayer settings file is invalid or exceeds the allowed size',
      'prayer_rules_invalid_json': 'The prayer settings file could not be read. Its format may be invalid',
      'prayer_rules_invalid_configuration_root': 'The prayer settings file has an incomplete structure',
      'prayer_rules_unsupported_schema': 'This prayer settings format is not supported',
      'prayer_rules_invalid_version': 'The prayer settings version is invalid or older than the current version',
      'prayer_rules_invalid_profiles': 'The country settings collection is incomplete or invalid',
      'prayer_rules_invalid_profile': 'One of the prayer calculation profiles is invalid',
      'prayer_rules_invalid_profile_id': 'The prayer profile identifier is invalid',
      'prayer_rules_invalid_country_code': 'The country code in the prayer settings is invalid',
      'prayer_rules_invalid_calculation_settings': 'The calculation method or madhab settings are incomplete',
      'prayer_rules_duplicate_profile_id': 'More than one profile uses the same identifier',
      'prayer_rules_duplicate_country_profile': 'Duplicate calculation profiles were found for the same country',
      'prayer_rules_unknown_calculation_method': 'The selected calculation method is unknown or unsupported',
      'prayer_rules_unknown_madhab': 'The selected madhab is not supported by the current calculation settings',
    },

    // =======================================================================
    // FRENCH
    // =======================================================================

    'fr': <String, String>{
      'app_name': 'Mumin Pro',
      'tagline': 'Votre compagnon pour une pratique quotidienne sereine',

      'quick_access': 'Accès rapide',
      'daily_essentials': 'Vos essentiels au quotidien',

      'prayer_times': 'Horaires de prière',
      'next_prayer': 'Prochaine prière',

      'location': 'Emplacement',
      'update_location': 'Actualiser ma position',
      'updating_location': 'Actualisation de votre position...',
      'loading_prayer_times': 'Préparation de vos horaires de prière...',
      'prayer_times_unavailable': 'Les horaires de prière sont momentanément indisponibles',

      'retry': 'Réessayer',
      'retrying': 'Nouvelle tentative...',

      'light_mode': 'Mode clair',
      'dark_mode': 'Mode sombre',

      'quran': 'Coran',
      'qibla': 'Direction de la Qibla',
      'adhkar': 'Invocations',
      'tasbih': 'Tasbih',
      'calendar': 'Calendrier hégirien',
      'settings': 'Paramètres',

      'coming_soon': 'Cette fonctionnalité sera bientôt disponible',
      'let_prayer_illuminate_your_day': 'Que la prière illumine votre journée',

      'unavailable': 'Indisponible',

      // Prayer names.
      'prayer_fajr': 'Fajr',
      'prayer_sunrise': 'Lever du soleil',
      'prayer_dhuhr': 'Dhuhr',
      'prayer_asr': 'Asr',
      'prayer_maghrib': 'Maghrib',
      'prayer_isha': 'Isha',

      // Existing feature states.
      'adhan_in_development': 'Le service d’adhan est en cours de développement',
      'adhkar_in_development': 'La section des invocations est en cours de développement',
      'getting_location': 'Recherche de votre position...',
      'location_permission_required': 'L’accès à votre position est nécessaire pour afficher les horaires locaux avec précision',
      'retry_location': 'Réessayer la localisation',

      // Location states.
      'location_unavailable': 'Nous ne parvenons pas à déterminer votre position pour le moment',
      'location_permission_denied': 'L’accès à la position n’a pas été autorisé. Vous pouvez activer cette autorisation pour continuer',
      'location_permission_permanently_denied': 'L’autorisation de localisation est désactivée dans les paramètres de votre appareil. Activez-la pour obtenir les horaires locaux',
      'location_services_disabled': 'Les services de localisation sont désactivés. Activez-les pour déterminer vos horaires locaux',
      'location_temporarily_unavailable': 'Le signal de localisation est momentanément indisponible. Veuillez réessayer dans un instant',
      'location_updated': 'Votre position a été actualisée',
      'location_update_failed': 'La position n’a pas pu être actualisée. Votre ancienne position est conservée',
      'location_saved': 'Votre position a été enregistrée sur cet appareil',
      'location_save_failed': 'Votre position a été actualisée, mais n’a pas pu être enregistrée sur cet appareil',

      // Timezone states.
      'timezone_resolving': 'Identification de votre fuseau horaire pour garantir des horaires précis...',
      'timezone_unavailable': 'Impossible de déterminer le fuseau horaire de cette position. Essayez d’actualiser votre position',
      'timezone_updated': 'Votre fuseau horaire local a été appliqué',

      // Prayer calculation states.
      'prayer_calculation_in_progress': 'Calcul des horaires selon votre position et vos préférences...',
      'prayer_calculation_failed': 'Impossible de calculer les horaires pour le moment. Vérifiez votre position et vos paramètres de calcul',
      'prayer_schedule_refreshed': 'Vos horaires de prière ont été actualisés',
      'prayer_schedule_refresh_failed': 'Impossible d’actualiser les horaires. Votre dernier calendrier valide est conservé',
      'prayer_settings_updated': 'Vos paramètres de calcul des prières ont été actualisés',
      'prayer_settings_update_failed': 'Impossible d’appliquer ces paramètres de calcul. Veuillez réessayer',
      'prayer_times_ready': 'Vos horaires de prière sont prêts',
      'prayer_times_need_location': 'Définissez votre position pour afficher les horaires de prière locaux',

      // General system states.
      'offline_mode': 'Vous êtes hors ligne',
      'offline_mode_description': 'Vous pouvez continuer à consulter les informations déjà enregistrées sur votre appareil',
      'unexpected_error': 'Un événement inattendu est survenu',
      'something_went_wrong': 'Tout ne s’est pas déroulé comme prévu. Nous sommes là pour vous aider',
      'try_again_in_a_moment': 'Patientez un instant, puis réessayez',
      'operation_cancelled': 'L’opération a été annulée',
      'settings_saved': 'Vos paramètres ont été enregistrés',
      'settings_save_failed': 'Impossible d’enregistrer vos paramètres sur cet appareil',

      // Prayer rules configuration errors.
      'prayer_rules_invalid_configuration_size': 'Le fichier des paramètres de prière est invalide ou dépasse la taille autorisée',
      'prayer_rules_invalid_json': 'Impossible de lire le fichier des paramètres de prière. Son format est peut-être incorrect',
      'prayer_rules_invalid_configuration_root': 'La structure du fichier des paramètres de prière est incomplète',
      'prayer_rules_unsupported_schema': 'Ce format de paramètres de prière n’est pas pris en charge',
      'prayer_rules_invalid_version': 'La version des paramètres de prière est invalide ou antérieure à la version actuelle',
      'prayer_rules_invalid_profiles': 'La liste des paramètres par pays est incomplète ou invalide',
      'prayer_rules_invalid_profile': 'L’un des profils de calcul des prières est invalide',
      'prayer_rules_invalid_profile_id': 'L’identifiant du profil de prière est invalide',
      'prayer_rules_invalid_country_code': 'Le code du pays dans les paramètres de prière est invalide',
      'prayer_rules_invalid_calculation_settings': 'La méthode de calcul ou les paramètres du madhab sont incomplets',
      'prayer_rules_duplicate_profile_id': 'Plusieurs profils utilisent le même identifiant',
      'prayer_rules_duplicate_country_profile': 'Plusieurs profils de calcul ont été trouvés pour le même pays',
      'prayer_rules_unknown_calculation_method': 'La méthode de calcul sélectionnée est inconnue ou non prise en charge',
      'prayer_rules_unknown_madhab': 'Le madhab sélectionné n’est pas pris en charge par les paramètres de calcul actuels',
    },
  };
}
