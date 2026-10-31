
import 'package:adhan/adhan.dart';

/// Pure prayer-time calculation service.
class PrayerCalculationService {
  const PrayerCalculationService();

  /// Calculate prayer times for a specific location and date.
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
    );

    final dateComponents = DateComponents.from(date);
    final parameters = method.getParameters();

    parameters.madhab = madhab;

    return PrayerTimes(
      coordinates,
      dateComponents,
      parameters,
    );
  }

  /// Validates geographical coordinate boundaries.
  ///
  /// Valid coordinates do not guarantee that astronomical
  /// prayer times can be calculated at every location and date.
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

  static void _validateDate(DateTime date) {
    if (date.year < 1 || date.year > 9999) {
      throw ArgumentError.value(
        date.year,
        'year',
        'Year is outside the supported range.',
      );
    }

    if (date.month < 1 || date.month > 12) {
      throw ArgumentError.value(
        date.month,
        'month',
        'Invalid month.',
      );
    }

    if (date.day < 1 || date.day > 31) {
      throw ArgumentError.value(
        date.day,
        'day',
        'Invalid day.',
      );
    }
  }
}
