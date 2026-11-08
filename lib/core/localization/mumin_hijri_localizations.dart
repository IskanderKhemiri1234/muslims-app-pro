
import 'mumin_localizations.dart';

/// Centralized Hijri calendar translations for Mumin Pro.
///
/// Keeps Hijri month names and calendar-specific labels
/// consistent across the home page and calendar feature.
abstract final class MuminHijriLocalizations {
  static const List<String> _arabicMonths = [
    'محرّم',
    'صفر',
    'ربيع الأول',
    'ربيع الآخر',
    'جمادى الأولى',
    'جمادى الآخرة',
    'رجب',
    'شعبان',
    'رمضان',
    'شوّال',
    'ذو القعدة',
    'ذو الحجة',
  ];

  static const List<String> _englishMonths = [
    'Muharram',
    'Safar',
    'Rabi al-Awwal',
    'Rabi al-Thani',
    'Jumada al-Awwal',
    'Jumada al-Thani',
    'Rajab',
    'Sha’ban',
    'Ramadan',
    'Shawwal',
    'Dhu al-Qi’dah',
    'Dhu al-Hijjah',
  ];

  static const List<String> _frenchMonths = [
    'Mouharram',
    'Safar',
    'Rabi al-Awwal',
    'Rabi al-Thani',
    'Joumada al-Oula',
    'Joumada al-Akhira',
    'Rajab',
    'Chaabane',
    'Ramadan',
    'Chawwal',
    'Dhou al-Qi’da',
    'Dhou al-Hijja',
  ];

  static String monthName(
    MuminLocalizations localizations,
    int month,
  ) {
    if (month < 1 || month > 12) {
      return localizations.text('unavailable');
    }

    final months = switch (localizations.languageCode) {
      'en' => _englishMonths,
      'fr' => _frenchMonths,
      _ => _arabicMonths,
    };

    return months[month - 1];
  }

  static String get titleArabic => 'التقويم الهجري';

  static String title(MuminLocalizations localizations) {
    return switch (localizations.languageCode) {
      'en' => 'Hijri calendar',
      'fr' => 'Calendrier hégirien',
      _ => titleArabic,
    };
  }

  static String estimatedLabel(
    MuminLocalizations localizations,
  ) {
    return switch (localizations.languageCode) {
      'en' => 'Calculated date — may differ from local moon sighting',
      'fr' => 'Date calculée — peut différer de l’observation locale du croissant',
      _ => 'تاريخ حسابي تقديري وقد يختلف عن إعلان رؤية الهلال محلياً',
    };
  }

  static String todayLabel(
    MuminLocalizations localizations,
  ) {
    return switch (localizations.languageCode) {
      'en' => 'Today in Hijri',
      'fr' => 'Aujourd’hui en calendrier hégirien',
      _ => 'تاريخ اليوم الهجري',
    };
  }

  static String locationLabel(
    MuminLocalizations localizations,
  ) {
    return switch (localizations.languageCode) {
      'en' => 'Based on your local date',
      'fr' => 'Selon votre date locale',
      _ => 'وفق التاريخ المحلي لجهازك',
    };
  }
}
