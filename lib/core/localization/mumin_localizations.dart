
/// Centralized interface translations for Mumin Pro.
///
/// This class intentionally has no Flutter dependency. It can be reused by
/// screens, controllers and presentation widgets without coupling them to
/// MaterialApp or a specific localization delegate.
final class MuminLocalizations {
  const MuminLocalizations._(this.languageCode);

  factory MuminLocalizations.fromCode(String? code) {
    final normalized = code?.trim().toLowerCase().split(RegExp('[-_]')).first;

    return MuminLocalizations._(
      supportedLanguageCodes.contains(normalized) ? normalized! : 'en',
    );
  }

  static const List<String> supportedLanguageCodes = <String>[
    'ar',
    'en',
    'fr',
  ];

  final String languageCode;

  bool get isArabic => languageCode == 'ar';

  bool get isFrench => languageCode == 'fr';

  bool get isRightToLeft => isArabic;

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

  String text(String key) {
    final current = _translations[languageCode]!;
    final english = _translations['en']!;

    return current[key] ?? english[key] ?? key;
  }

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

  String prayerName(String prayerKey) {
    const prayerKeys = <String>{
      'fajr',
      'sunrise',
      'dhuhr',
      'asr',
      'maghrib',
      'isha',
    };

    if (!prayerKeys.contains(prayerKey)) {
      return text('unavailable');
    }

    return text('prayer_$prayerKey');
  }

  static const Map<String, Map<String, String>> _translations =
      <String, Map<String, String>>{
    'ar': <String, String>{
      'app_name': 'Mumin Pro',
      'tagline': 'رفيقك لعبادة أكثر طمأنينة',
      'quick_access': 'الوصول السريع',
      'daily_essentials': 'كل ما تحتاجه في يومك',
      'prayer_times': 'مواقيت الصلاة',
      'next_prayer': 'الصلاة القادمة',
      'location': 'الموقع',
      'update_location': 'تحديث موقعي الحالي',
      'updating_location': 'جارٍ تحديث الموقع...',
      'loading_prayer_times': 'جارٍ تجهيز مواقيت الصلاة...',
      'prayer_times_unavailable': 'تعذر تجهيز مواقيت الصلاة',
      'retry': 'إعادة المحاولة',
      'retrying': 'جارٍ إعادة المحاولة...',
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
      'prayer_fajr': 'الفجر',
      'prayer_sunrise': 'الشروق',
      'prayer_dhuhr': 'الظهر',
      'prayer_asr': 'العصر',
      'prayer_maghrib': 'المغرب',
      'prayer_isha': 'العشاء',
      'adhan_in_development': 'خدمة الأذان قيد التطوير',
      'adhkar_in_development': 'قسم الأذكار قيد التطوير',
      'getting_location': 'جارٍ تحديد الموقع...',
      'location_permission_required': 'يلزم السماح بالوصول إلى الموقع',
      'retry_location': 'إعادة تحديد الموقع',
    },
    'en': <String, String>{
      'app_name': 'Mumin Pro',
      'tagline': 'Your companion for a more mindful daily practice',
      'quick_access': 'Quick access',
      'daily_essentials': 'Your daily essentials',
      'prayer_times': 'Prayer times',
      'next_prayer': 'Next prayer',
      'location': 'Location',
      'update_location': 'Update my location',
      'updating_location': 'Updating location...',
      'loading_prayer_times': 'Preparing prayer times...',
      'prayer_times_unavailable': 'Unable to prepare prayer times',
      'retry': 'Try again',
      'retrying': 'Retrying...',
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
      'prayer_fajr': 'Fajr',
      'prayer_sunrise': 'Sunrise',
      'prayer_dhuhr': 'Dhuhr',
      'prayer_asr': 'Asr',
      'prayer_maghrib': 'Maghrib',
      'prayer_isha': 'Isha',
      'adhan_in_development': 'Adhan service is under development',
      'adhkar_in_development': 'Adhkar section is under development',
      'getting_location': 'Getting location...',
      'location_permission_required': 'Location permission is required',
      'retry_location': 'Try locating again',
    },
    'fr': <String, String>{
      'app_name': 'Mumin Pro',
      'tagline': 'Votre compagnon pour une pratique quotidienne sereine',
      'quick_access': 'Accès rapide',
      'daily_essentials': 'Vos essentiels au quotidien',
      'prayer_times': 'Horaires de prière',
      'next_prayer': 'Prochaine prière',
      'location': 'Emplacement',
      'update_location': 'Actualiser ma position',
      'updating_location': 'Actualisation de la position...',
      'loading_prayer_times': 'Préparation des horaires de prière...',
      'prayer_times_unavailable': 'Impossible de préparer les horaires de prière',
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
      'prayer_fajr': 'Fajr',
      'prayer_sunrise': 'Lever du soleil',
      'prayer_dhuhr': 'Dhuhr',
      'prayer_asr': 'Asr',
      'prayer_maghrib': 'Maghrib',
      'prayer_isha': 'Isha',
      'adhan_in_development': 'Le service d’adhan est en cours de développement',
      'adhkar_in_development': 'La section des invocations est en cours de développement',
      'getting_location': 'Localisation en cours...',
      'location_permission_required': 'L’autorisation de localisation est nécessaire',
      'retry_location': 'Réessayer la localisation',
    },
  };
}
