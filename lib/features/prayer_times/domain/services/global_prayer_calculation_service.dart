
import 'package:adhan/adhan.dart';
import 'package:timezone/timezone.dart' as tz;

/// Prayer times represented as actual instants in the selected
/// IANA timezone, not the phone's timezone.
class GlobalPrayerSchedule {
  final String timezoneId;
  final DateTime calculationDate;
  final Map<Prayer, tz.TZDateTime> _times;

  GlobalPrayerSchedule({
    required this.timezoneId,
    required this.calculationDate,
    required Map<Prayer, tz.TZDateTime> times,
  }) : _times = Map.unmodifiable(times);

  tz.TZDateTime? timeForPrayer(Prayer prayer) {
    return _times[prayer];
  }

  Map<Prayer, tz.TZDateTime> get allTimes => _times;
}

/// Calculates prayer instants in UTC and converts each instant
/// using the IANA timezone rules for that exact moment.
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

    final coordinates = Coordinates(
      latitude,
      longitude,
      validate: true,
    );

    final dateComponents = DateComponents(
      localDate.year,
      localDate.month,
      localDate.day,
    );

    final parameters = method.getParameters()
      ..madhab = madhab
      ..highLatitudeRule = highLatitudeRule;

    // Calculate absolute UTC instants. Never use the phone's
    // local timezone as the calculation timezone.
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
      calculationDate: DateTime(
        localDate.year,
        localDate.month,
        localDate.day,
      ),
      times: localTimes,
    );
  }

  static void _validateCoordinates(
    double latitude,
    double longitude,
  ) {
    if (!latitude.isFinite || !longitude.isFinite) {
      throw ArgumentError('Coordinates must be finite.');
    }

    if (latitude < -90 || latitude > 90) {
      throw ArgumentError.value(latitude, 'latitude');
    }

    if (longitude < -180 || longitude > 180) {
      throw ArgumentError.value(longitude, 'longitude');
    }
  }

  static void _validateDate(DateTime date) {
    if (date.year < 1 || date.year > 9999) {
      throw ArgumentError.value(date.year, 'year');
    }

    if (date.month < 1 || date.month > 12) {
      throw ArgumentError.value(date.month, 'month');
    }

    if (date.day < 1 || date.day > 31) {
      throw ArgumentError.value(date.day, 'day');
    }
  }

  static void _validateChronologicalOrder(
    Map<Prayer, tz.TZDateTime> times,
  ) {
    for (var i = 0; i < supportedPrayers.length - 1; i++) {
      final current = times[supportedPrayers[i]]!;
      final next = times[supportedPrayers[i + 1]]!;

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
