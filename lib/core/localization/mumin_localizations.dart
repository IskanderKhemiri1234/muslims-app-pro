
import 'mumin_language_registry.dart';

export 'mumin_language_registry.dart'
    show MuminLanguage, MuminTextDirection;

/// Mumin Pro — Central Localization Engine.
///
/// Responsibilities:
/// - Resolve translations for the active launch language.
/// - Apply the single Arabic fallback policy.
/// - Interpolate named parameters.
/// - Select language-aware plural forms.
/// - Report translation coverage and missing keys.
///
/// Language metadata and text direction are owned exclusively by
/// MuminLanguageRegistry. The original Quranic Arabic text is never
/// replaced by a translation of its meaning.
final class MuminLocalizations {
  const MuminLocalizations._(this.languageCode);

  factory MuminLocalizations.fromCode(String? code) {
    return MuminLocalizations._(
      MuminLanguageRegistry.normalizeLanguageCode(code),
    );
  }

  static const String defaultLanguageCode =
      MuminLanguageRegistry.defaultLanguageCode;
  static const String fallbackLanguageCode =
      MuminLanguageRegistry.fallbackLanguageCode;
  static const String languagePreferenceKey =
      MuminLanguageRegistry.languagePreferenceKey;
  static const String legacyLanguagePreferenceKey =
      MuminLanguageRegistry.legacyLanguagePreferenceKey;

  static Map<String, MuminLanguage> get languageRegistry =>
      MuminLanguageRegistry.languages;

  static List<String> get supportedLanguageCodes =>
      MuminLanguageRegistry.supportedLanguageCodes;

  final String languageCode;

  MuminLanguage get language =>
      MuminLanguageRegistry.launchLanguageFor(languageCode) ??
      MuminLanguageRegistry.languages[defaultLanguageCode]!;

  String get languageNativeName => language.nativeName;
  String get languageEnglishName => language.englishName;
  MuminTextDirection get direction => language.direction;

  bool get isArabic => languageCode == 'ar';
  bool get isEnglish => languageCode == 'en';
  bool get isFrench => languageCode == 'fr';
  bool get isRightToLeft => language.isRightToLeft;
  bool get isLeftToRight => language.isLeftToRight;
  String get localeTag => language.localeTag;

  static Map<String, String> get languageNativeNames =>
      MuminLanguageRegistry.languageNativeNames;

  static Map<String, String> get languageEnglishNames =>
      MuminLanguageRegistry.languageEnglishNames;

  static bool isSupported(String? code) =>
      MuminLanguageRegistry.isSupported(code);

  static String normalizeLanguageCode(String? code) =>
      MuminLanguageRegistry.normalizeLanguageCode(code);

  static MuminLanguage? languageFor(String? code) =>
      MuminLanguageRegistry.launchLanguageFor(code);

  static List<MuminLanguage> get availableLanguages =>
      MuminLanguageRegistry.availableLanguages;

  // ---------------------------------------------------------------------------
  // CENTRAL TRANSLATION ENGINE
  // ---------------------------------------------------------------------------

  static const Map<String, Map<String, String>> _translations =
      <String, Map<String, String>>{
    // -------------------------------------------------------------------------
    // ARABIC
    // -------------------------------------------------------------------------

    'ar': <String, String>{
      'app_name': 'Mumin Pro',
      
'permission_setup_title': 'لنُعِدّ Mumin Pro معاً',
'permission_setup_description':
    'فعّل الأذونات اللازمة لتصلك تنبيهات الصلاة وتظهر لك المواقيت واتجاه القبلة بدقة.',
'permission_notifications_title': 'إشعارات الصلاة والأذان',
'permission_notifications_description':
    'لإرسال تنبيهات مواقيت الصلاة والتذكيرات التي تختارها.',
'permission_location_title': 'الموقع الجغرافي',
'permission_location_description':
    'لتحديد مواقيت الصلاة المحلية وحساب اتجاه القبلة.',
'permission_status_granted': 'تم السماح',
'permission_status_pending': 'لم يتم السماح بعد',
'permission_location_service_disabled':
    'إذن الموقع ممنوح، لكن خدمة تحديد الموقع متوقفة في الجهاز.',
'permission_open_location_settings': 'تفعيل خدمة الموقع',
'permission_allow_and_continue': 'السماح والمتابعة',
'permission_continue': 'متابعة إلى التطبيق',
'permission_open_app_settings': 'إعدادات أذونات التطبيق',
'permission_skip_for_now': 'تخطي الآن',
'permission_privacy_note':
    'نحترم خصوصيتك. لا نطلب إلا الأذونات اللازمة للميزات التي تستخدمها.',
'permission_setup_save_failed':
    'تعذر حفظ إعدادات التهيئة. حاول مرة أخرى.',

      'tagline': 'رفيقك لعبادة أكثر طمأنينة',

      'select_language': 'اختر لغة التطبيق',
      'language': 'اللغة',
      'language_changed': 'تم تغيير لغة التطبيق',
      'language_change_failed': 'تعذر حفظ اللغة المختارة',
      'language_ar': 'العربية',
      'language_en': 'الإنجليزية',
      'language_fr': 'الفرنسية',

      'quick_access': 'الوصول السريع',
      'daily_essentials': 'كل ما تحتاجه في يومك',

      'prayer_times': 'مواقيت الصلاة',
      'next_prayer': 'الصلاة القادمة',

      'location': 'الموقع',
      'update_location': 'تحديث موقعي الحالي',
      'updating_location': 'جارٍ تحديث موقعك...',
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
      'settings_subtitle': 'خصص تجربتك واجعل التطبيق أقرب إلى احتياجاتك',
      'general_settings': 'الإعدادات العامة',
      'app_updates': 'تحديث التطبيق',
      'update_channel_setup_required': 'تحقق من وجود إصدار جديد ونزّله مباشرة من داخل التطبيق.',
      'update_setup_pending': 'عرض التحديثات',
      'update_signature_note': 'يجب تثبيت التحديث بتوقيع الإصدار نفسه ورقم إصدار أعلى. لا تحذف التطبيق قبل التحديث.',
      'update_checking': 'جارٍ التحقق من وجود تحديث...',
      'update_latest': 'أنت تستخدم أحدث إصدار من مؤمن برو.',
      'update_available': 'يتوفر تحديث جديد لمؤمن برو',
      'update_release_version': 'الإصدار الجديد:',
      'update_later': 'لاحقاً',
      'update_download': 'تنزيل التحديث',
      'update_check_failed': 'تعذر التحقق من التحديث. تحقق من اتصال الإنترنت وحاول مجدداً.',
      'update_download_failed': 'تعذر فتح رابط تنزيل التحديث.'

      'coming_soon': 'هذه الميزة ستتوفر قريباً',
      'let_prayer_illuminate_your_day': 'صلاتك نور يومك',
      'translation_unavailable': 'النص غير متاح حالياً',
      'unavailable': 'غير متاح',
            'today_label': 'اليوم',
      'next_prayer_eyebrow': 'الصلاة القادمة',
      'time_remaining': 'الوقت المتبقي للصلاة',
      'countdown_auto_update': 'يتم تحديث العداد تلقائيًا',
            'countdown_hour_one': 'ساعة',
      'countdown_hour_two': 'ساعتان',
      'countdown_hour_few': 'ساعات',
      'countdown_hour_other': 'ساعة',
      'countdown_minute_one': 'دقيقة',
      'countdown_minute_two': 'دقيقتان',
      'countdown_minute_few': 'دقائق',
      'countdown_minute_other': 'دقيقة',
      'countdown_second_one': 'ثانية',
      'countdown_second_two': 'ثانيتان',
      'countdown_second_few': 'ثوانٍ',
      'countdown_second_other': 'ثانية',
      'countdown_hours_label': 'ساعات',
      'countdown_minutes_label': 'دقائق',
      'countdown_seconds_label': 'ثوانٍ',
      'countdown_no_upcoming_prayer': 'لا يوجد موعد صلاة قادم متاح',
      'countdown_semantic_label':
          'الوقت المتبقي: {hours} و{minutes} و{seconds}',

      'prayer_fajr': 'الفجر',
      'prayer_sunrise': 'الشروق',
      'prayer_dhuhr': 'الظهر',
      'prayer_asr': 'العصر',
      'prayer_maghrib': 'المغرب',
      'prayer_isha': 'العشاء',

      'adhan_in_development': 'خدمة الأذان قيد التطوير',
      'adhkar_in_development': 'قسم الأذكار قيد التطوير',
      'getting_location': 'جارٍ تحديد موقعك...',
      'location_permission_required':
          'نحتاج إلى إذن الموقع لعرض المواقيت الدقيقة',
      'retry_location': 'المحاولة مجدداً لتحديد الموقع',

      'location_unavailable': 'لم نتمكن من تحديد موقعك حالياً',
      'location_permission_denied':
          'لم يُسمح بالوصول إلى الموقع. يمكنك تفعيل الإذن للمتابعة',
      'location_permission_permanently_denied':
          'إذن الموقع مغلق من إعدادات الجهاز. فعّله متى رغبت في استخدام المواقيت المحلية',
      'location_services_disabled':
          'خدمة تحديد الموقع متوقفة. فعّلها لنحدد مواقيت مدينتك',

      'location_temporarily_unavailable':
          'إشارة الموقع غير مستقرة الآن. حاول مرة أخرى بعد لحظات',
      'location_updated': 'تم تحديث موقعك بنجاح',
      'location_update_failed':
          'تعذر تحديث موقعك. احتفظنا بموقعك السابق',
      'location_saved': 'تم حفظ موقعك على هذا الجهاز',
      'location_save_failed':
          'تم تحديث الموقع، لكن تعذر حفظه على الجهاز',

      'timezone_resolving':
          'نحدد منطقتك الزمنية لضبط المواقيت بدقة...',
      'timezone_unavailable':
          'تعذر تحديد المنطقة الزمنية لهذا الموقع. حاول تحديث موقعك',
      'timezone_updated': 'تم ضبط المنطقة الزمنية المحلية',

      'prayer_calculation_in_progress':
          'نحسب المواقيت وفق موقعك وإعداداتك...',
      'prayer_calculation_failed':
          'تعذر حساب المواقيت الآن. تحقق من الموقع وإعدادات الحساب',
      'prayer_schedule_refreshed': 'تم تحديث مواقيت الصلاة',
      'prayer_schedule_refresh_failed':
          'تعذر تحديث المواقيت. سنحتفظ بآخر بيانات صالحة',
      'prayer_settings_updated': 'تم تحديث طريقة حساب الصلاة',
      'prayer_settings_update_failed':
          'لم نتمكن من تطبيق إعدادات الحساب. أعد المحاولة',
      'prayer_times_ready': 'مواقيت الصلاة جاهزة',
      'prayer_times_need_location':
          'حدد موقعك أولاً لعرض مواقيت الصلاة المحلية',

      'offline_mode': 'أنت في وضع عدم الاتصال',
      'offline_mode_description':
          'يمكنك متابعة استخدام البيانات المحفوظة على جهازك',
      'unexpected_error': 'حدث أمر غير متوقع',
      'something_went_wrong':
          'لم تسر الأمور كما ينبغي، ونحن نعمل على مساعدتك',
      'try_again_in_a_moment': 'امنحنا لحظة ثم حاول مجدداً',
      'operation_cancelled': 'تم إلغاء العملية',
      'settings_saved': 'تم حفظ إعداداتك',
      'settings_save_failed': 'تعذر حفظ الإعدادات على الجهاز',

      'prayer_rules_invalid_configuration_size':
          'ملف إعدادات الحساب غير صالح أو يتجاوز الحجم المسموح',
      'prayer_rules_invalid_json':
          'تعذر قراءة ملف إعدادات الحساب. قد يكون تنسيقه غير صحيح',
      'prayer_rules_invalid_configuration_root':
          'بنية ملف إعدادات الحساب غير مكتملة',
      'prayer_rules_unsupported_schema':
          'إصدار بنية إعدادات الحساب غير مدعوم',
      'prayer_rules_invalid_version':
          'إصدار إعدادات الحساب غير صالح أو أقدم من الإصدار الحالي',
      'prayer_rules_invalid_profiles':
          'قائمة إعدادات الدول غير مكتملة أو غير صالحة',
      'prayer_rules_invalid_profile':
          'أحد ملفات إعدادات الحساب غير صالح',
      'prayer_rules_invalid_profile_id':
          'معرّف ملف إعدادات الحساب غير صالح',
      'prayer_rules_invalid_country_code':
          'رمز الدولة في إعدادات الحساب غير صالح',
      'prayer_rules_invalid_calculation_settings':
          'إعدادات طريقة الحساب أو المذهب غير مكتملة',
      'prayer_rules_duplicate_profile_id':
          'يوجد أكثر من ملف يحمل معرّف الإعداد نفسه',
      'prayer_rules_duplicate_country_profile':
          'توجد إعدادات مكررة للدولة نفسها',
      'prayer_rules_unknown_calculation_method':
          'طريقة الحساب المحددة غير معروفة أو غير مدعومة',
      'prayer_rules_unknown_madhab':
          'المذهب المحدد غير مدعوم في إعدادات الحساب الحالية',

      // Quran interface.
      'quran_reading': 'قراءة القرآن',

      'continue_reading': 'متابعة القراءة',
      'start_reading': 'ابدأ القراءة',
      'resume_reading': 'متابعة من حيث وصلت',
      'surah': 'السورة',
      'surahs': 'السور',
      'juz': 'الجزء',
      'juz_number': 'رقم الجزء',
      'page': 'الصفحة',
      'page_number': 'رقم الصفحة',
      'ayah': 'الآية',
      'ayah_number': 'رقم الآية',
      'bookmarks': 'العلامات المرجعية',
      'bookmark': 'علامة مرجعية',
      'add_bookmark': 'إضافة علامة مرجعية',
      'remove_bookmark': 'إزالة العلامة المرجعية',
      'bookmarked': 'تمت إضافة العلامة المرجعية',
      'no_bookmarks': 'لا توجد علامات مرجعية بعد',
      'last_read': 'آخر موضع قراءة',
      'reading_progress': 'تقدم القراءة',
      'khatma': 'الختمة',
      'khatmas_completed': 'الختمات المكتملة',
      'daily_reading_goal': 'هدف القراءة اليومي',
      'pages_read_today': 'الصفحات المقروءة اليوم',
      'mark_page_completed': 'تحديد الصفحة كمكتملة',
      'page_completed': 'تم إكمال الصفحة',
      'page_not_completed': 'لم تكتمل الصفحة بعد',
      'go_to_page': 'الانتقال إلى صفحة',
      'select_surah': 'اختر سورة',
      'select_juz': 'اختر جزءاً',
      'search_surah': 'البحث عن سورة',
      'quran_loading': 'جارٍ تحميل القرآن الكريم...',
      'quran_load_failed': 'تعذر تحميل صفحات القرآن الكريم',
      'quran_settings': 'إعدادات القراءة',
      'translation': 'الترجمة',
      'translation_language': 'لغة الترجمة',
      'show_translation': 'إظهار ترجمة المعاني',
      'hide_translation': 'إخفاء ترجمة المعاني',
      'arabic_text': 'النص العربي',
      'recitation': 'التلاوة',
      'playback': 'التشغيل',
      'play': 'تشغيل',
      'pause': 'إيقاف مؤقت',
      'stop': 'إيقاف',
      'next_ayah': 'الآية التالية',
      'previous_ayah': 'الآية السابقة',
      'repeat': 'تكرار',
      'font_size': 'حجم الخط',
      'mushaf_page': 'صفحة المصحف',
      'hizb': 'الحزب',
      'rub': 'ربع الحزب',
      'sajdah': 'موضع سجدة',
      'meccan': 'مكية',
      'medinan': 'مدنية',
      'surah_count': 'عدد السور',
      'ayah_count': 'عدد الآيات',
      'juz_progress': 'تقدم الجزء',
      'today_progress': 'إنجاز اليوم',
      'reading_streak': 'أيام القراءة المتتالية',
      'quran_translation_not_available':
          'ترجمة المعاني غير متاحة بهذه اللغة حالياً',
      'quran_original_text_notice':
          'النص القرآني العربي الأصلي محفوظ كما هو',

        // Adhkar and Tasbih.
'adhkar_header_title': 'اذكر الله واطمئن',
'adhkar_header_description': 'اختر ذكراً وابدأ العدّ. سيُحفظ تقدمك على جهازك.',
'adhkar_choose_dhikr': 'اختر الذكر',
'adhkar_istighfar_title': 'الاستغفار',
'adhkar_subhanallah_title': 'سبحان الله وبحمده',
'adhkar_tahlil_title': 'كلمة التوحيد',
'adhkar_daily': 'خلال اليوم',
'adhkar_morning_evening': 'صباحاً ومساءً',
'adhkar_target': 'العدد',
'adhkar_tap_to_count': 'اضغط للتسبيح والعدّ',
'adhkar_completed': 'اكتمل العدد، تقبّل الله منك',
'adhkar_remaining': 'المتبقي',
'adhkar_reset': 'إعادة ضبط العدّاد',
'adhkar_reset_title': 'إعادة ضبط العدّاد',
'adhkar_reset_message': 'هل تريد تصفير عدّاد هذا الذكر؟',
'adhkar_source': 'المصدر والتوثيق',
'reset': 'إعادة الضبط',

'tasbih_header_title': 'مسبحتك الرقمية',
'tasbih_header_description': 'اختر هدف العدّ واضغط على الدائرة لتسجيل كل تسبيحة.',
'tasbih_choose_target': 'اختر هدف العدّ',
'tasbih_current_count': 'العدد الحالي',
'tasbih_tap_to_count': 'اضغط لزيادة العدّاد',
'tasbih_tap_instruction': 'المس الدائرة الكبيرة لإضافة تسبيحة',
'tasbih_completed': 'اكتمل هدف العدّ',
'tasbih_remaining': 'المتبقي',
'tasbih_undo': 'تراجع',
'tasbih_reset_title': 'إعادة ضبط المسبحة',
'tasbih_reset_message': 'هل تريد تصفير العدّاد الحالي؟',
'tasbih_personal_target_note': 'الأعداد المعروضة أهداف شخصية للعدّ، ويمكنك اختيار ما يناسبك. لا تمثل هذه الأهداف تحديداً شرعياً لعدد الذكر.',
      
        // General interface.
      'cancel': 'إلغاء',
      'confirm': 'تأكيد',
      'save': 'حفظ',
      'delete': 'حذف',
      'edit': 'تعديل',
      'close': 'إغلاق',
      'done': 'تم',
      'search': 'بحث',
      'clear': 'مسح',
      'back': 'رجوع',
      'continue': 'متابعة',
      'yes': 'نعم',
      'no': 'لا',
      'on': 'مفعّل',
      'off': 'متوقف',
      'enabled': 'مفعّل',
      'disabled': 'معطّل',
    },

    // -------------------------------------------------------------------------
    // ENGLISH
    // -------------------------------------------------------------------------

    'en': <String, String>{
      'app_name': 'Mumin Pro',
        
'permission_setup_title': 'Let’s set up Mumin Pro',
'permission_setup_description':
    'Enable the permissions needed for prayer alerts, accurate prayer times and Qibla direction.',
'permission_notifications_title': 'Prayer and Adhan notifications',
'permission_notifications_description':
    'Receive prayer-time alerts and the reminders you choose.',
'permission_location_title': 'Location access',
'permission_location_description':
    'Calculate local prayer times and determine the Qibla direction.',
'permission_status_granted': 'Permission granted',
'permission_status_pending': 'Not granted yet',
'permission_location_service_disabled':
    'Location permission is granted, but device location services are turned off.',
'permission_open_location_settings': 'Enable location services',
'permission_allow_and_continue': 'Allow and continue',
'permission_continue': 'Continue to app',
'permission_open_app_settings': 'App permission settings',
'permission_skip_for_now': 'Skip for now',
'permission_privacy_note':
    'Your privacy matters. We request only permissions needed for the features you use.',
'permission_setup_save_failed':
    'Could not save setup preferences. Please try again.',

      'tagline': 'Your companion for a more mindful daily practice',

      'select_language': 'Choose your app language',
      'language': 'Language',
      'language_changed': 'App language changed',

      'language_change_failed': 'The selected language could not be saved',
      'language_ar': 'Arabic',
      'language_en': 'English',
      'language_fr': 'French',

      'quick_access': 'Quick access',
      'daily_essentials': 'Your daily essentials',

      'prayer_times': 'Prayer times',
      'next_prayer': 'Next prayer',

      'location': 'Location',
      'update_location': 'Update my location',
      'updating_location': 'Refreshing your location...',
      'loading_prayer_times': 'Preparing your prayer times...',
      'prayer_times_unavailable':
          'Prayer times are temporarily unavailable',

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
      'settings_subtitle': 'Personalize your experience and make the app yours',
      'general_settings': 'General settings',
      'app_updates': 'App updates',
      'update_channel_setup_required': 'Check for a new version and download it directly from the app.',
      'update_setup_pending': 'View updates',
      'update_signature_note': 'The update must use the same signing certificate and a higher version code. Do not uninstall the app before updating.',
      'update_checking': 'Checking for updates...',
      'update_latest': 'You are using the latest version of Mumin Pro.',
      'update_available': 'A new Mumin Pro update is available',
      'update_release_version': 'New version:',
      'update_later': 'Later',
      'update_download': 'Download update',
      'update_check_failed': 'Could not check for updates. Check your internet connection and try again.',
      'update_download_failed': 'Could not open the update download link.'
      'today_label': 'Today',
      'next_prayer_eyebrow': 'Up next',
      'time_remaining': 'Time remaining',
      'countdown_auto_update': 'Countdown updates automatically',
            'countdown_hour_one': 'hour',
      'countdown_hour_other': 'hours',
      'countdown_minute_one': 'minute',
      'countdown_minute_other': 'minutes',
      'countdown_second_one': 'second',
      'countdown_second_other': 'seconds',
      'countdown_hours_label': 'HOURS',
      'countdown_minutes_label': 'MINUTES',
      'countdown_seconds_label': 'SECONDS',
      'countdown_no_upcoming_prayer': 'No upcoming prayer time available',
      'countdown_semantic_label':
          'Time remaining: {hours}, {minutes} and {seconds}',

      'coming_soon': 'This feature will be available soon',
      'let_prayer_illuminate_your_day': 'Let prayer illuminate your day',
      'translation_unavailable': 'This text is currently unavailable',
      'unavailable': 'Unavailable',

      'prayer_fajr': 'Fajr',
      'prayer_sunrise': 'Sunrise',
      'prayer_dhuhr': 'Dhuhr',
      'prayer_asr': 'Asr',
      'prayer_maghrib': 'Maghrib',
      'prayer_isha': 'Isha',

      'adhan_in_development': 'Adhan service is under development',
      'adhkar_in_development': 'Adhkar section is under development',
      'getting_location': 'Finding your location...',
      'location_permission_required':
          'Location access is needed to show accurate local prayer times',
      'retry_location': 'Try locating again',

      'location_unavailable':
          'We could not determine your location right now',
      'location_permission_denied':
          'Location access was not granted. You can enable permission to continue',
      'location_permission_permanently_denied':
          'Location permission is disabled in your device settings. Enable it whenever you want local prayer times',
      'location_services_disabled':
          'Location services are turned off. Enable them to find your local prayer times',
      'location_temporarily_unavailable':
          'Your location signal is unavailable right now. Please try again shortly',
      'location_updated': 'Your location has been updated',
      'location_update_failed':
          'Your location could not be updated. Your previous location has been preserved',

      'location_saved': 'Your location has been saved on this device',
      'location_save_failed':
          'Your location was updated, but could not be saved on this device',

      'timezone_resolving':
          'Finding your local time zone to keep prayer times accurate...',
      'timezone_unavailable':
          'We could not determine the time zone for this location. Try updating your location',
      'timezone_updated': 'Your local time zone has been applied',

      'prayer_calculation_in_progress':
          'Calculating prayer times using your location and preferences...',
      'prayer_calculation_failed':
          'We could not calculate prayer times right now. Check your location and calculation settings',
      'prayer_schedule_refreshed': 'Your prayer schedule has been refreshed',
      'prayer_schedule_refresh_failed':
          'Your prayer times could not be refreshed. Your last valid schedule is being kept',
      'prayer_settings_updated':
          'Your prayer calculation settings have been updated',
      'prayer_settings_update_failed':
          'We could not apply those calculation settings. Please try again',
      'prayer_times_ready': 'Your prayer times are ready',
      'prayer_times_need_location':
          'Set your location to see local prayer times',

      'offline_mode': 'You are offline',
      'offline_mode_description':
          'You can continue using the information already saved on your device',
      'unexpected_error': 'Something unexpected happened',
      'something_went_wrong':
          'Something did not go as expected. We are here to help',
      'try_again_in_a_moment': 'Please wait a moment and try again',
      'operation_cancelled': 'The operation was cancelled',
      'settings_saved': 'Your settings have been saved',
      'settings_save_failed':
          'Your settings could not be saved on this device',

      'prayer_rules_invalid_configuration_size':
          'The prayer settings file is invalid or exceeds the allowed size',
      'prayer_rules_invalid_json':
          'The prayer settings file could not be read. Its format may be invalid',
      'prayer_rules_invalid_configuration_root':
          'The prayer settings file has an incomplete structure',
      'prayer_rules_unsupported_schema':
          'This prayer settings format is not supported',
      'prayer_rules_invalid_version':
          'The prayer settings version is invalid or older than the current version',
      'prayer_rules_invalid_profiles':
          'The country settings collection is incomplete or invalid',
      'prayer_rules_invalid_profile':
          'One of the prayer calculation profiles is invalid',
      'prayer_rules_invalid_profile_id':
          'The prayer profile identifier is invalid',
      'prayer_rules_invalid_country_code':
          'The country code in the prayer settings is invalid',
      'prayer_rules_invalid_calculation_settings':
          'The calculation method or madhab settings are incomplete',
      'prayer_rules_duplicate_profile_id':
          'More than one profile uses the same identifier',
      'prayer_rules_duplicate_country_profile':
          'Duplicate calculation profiles were found for the same country',

      'prayer_rules_unknown_calculation_method':
          'The selected calculation method is unknown or unsupported',
      'prayer_rules_unknown_madhab':
          'The selected madhab is not supported by the current calculation settings',

      // Quran interface.
      'quran_reading': 'Quran reading',
      'continue_reading': 'Continue reading',
      'start_reading': 'Start reading',
      'resume_reading': 'Resume where you left off',
      'surah': 'Surah',
      'surahs': 'Surahs',
      'juz': 'Juz',
      'juz_number': 'Juz number',
      'page': 'Page',
      'page_number': 'Page number',
      'ayah': 'Ayah',
      'ayah_number': 'Ayah number',
      'bookmarks': 'Bookmarks',
      'bookmark': 'Bookmark',
      'add_bookmark': 'Add bookmark',
      'remove_bookmark': 'Remove bookmark',
      'bookmarked': 'Bookmark added',
      'no_bookmarks': 'You have no bookmarks yet',
      'last_read': 'Last read position',
      'reading_progress': 'Reading progress',
      'khatma': 'Khatma',
      'khatmas_completed': 'Completed khatmas',
      'daily_reading_goal': 'Daily reading goal',
      'pages_read_today': 'Pages read today',
      'mark_page_completed': 'Mark page as completed',
      'page_completed': 'Page completed',
      'page_not_completed': 'Page not completed yet',
      'go_to_page': 'Go to page',
      'select_surah': 'Select a surah',
      'select_juz': 'Select a juz',
      'search_surah': 'Search surahs',
      'quran_loading': 'Loading the Holy Quran...',
      'quran_load_failed': 'Could not load Quran pages',
      'quran_settings': 'Reading settings',
      'translation': 'Translation',
      'translation_language': 'Translation language',
      'show_translation': 'Show meaning translation',
      'hide_translation': 'Hide meaning translation',
      'arabic_text': 'Arabic text',
      'recitation': 'Recitation',
      'playback': 'Playback',
      'play': 'Play',
      'pause': 'Pause',
      'stop': 'Stop',
      'next_ayah': 'Next ayah',
      'previous_ayah': 'Previous ayah',
      'repeat': 'Repeat',
      'font_size': 'Font size',
      'mushaf_page': 'Mushaf page',
      'hizb': 'Hizb',
      'rub': 'Quarter hizb',
      'sajdah': 'Prostration marker',
      'meccan': 'Meccan',
      'medinan': 'Medinan',
      'surah_count': 'Number of surahs',
      'ayah_count': 'Number of ayahs',
      'juz_progress': 'Juz progress',
      'today_progress': 'Today’s progress',
      'reading_streak': 'Reading streak',
      'quran_translation_not_available':
          'A meaning translation is not currently available in this language',
      'quran_original_text_notice':
          'The original Arabic Quran text is preserved unchanged',

        // Adhkar and Tasbih.
'adhkar_header_title': 'Remember Allah and find peace',
'adhkar_header_description': 'Choose a dhikr and start counting. Your progress is saved on your device.',
'adhkar_choose_dhikr': 'Choose a dhikr',
'adhkar_istighfar_title': 'Seeking forgiveness',
'adhkar_subhanallah_title': 'Glory be to Allah and praise Him',
'adhkar_tahlil_title': 'Declaration of faith',
'adhkar_daily': 'Throughout the day',
'adhkar_morning_evening': 'Morning and evening',
'adhkar_target': 'Target',
'adhkar_tap_to_count': 'Tap to count',
'adhkar_completed': 'Target completed. May Allah accept it from you.',
'adhkar_remaining': 'Remaining',
'adhkar_reset': 'Reset counter',
'adhkar_reset_title': 'Reset counter',
'adhkar_reset_message': 'Do you want to reset this dhikr counter?',
'adhkar_source': 'Source and reference',
'reset': 'Reset',

'tasbih_header_title': 'Your digital tasbih',
'tasbih_header_description': 'Choose a counting target and tap the circle to record each remembrance.',
'tasbih_choose_target': 'Choose a counting target',
'tasbih_current_count': 'Current count',
'tasbih_tap_to_count': 'Tap to increase the counter',
'tasbih_tap_instruction': 'Tap the large circle to add a remembrance',
'tasbih_completed': 'Counting target completed',
'tasbih_remaining': 'Remaining',
'tasbih_undo': 'Undo',
'tasbih_reset_title': 'Reset tasbih',
'tasbih_reset_message': 'Do you want to reset the current counter?',
'tasbih_personal_target_note': 'These numbers are personal counting goals. Choose what suits you. They do not establish a religiously prescribed number for remembrance.',
      
        // General interface.
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'save': 'Save',
      'delete': 'Delete',
      'edit': 'Edit',
      'close': 'Close',
      'done': 'Done',
      'search': 'Search',
      'clear': 'Clear',
      'back': 'Back',
      'continue': 'Continue',
      'yes': 'Yes',
      'no': 'No',
      'on': 'On',
      'off': 'Off',
      'enabled': 'Enabled',
      'disabled': 'Disabled',
    },

    // -------------------------------------------------------------------------

    // FRENCH
    // -------------------------------------------------------------------------

    'fr': <String, String>{
      'app_name': 'Mumin Pro',
        
'permission_setup_title': 'Configurons Mumin Pro',
'permission_setup_description':
    'Activez les autorisations nécessaires aux alertes de prière, aux horaires précis et à la direction de la Qibla.',
'permission_notifications_title': 'Notifications de prière et d’Adhan',
'permission_notifications_description':
    'Recevez les alertes des horaires de prière et les rappels de votre choix.',
'permission_location_title': 'Accès à la localisation',
'permission_location_description':
    'Calculer les horaires de prière locaux et déterminer la direction de la Qibla.',
'permission_status_granted': 'Autorisation accordée',
'permission_status_pending': 'Pas encore autorisée',
'permission_location_service_disabled':
    'L’autorisation est accordée, mais le service de localisation est désactivé.',
'permission_open_location_settings': 'Activer la localisation',
'permission_allow_and_continue': 'Autoriser et continuer',
'permission_continue': 'Continuer vers l’application',
'permission_open_app_settings': 'Paramètres des autorisations',
'permission_skip_for_now': 'Ignorer pour le moment',
'permission_privacy_note':
    'Votre confidentialité compte. Nous demandons uniquement les autorisations nécessaires aux fonctionnalités utilisées.',
'permission_setup_save_failed':
    'Impossible d’enregistrer la configuration. Veuillez réessayer.',

      'tagline': 'Votre compagnon pour une pratique quotidienne sereine',

      'select_language': 'Choisissez la langue de l’application',
      'language': 'Langue',
      'language_changed': 'La langue de l’application a été modifiée',
      'language_change_failed':
          'La langue sélectionnée n’a pas pu être enregistrée',
      'language_ar': 'Arabe',
      'language_en': 'Anglais',
      'language_fr': 'Français',

      'quick_access': 'Accès rapide',
      'daily_essentials': 'Vos essentiels au quotidien',

      'prayer_times': 'Horaires de prière',
      'next_prayer': 'Prochaine prière',

      'location': 'Position',
      'update_location': 'Actualiser ma position',
      'updating_location': 'Actualisation de votre position...',
      'loading_prayer_times': 'Préparation de vos horaires de prière...',
      'prayer_times_unavailable':
          'Les horaires de prière sont momentanément indisponibles',

      'retry': 'Réessayer',
      'retrying': 'Nouvelle tentative...',

      'light_mode': 'Mode clair',
      'dark_mode': 'Mode sombre',

      'quran': 'Coran',
      'qibla': 'Direction de la Qibla',
      'adhkar': 'Invocations',
      'tasbih': 'Tasbih',
      'calendar': 'Calendrier hégirien',
      'today_label': 'Aujourd’hui',
      'next_prayer_eyebrow': 'Prochaine prière',
      'time_remaining': 'Temps restant avant la prière',
      'countdown_auto_update':
          'Le compte à rebours se met à jour automatiquement',
      'countdown_hour_one': 'heure',
      'countdown_hour_other': 'heures',
      'countdown_minute_one': 'minute',
      'countdown_minute_other': 'minutes',
      'countdown_second_one': 'seconde',
      'countdown_second_other': 'secondes',
      'countdown_hours_label': 'HEURES',
      'countdown_minutes_label': 'MINUTES',
      'countdown_seconds_label': 'SECONDES',
      'countdown_no_upcoming_prayer':
          'Aucun horaire de prière à venir disponible',
      'countdown_semantic_label':
          'Temps restant : {hours}, {minutes} et {seconds}',
      'settings': 'Paramètres',
      'settings_subtitle': 'Personnalisez votre expérience selon vos besoins',
      'general_settings': 'Paramètres généraux',
      'app_updates': 'Mise à jour de l’application',
      'update_channel_setup_required': 'Vérifiez la disponibilité d’une nouvelle version et téléchargez-la directement depuis l’application.',
      'update_setup_pending': 'Voir les mises à jour',
      'update_signature_note': 'La mise à jour doit utiliser le même certificat de signature et un code de version supérieur. Ne désinstallez pas l’application avant la mise à jour.',
      'update_checking': 'Vérification des mises à jour...',
      'update_latest': 'Vous utilisez la dernière version de Mumin Pro.',
      'update_available': 'Une nouvelle mise à jour de Mumin Pro est disponible',
      'update_release_version': 'Nouvelle version :',
      'update_later': 'Plus tard',
      'update_download': 'Télécharger la mise à jour',
      'update_check_failed': 'Impossible de vérifier les mises à jour. Vérifiez votre connexion Internet et réessayez.',
      'update_download_failed': 'Impossible d’ouvrir le lien de téléchargement.'

      'coming_soon': 'Cette fonctionnalité sera bientôt disponible',
      'let_prayer_illuminate_your_day':
          'Que la prière illumine votre journée',
      'translation_unavailable':
          'Ce texte est actuellement indisponible',
      'unavailable': 'Indisponible',

      'prayer_fajr': 'Fajr',
      'prayer_sunrise': 'Lever du soleil',
      'prayer_dhuhr': 'Dhuhr',
      'prayer_asr': 'Asr',
      'prayer_maghrib': 'Maghrib',
      'prayer_isha': 'Isha',

      'adhan_in_development':
          'Le service d’adhan est en cours de développement',
      'adhkar_in_development':
          'La section des invocations est en cours de développement',
      'getting_location': 'Recherche de votre position...',
      'location_permission_required':
          'L’accès à votre position est nécessaire pour afficher les horaires locaux avec précision',
      'retry_location': 'Réessayer la localisation',

      'location_unavailable':
          'Nous ne parvenons pas à déterminer votre position pour le moment',

      'location_permission_denied':
          'L’accès à la position n’a pas été autorisé. Vous pouvez activer cette autorisation pour continuer',
      'location_permission_permanently_denied':
          'L’autorisation de localisation est désactivée dans les paramètres de votre appareil. Activez-la pour obtenir les horaires locaux',
      'location_services_disabled':
          'Les services de localisation sont désactivés. Activez-les pour déterminer vos horaires locaux',
      'location_temporarily_unavailable':
          'Le signal de localisation est momentanément indisponible. Veuillez réessayer dans un instant',
      'location_updated': 'Votre position a été actualisée',
      'location_update_failed':
          'La position n’a pas pu être actualisée. Votre ancienne position est conservée',
      'location_saved':
          'Votre position a été enregistrée sur cet appareil',
      'location_save_failed':
          'Votre position a été actualisée, mais n’a pas pu être enregistrée sur cet appareil',

      'timezone_resolving':
          'Identification de votre fuseau horaire pour garantir des horaires précis...',
      'timezone_unavailable':
          'Impossible de déterminer le fuseau horaire de cette position. Essayez d’actualiser votre position',
      'timezone_updated': 'Votre fuseau horaire local a été appliqué',

      'prayer_calculation_in_progress':
          'Calcul des horaires selon votre position et vos préférences...',
      'prayer_calculation_failed':
          'Impossible de calculer les horaires pour le moment. Vérifiez votre position et vos paramètres de calcul',
      'prayer_schedule_refreshed':
          'Vos horaires de prière ont été actualisés',
      'prayer_schedule_refresh_failed':
          'Impossible d’actualiser les horaires. Votre dernier calendrier valide est conservé',
      'prayer_settings_updated':
          'Vos paramètres de calcul des prières ont été actualisés',
      'prayer_settings_update_failed':
          'Impossible d’appliquer ces paramètres de calcul. Veuillez réessayer',
      'prayer_times_ready': 'Vos horaires de prière sont prêts',
      'prayer_times_need_location':
          'Définissez votre position pour afficher les horaires de prière locaux',

      'offline_mode': 'Vous êtes hors ligne',
      'offline_mode_description':
          'Vous pouvez continuer à consulter les informations déjà enregistrées sur votre appareil',
      'unexpected_error': 'Un événement inattendu est survenu',
      'something_went_wrong':
          'Tout ne s’est pas déroulé comme prévu. Nous sommes là pour vous aider',
      'try_again_in_a_moment':
          'Patientez un instant, puis réessayez',
      'operation_cancelled': 'L’opération a été annulée',
      'settings_saved': 'Vos paramètres ont été enregistrés',
      'settings_save_failed':
          'Impossible d’enregistrer vos paramètres sur cet appareil',

      'prayer_rules_invalid_configuration_size':
          'Le fichier des paramètres de prière est invalide ou dépasse la taille autorisée',
      'prayer_rules_invalid_json':
          'Impossible de lire le fichier des paramètres de prière. Son format est peut-être incorrect',
      'prayer_rules_invalid_configuration_root':

          'La structure du fichier des paramètres de prière est incomplète',
      'prayer_rules_unsupported_schema':
          'Ce format de paramètres de prière n’est pas pris en charge',
      'prayer_rules_invalid_version':
          'La version des paramètres de prière est invalide ou antérieure à la version actuelle',
      'prayer_rules_invalid_profiles':
          'La liste des paramètres par pays est incomplète ou invalide',
      'prayer_rules_invalid_profile':
          'L’un des profils de calcul des prières est invalide',
      'prayer_rules_invalid_profile_id':
          'L’identifiant du profil de prière est invalide',
      'prayer_rules_invalid_country_code':
          'Le code du pays dans les paramètres de prière est invalide',
      'prayer_rules_invalid_calculation_settings':
          'La méthode de calcul ou les paramètres du madhab sont incomplets',
      'prayer_rules_duplicate_profile_id':
          'Plusieurs profils utilisent le même identifiant',
      'prayer_rules_duplicate_country_profile':
          'Plusieurs profils de calcul ont été trouvés pour le même pays',
      'prayer_rules_unknown_calculation_method':
          'La méthode de calcul sélectionnée est inconnue ou non prise en charge',
      'prayer_rules_unknown_madhab':
          'Le madhab sélectionné n’est pas pris en charge par les paramètres de calcul actuels',

      // Quran interface.
      'quran_reading': 'Lecture du Coran',
      'continue_reading': 'Continuer la lecture',
      'start_reading': 'Commencer la lecture',
      'resume_reading': 'Reprendre là où vous vous êtes arrêté',
      'surah': 'Sourate',
      'surahs': 'Sourates',
      'juz': 'Juz',
      'juz_number': 'Numéro du juz',
      'page': 'Page',
      'page_number': 'Numéro de page',
      'ayah': 'Verset',
      'ayah_number': 'Numéro du verset',
      'bookmarks': 'Signets',
      'bookmark': 'Signet',
      'add_bookmark': 'Ajouter un signet',
      'remove_bookmark': 'Supprimer le signet',
      'bookmarked': 'Signet ajouté',
      'no_bookmarks': 'Vous n’avez pas encore de signets',
      'last_read': 'Dernière position de lecture',
      'reading_progress': 'Progression de lecture',
      'khatma': 'Khatma',
      'khatmas_completed': 'Khatmas terminées',
      'daily_reading_goal': 'Objectif de lecture quotidien',
      'pages_read_today': 'Pages lues aujourd’hui',
      'mark_page_completed': 'Marquer la page comme terminée',
      'page_completed': 'Page terminée',
      'page_not_completed': 'Page pas encore terminée',
      'go_to_page': 'Aller à la page',
      'select_surah': 'Choisir une sourate',
      'select_juz': 'Choisir un juz',
      'search_surah': 'Rechercher une sourate',
      'quran_loading': 'Chargement du Saint Coran...',
      'quran_load_failed': 'Impossible de charger les pages du Coran',
      'quran_settings': 'Paramètres de lecture',
      'translation': 'Traduction',
      'translation_language': 'Langue de traduction',
      'show_translation': 'Afficher la traduction du sens',
      'hide_translation': 'Masquer la traduction du sens',
      'arabic_text': 'Texte arabe',
      'recitation': 'Récitation',
      'playback': 'Lecture audio',

      'play': 'Lire',
      'pause': 'Mettre en pause',
      'stop': 'Arrêter',
      'next_ayah': 'Verset suivant',
      'previous_ayah': 'Verset précédent',
      'repeat': 'Répéter',
      'font_size': 'Taille du texte',
      'mushaf_page': 'Page du Mushaf',
      'hizb': 'Hizb',
      'rub': 'Quart de hizb',
      'sajdah': 'Marque de prosternation',
      'meccan': 'Mecquoise',
      'medinan': 'Médinoise',
      'surah_count': 'Nombre de sourates',
      'ayah_count': 'Nombre de versets',
      'juz_progress': 'Progression du juz',
      'today_progress': 'Progression du jour',
      'reading_streak': 'Jours de lecture consécutifs',
      'quran_translation_not_available':
          'La traduction du sens n’est pas disponible actuellement dans cette langue',
      'quran_original_text_notice':
          'Le texte arabe original du Coran est conservé sans modification',

        // Adhkar and Tasbih.
'adhkar_header_title': 'Évoquez Allah et trouvez la sérénité',
'adhkar_header_description': 'Choisissez une invocation et commencez à compter. Votre progression est enregistrée sur votre appareil.',
'adhkar_choose_dhikr': 'Choisir une invocation',
'adhkar_istighfar_title': 'Demande de pardon',
'adhkar_subhanallah_title': 'Gloire et louange à Allah',
'adhkar_tahlil_title': 'Déclaration de foi',
'adhkar_daily': 'Tout au long de la journée',
'adhkar_morning_evening': 'Matin et soir',
'adhkar_target': 'Objectif',
'adhkar_tap_to_count': 'Appuyez pour compter',
'adhkar_completed': 'Objectif atteint. Qu’Allah l’accepte.',
'adhkar_remaining': 'Restant',
'adhkar_reset': 'Réinitialiser le compteur',
'adhkar_reset_title': 'Réinitialiser le compteur',
'adhkar_reset_message': 'Voulez-vous remettre ce compteur à zéro ?',
'adhkar_source': 'Source et référence',
'reset': 'Réinitialiser',

'tasbih_header_title': 'Votre tasbih numérique',
'tasbih_header_description': 'Choisissez un objectif et appuyez sur le cercle pour compter chaque évocation.',
'tasbih_choose_target': 'Choisir un objectif',
'tasbih_current_count': 'Nombre actuel',
'tasbih_tap_to_count': 'Appuyez pour augmenter le compteur',
'tasbih_tap_instruction': 'Touchez le grand cercle pour ajouter une évocation',
'tasbih_completed': 'Objectif atteint',
'tasbih_remaining': 'Restant',
'tasbih_undo': 'Annuler',
'tasbih_reset_title': 'Réinitialiser le tasbih',
'tasbih_reset_message': 'Voulez-vous remettre le compteur actuel à zéro ?',
'tasbih_personal_target_note': 'Ces nombres sont des objectifs personnels de comptage. Choisissez celui qui vous convient. Ils ne constituent pas un nombre religieusement prescrit.',
      
        // General interface.
      'cancel': 'Annuler',
      'confirm': 'Confirmer',
      'save': 'Enregistrer',
      'delete': 'Supprimer',
      'edit': 'Modifier',
      'close': 'Fermer',
      'done': 'Terminé',
      'search': 'Rechercher',
      'clear': 'Effacer',
      'back': 'Retour',
      'continue': 'Continuer',
      'yes': 'Oui',
      'no': 'Non',
      'on': 'Activé',
      'off': 'Désactivé',
      'enabled': 'Activé',
      'disabled': 'Désactivé',
    },
  };

  // ---------------------------------------------------------------------------
  // TRANSLATION RESOLUTION
  // ---------------------------------------------------------------------------

  Map<String, String> get _currentCatalog =>
      _translations[languageCode] ??
      _translations[defaultLanguageCode]!;

  Map<String, String> get _fallbackCatalog =>
      _translations[fallbackLanguageCode]!;

  /// Returns a translation for the selected language.
  ///
  /// Resolution order:
  /// 1. Selected language.
  /// 2. Arabic fallback.
  /// 3. Safe unavailable message.
  ///
  /// Unknown keys are never exposed to the user.
  String text(String key) {
    final normalizedKey = key.trim();

    if (normalizedKey.isEmpty) {
      return '';
    }

    return _currentCatalog[normalizedKey] ??
        _fallbackCatalog[normalizedKey] ??
        _fallbackCatalog['translation_unavailable']!;
  }

  /// Returns a translation with an explicit final fallback.
  String textOr(
    String key, {
    required String fallback,
  }) {
    final normalizedKey = key.trim();

    if (normalizedKey.isEmpty) {
      return fallback;
    }

    return _currentCatalog[normalizedKey] ??
        _fallbackCatalog[normalizedKey] ??
        fallback;
  }

  /// Resolves a key for a specified language.
  ///
  /// This is useful for displaying a translation selector without changing
  /// the currently active application language.
  String textFor(
    String languageCode,
    String key,
  ) {
    final selectedCode = normalizeLanguageCode(languageCode);
    final selectedCatalog = _translations[selectedCode]!;
    final fallbackCatalog = _fallbackCatalog;
    final normalizedKey = key.trim();

    if (normalizedKey.isEmpty) {
      return '';
    }

    return selectedCatalog[normalizedKey] ??
        fallbackCatalog[normalizedKey] ??

        fallbackCatalog['translation_unavailable']!;
  }

  /// Replaces named placeholders in a translated string.
  ///
  /// Example:
  /// textWith('page_number_format', {'page': '12'})
  String textWith(
    String key,
    Map<String, Object?> arguments,
  ) {
    var result = text(key);

    for (final entry in arguments.entries) {
      result = result.replaceAll(
        '{${entry.key}}',
        entry.value?.toString() ?? '',
      );
    }

    return result;
  }

  /// Selects a plural form when plural keys are provided.
  ///
  /// Supported suffixes:
  /// _zero, _one, _two, _few, _many, _other.
  ///
  /// If the requested plural form is absent, the base key is used.
  String plural(
    String key,
    int count, {
    Map<String, Object?> arguments = const <String, Object?>{},
  }) {
    final category = _pluralCategory(count);
    final pluralKey = '${key}_$category';

    final selected =
        _currentCatalog.containsKey(pluralKey) ||
                _fallbackCatalog.containsKey(pluralKey)
            ? pluralKey
            : _currentCatalog.containsKey('${key}_other') ||
                    _fallbackCatalog.containsKey('${key}_other')
                ? '${key}_other'
                : key;

    final values = <String, Object?>{
      ...arguments,
      'count': count,
    };

    return textWith(selected, values);
  }

  String _pluralCategory(int count) {
    if (isArabic) {
      if (count == 0) return 'zero';
      if (count == 1) return 'one';
      if (count == 2) return 'two';

      final remainder = count.abs() % 100;

      if (remainder >= 3 && remainder <= 10) {
        return 'few';
      }

      if (remainder >= 11 && remainder <= 99) {
        return 'many';
      }

      return 'other';
    }

    if (isFrench) {
      return count == 0 || count == 1 ? 'one' : 'other';
    }

    return count == 1 ? 'one' : 'other';
  }

  // ---------------------------------------------------------------------------
  // TRANSLATION DIAGNOSTICS
  // ---------------------------------------------------------------------------

  bool hasTranslation(String key) {
    return _currentCatalog.containsKey(key.trim());
  }

  bool knowsKey(String key) {
    final normalizedKey = key.trim();

    for (final catalog in _translations.values) {
      if (catalog.containsKey(normalizedKey)) {
        return true;
      }
    }

    return false;
  }

  static bool isCompleteTranslation(String key) {
    final normalizedKey = key.trim();

    if (normalizedKey.isEmpty) {
      return false;
    }

    for (final languageCode in supportedLanguageCodes) {
      if (!(_translations[languageCode]
              ?.containsKey(normalizedKey) ??
          false)) {
        return false;
      }
    }

    return true;
  }

  static Set<String> get allTranslationKeys =>
      Set<String>.unmodifiable(
        _translations[defaultLanguageCode]!.keys,
      );

  static List<String> missingKeysFor(String languageCode) {
    final normalized = normalizeLanguageCode(languageCode);
    final referenceKeys = _translations[defaultLanguageCode]!.keys;
    final selectedKeys = _translations[normalized]!.keys;

    return referenceKeys
        .where((key) => !selectedKeys.contains(key))

        .toList(growable: false);
  }

  static double translationCoverage(String languageCode) {
    final normalized = normalizeLanguageCode(languageCode);
    final referenceCount =
        _translations[defaultLanguageCode]!.length;

    if (referenceCount == 0) {
      return 1;
    }

    final translatedCount = _translations[normalized]!.keys
        .where(
          (key) =>
              _translations[defaultLanguageCode]!.containsKey(key),
        )
        .length;

    return translatedCount / referenceCount;
  }

  static Map<String, double> get allTranslationCoverage =>
      Map<String, double>.unmodifiable({
        for (final code in supportedLanguageCodes)
          code: translationCoverage(code),
      });

  /// Resolves a domain error key without importing domain classes.
  String error(String localizationKey) => text(localizationKey);

  // ---------------------------------------------------------------------------
  // LANGUAGE SELECTION
  // ---------------------------------------------------------------------------

  String get selectLanguage => text('select_language');

  String get languageName => text('language');

  String get languageChanged => text('language_changed');

  String get languageChangeFailed => text('language_change_failed');

  String get arabicLanguage => text('language_ar');

  String get englishLanguage => text('language_en');

  String get frenchLanguage => text('language_fr');

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

  String get prayerTimesUnavailable =>
      text('prayer_times_unavailable');

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

  String get translationUnavailable =>
      text('translation_unavailable');

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

  String get locationUpdateFailed =>
      text('location_update_failed');

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

    const validKeys = <String>{
      'fajr',
      'sunrise',
      'dhuhr',
      'asr',
      'maghrib',
      'isha',
    };

    if (!validKeys.contains(normalized)) {
      return text('unavailable');
    }

    return text('prayer_$normalized');
  }

  // ---------------------------------------------------------------------------
  // QURAN INTERFACE
  // ---------------------------------------------------------------------------

  String get quranReading => text('quran_reading');

  String get continueReading => text('continue_reading');

  String get startReading => text('start_reading');

  String get resumeReading => text('resume_reading');

  String get surah => text('surah');

  String get surahs => text('surahs');

  String get juz => text('juz');

  String get page => text('page');

  String get ayah => text('ayah');

  String get bookmarks => text('bookmarks');

  String get bookmark => text('bookmark');

  String get addBookmark => text('add_bookmark');

  String get removeBookmark => text('remove_bookmark');

  String get lastRead => text('last_read');

  String get readingProgress => text('reading_progress');

  String get khatma => text('khatma');

  String get dailyReadingGoal => text('daily_reading_goal');

  String get pagesReadToday => text('pages_read_today');

  String get quranLoading => text('quran_loading');

  String get quranLoadFailed => text('quran_load_failed');

  String get quranSettings => text('quran_settings');

  String get translationLanguage => text('translation_language');

  String get showTranslation => text('show_translation');

  String get hideTranslation => text('hide_translation');

  String get recitation => text('recitation');

  String get playback => text('playback');

  String get quranOriginalTextNotice =>
      text('quran_original_text_notice');

  /// Prayer name lookup remains compatible with existing callers.
  ///
  /// Quran surah names will be connected to the authoritative Quran data
  /// source in the Quran integration stage. They must not be generated
  /// from guessed or machine-translated Arabic names.
}
