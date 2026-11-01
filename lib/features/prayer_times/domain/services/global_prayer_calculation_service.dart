
import 'package:adhan/adhan.dart';
import 'package:timezone/timezone.dart' as tz;

/// Immutable prayer schedule represented as absolute instants
/// converted into the selected IANA timezone.
class GlobalPrayerSchedule {
  GlobalPrayerSchedule({
    required this.timezoneId,
    required this.calculationDate,
    required Map<Prayer, tz.TZDateTime> times,
  }) : _times = Map<Prayer, tz.TZDateTime>.unmodifiable(times);

  /// IANA timezone identifier, for example: Africa/Casablanca.
  final String timezoneId;

  /// Date-only value represented at UTC midnight.
  ///
  /// This is a calendar date, not a prayer instant.
  final DateTime calculationDate;

  final Map<Prayer, tz.TZDateTime> _times;

  /// Returns the prayer instant in the selected timezone.
  tz.TZDateTime? timeForPrayer(Prayer prayer) {
    return _times[prayer];
  }

  /// Returns an immutable map of all calculated prayer times.
  Map<Prayer, tz.TZDateTime> get allTimes => _times;
}

/// Calculates prayer instants independently of the device timezone.
///
/// The supplied localDate must represent the calendar date in the
/// target timezone, not necessarily the device's calendar date.
class GlobalPrayerCalculationService {
  const GlobalPrayerCalculationService();

  static const List<Prayer> supportedPrayers = [
    Prayer.fajr,
    Prayer.sunrise,
    Prayer.dhuhr,
    Prayer.asr,
    Prayer.maghrib,
    Prayer.isha,
  ];

  GlobalPrayerSchedule calculate({
    required double latitude,
    required double longitude,
    required DateTime localDate,
    required tz.Location timezone,
    required CalculationMethod method,
    required Madhab madhab,
    HighLatitudeRule highLatitudeRule =
        HighLatitudeRule.middle_of_the_night,
  }) {
    _validateCoordinates(latitude, longitude);
    _validateDate(localDate);
    _validateTimezone(timezone);

    final coordinates = Coordinates(
      latitude,
      longitude,
      validate: true,
    );

    // Extract the intended calendar date without inheriting
    // the device's timezone or UTC offset.
    final dateComponents = DateComponents(
      localDate.year,
      localDate.month,
      localDate.day,
    );

    final parameters = method.getParameters()
      ..madhab = madhab
      ..highLatitudeRule = highLatitudeRule;

    // Calculate absolute UTC instants.
    final utcSchedule = PrayerTimes.utc(
      coordinates,
      dateComponents,
      parameters,
    );

    final localTimes = <Prayer, tz.TZDateTime>{};

    for (final prayer in supportedPrayers) {
      final utcTime = utcSchedule.timeForPrayer(prayer);

      if (utcTime == null) {
        throw StateError(
          'The calculation engine did not return $prayer.',
        );
      }

      localTimes[prayer] = tz.TZDateTime.from(
        utcTime,
        timezone,
      );
    }

    _validateChronologicalOrder(localTimes);

    return GlobalPrayerSchedule(
      timezoneId: timezone.name,
      calculationDate: DateTime.utc(
        localDate.year,
        localDate.month,
        localDate.day,
      ),
      times: localTimes,
    );
  }

  // --------------------------------------------------
  // VALIDATION
  // --------------------------------------------------

  static void _validateCoordinates(
    double latitude,
    double longitude,
  ) {
    if (!latitude.isFinite || !longitude.isFinite) {
      throw ArgumentError(
        'Coordinates must be finite numbers.',
      );
    }

    if (latitude < -90 || latitude > 90) {
      throw ArgumentError.value(
        latitude,
        'latitude',
        'Latitude must be between -90 and 90.',
      );
    }

    if (longitude < -180 || longitude > 180) {
      throw ArgumentError.value(
        longitude,
        'longitude',
        'Longitude must be between -180 and 180.',
      );
    }
  }

  static void _validateDate(DateTime date) {
    final year = date.year;
    final month = date.month;
    final day = date.day;

    if (year < 1 || year > 9999) {
      throw ArgumentError.value(year, 'year');
    }

    final normalized = DateTime.utc(year, month, day);

    // DateTime normalizes invalid dates, so compare the components.
    if (normalized.year != year ||
        normalized.month != month ||
        normalized.day != day) {
      throw ArgumentError.value(
        date,
        'localDate',
        'A valid calendar date is required.',
      );
    }
  }

  static void _validateTimezone(tz.Location timezone) {
    if (timezone.name.trim().isEmpty) {
      throw ArgumentError.value(
        timezone.name,
        'timezone',
        'A valid IANA timezone is required.',
      );
    }
  }

  static void _validateChronologicalOrder(
    Map<Prayer, tz.TZDateTime> times,
  ) {
    for (var i = 0; i < supportedPrayers.length - 1; i++) {
      final current = times[supportedPrayers[i]];
      final next = times[supportedPrayers[i + 1]];

      if (current == null || next == null) {
        throw StateError(
          'A required prayer time is missing.',
        );
      }

      if (!current.isBefore(next)) {
        throw StateError(
          'Invalid prayer sequence between '
          '${supportedPrayers[i]} and '
          '${supportedPrayers[i + 1]}.',
        );
      }
    }
  }
}
