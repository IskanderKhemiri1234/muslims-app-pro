import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone_finder/timezone_finder.dart';

/// Resolves GPS coordinates to an IANA timezone.
///
/// Works locally on supported mobile platforms.
/// Coordinates are not sent to an external service.
class TimezoneDiscoveryService {
  static Future<void>? _initialization;

  Future<void> initialize() async {
    final pending = _initialization ??= _initializeDatabase();

    try {
      await pending;
    } catch (_) {
      _initialization = null;
      rethrow;
    }
  }

  Future<void> _initializeDatabase() async {
    tz_data.initializeTimeZones();
    await ensurePreloaded();
  }

  /// Returns null when no timezone polygon covers the coordinates.
  Future<tz.Location?> discover({
    required double latitude,
    required double longitude,
  }) async {
    _validateCoordinates(
      latitude: latitude,
      longitude: longitude,
    );

    await initialize();

    // timezone_finder expects longitude first, then latitude.
    return findLocation(longitude, latitude);
  }

  /// Gets the current instant expressed in the discovered timezone.
  Future<tz.TZDateTime> nowAt(tz.Location location) async {
    await initialize();
    return tz.TZDateTime.now(location);
  }

  static void _validateCoordinates({
    required double latitude,
    required double longitude,
  }) {
    if (!latitude.isFinite || !longitude.isFinite) {
      throw ArgumentError('Coordinates must be finite.');
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
}
