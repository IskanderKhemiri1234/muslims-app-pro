
import 'package:adhan/adhan.dart';

/// Pure prayer-time calculation service.
///
/// This service does not access GPS, storage, notifications,
/// application state, or the device clock.
///
/// The caller must supply the intended calendar date.
class PrayerCalculationService {
  const PrayerCalculationService();

  /// Calculate prayer times for a specific location and date.
  ///
  /// [date] supplies the calendar date used for calculation.
  /// When using a timezone-aware date, pass its local calendar
  /// components through this DateTime-compatible parameter.
  PrayerTimes calculate({
    required double latitude,
    required double longitude,
    required DateTime date,
    required CalculationMethod method,
    required Madhab madhab,
  }) {
    _validateCoordinates(latitude, longitude);
    _validateDate(date);

    final coordinates = Coordinates(
      latitude,
      longitude,
    );

    final dateComponents = DateComponents.from(date);

    // Create fresh parameters for every calculation.
    // This prevents one calculation from changing another.
    final parameters = method.getParameters();

    parameters.madhab = madhab;

    return PrayerTimes(
      coordinates,
      dateComponents,
      parameters,
    );
  }

  /// Validate geographical coordinates.
  static void _validateCoordinates(
    double latitude,
    double longitude,
  ) {
    if (!latitude.isFinite ||
        !longitude.isFinite) {
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

  /// Validate the calendar date.
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
