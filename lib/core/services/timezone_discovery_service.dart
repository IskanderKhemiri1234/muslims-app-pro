import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone_finder/timezone_finder.dart';

/// Represents a successfully discovered timezone.
class DiscoveredTimezone {
  const DiscoveredTimezone({
    required this.location,
    this.countryCode,
  });

  /// IANA timezone location.
  final tz.Location location;

  /// Country code when independently available.
  ///
  /// The timezone name alone is not sufficient to determine
  /// a reliable ISO country code.
  final String? countryCode;

  /// Canonical IANA timezone identifier.
  String get timezoneId => location.name;
}

/// Resolves GPS coordinates to an IANA timezone.
///
/// All discovery operations are performed locally.
/// Coordinates are not sent to an external service.
class TimezoneDiscoveryService {
  static Future<void>? _initialization;

  /// Initializes the timezone database once.
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

  /// Discovers the timezone covering the supplied coordinates.
  ///
  /// Returns null when no timezone polygon covers the coordinates.
  Future<DiscoveredTimezone?> discover({
    required double latitude,
    required double longitude,
  }) async {
    _validateCoordinates(
      latitude: latitude,
      longitude: longitude,
    );

    await initialize();

    // timezone_finder expects longitude first, latitude second.
    final location = findLocation(
      longitude,
      latitude,
    );

    if (location == null) {
      return null;
    }

    return DiscoveredTimezone(
      location: location,
    );
  }

  /// Gets the current instant expressed in the discovered timezone.
  Future<tz.TZDateTime> nowAt(
    tz.Location location,
  ) async {
    await initialize();

    return tz.TZDateTime.now(location);
  }

  /// Validates geographic coordinates.
  static void _validateCoordinates({
    required double latitude,
    required double longitude,
  }) {
    if (!latitude.isFinite || !longitude.isFinite) {
      throw ArgumentError(
        'Coordinates must be finite.',
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
}
