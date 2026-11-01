
import 'package:adhan/adhan.dart';

/// Pure prayer-time calculation service.
///
/// Uses the date components supplied by the caller.
/// For timezone-aware global calculations, use
/// GlobalPrayerCalculationService instead.
class PrayerCalculationService {
  const PrayerCalculationService();

  /// Calculates prayer times for a location and calendar date.
  PrayerTimes calculate({
    required double latitude,
    required double longitude,
    required DateTime date,
    required CalculationMethod method,
    required Madhab madhab,
  }) {
    validateCoordinates(
      latitude: latitude,
      longitude: longitude,
    );

    _validateDate(date);

    final coordinates = Coordinates(
      latitude,
      longitude,
      validate: true,
    );

    final dateComponents = DateComponents(
      date.year,
      date.month,
      date.day,
    );

    final parameters = method.getParameters()
      ..madhab = madhab;

    return PrayerTimes(
      coordinates,
      dateComponents,
      parameters,
    );
  }

  /// Validates geographical coordinate boundaries.
  static void validateCoordinates({
    required double latitude,
    required double longitude,
  }) {
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

  /// Validates that the supplied date is a real calendar date.
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
        'Invalid month.',
      );
    }

    if (day < 1 || day > 31) {
      throw ArgumentError.value(
        day,
        'day',
        'Invalid day.',
      );
    }

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
        'date',
        'A valid calendar date is required.',
      );
    }
  }
}
