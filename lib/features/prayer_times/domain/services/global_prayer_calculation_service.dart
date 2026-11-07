
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

  /// Calendar date represented at UTC midnight.
  ///
  /// This is a date-only value, not a prayer instant.
  final DateTime calculationDate;

  final Map<Prayer, tz.TZDateTime> _times;

  /// Returns the prayer instant in the selected timezone.
  tz.TZDateTime? timeForPrayer(Prayer prayer) => _times[prayer];

  /// Returns an immutable map of all calculated prayer times.
  Map<Prayer, tz.TZDateTime> get allTimes => _times;

  /// Whether the schedule contains every required prayer event.
  bool get isComplete =>
      GlobalPrayerCalculationService.supportedPrayers.every(
        _times.containsKey,
      );
}

/// Calculates prayer instants independently of the device timezone.
///
/// The supplied [localDate] must represent the calendar date in the
/// target timezone, not necessarily the device's calendar date.
///
/// This service does not claim universal religious or observational
/// precision: results depend on the selected calculation method,
/// madhab, high-latitude rule and the accuracy of the supplied location.
class GlobalPrayerCalculationService {
  const GlobalPrayerCalculationService();

  static const List<Prayer> supportedPrayers = <Prayer>[
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
    // the device timezone or its UTC offset.
    final dateComponents = DateComponents(
      localDate.year,
      localDate.month,
      localDate.day,
    );

    final parameters = method.getParameters()
      ..madhab = madhab
      ..highLatitudeRule = highLatitudeRule;

    // Calculate absolute instants using the UTC calculation API.
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

      final localTime = tz.TZDateTime.from(
        utcTime,
        timezone,
      );

      localTimes[prayer] = localTime;
    }

    _validateScheduleCompleteness(localTimes);
    _validateChronologicalOrder(localTimes);

    final schedule = GlobalPrayerSchedule(
      timezoneId: timezone.name,
      calculationDate: DateTime.utc(
        localDate.year,
        localDate.month,
        localDate.day,
      ),
      times: localTimes,
    );

    if (!schedule.isComplete) {
      throw StateError(
        'The calculated prayer schedule is incomplete.',
      );
    }

    return schedule;
  }

  // ---------------------------------------------------------------------------
  // INPUT VALIDATION
  // ---------------------------------------------------------------------------

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
      throw ArgumentError.value(
        year,
        'year',
        'Year is outside the supported range.',
      );
    }

    if (month < 1 || month > 12) {
      throw ArgumentError.value(
        month,
        'month',
        'Month must be between 1 and 12.',
      );
    }

    if (day < 1 || day > 31) {
      throw ArgumentError.value(
        day,
        'day',
        'Day must be between 1 and 31.',
      );
    }

    // DateTime normalizes invalid dates, so compare the components.
    final normalized = DateTime.utc(
      year,
      month,
      day,
    );

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
    final timezoneId = timezone.name.trim();

    if (timezoneId.isEmpty) {
      throw ArgumentError.value(
        timezone.name,
        'timezone',
        'A valid IANA timezone is required.',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // RESULT VALIDATION
  // ---------------------------------------------------------------------------

  static void _validateScheduleCompleteness(
    Map<Prayer, tz.TZDateTime> times,
  ) {
    for (final prayer in supportedPrayers) {
      if (!times.containsKey(prayer)) {
        throw StateError(
          'A required prayer time is missing: $prayer.',
        );
      }
    }
  }

  /// Ensures all daily prayer events follow the expected sequence.
  ///
  /// The order includes sunrise because it is a significant boundary
  /// in the daily prayer schedule.
  static void _validateChronologicalOrder(
    Map<Prayer, tz.TZDateTime> times,
  ) {
    for (var index = 0;
        index < supportedPrayers.length - 1;
        index++) {
      final currentPrayer = supportedPrayers[index];
      final nextPrayer = supportedPrayers[index + 1];

      final currentTime = times[currentPrayer];
      final nextTime = times[nextPrayer];

      if (currentTime == null || nextTime == null) {
        throw StateError(
          'A required prayer time is missing.',
        );
      }

      if (!currentTime.isBefore(nextTime)) {
        throw StateError(
          'Invalid prayer sequence between '
          '$currentPrayer and $nextPrayer.',
        );
      }
    }
  }
}
