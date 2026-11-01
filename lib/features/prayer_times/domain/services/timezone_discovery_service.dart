
import 'package:timezone/timezone.dart' as tz;

import '../../../../core/services/timezone_discovery_service.dart'
    as local_timezone;

/// A validated timezone discovered from geographic coordinates.
class DiscoveredTimezone {
  const DiscoveredTimezone({
    required this.timezoneId,
    required this.countryCode,
    required this.location,
  });

  /// IANA timezone identifier, for example: Africa/Casablanca.
  final String timezoneId;

  /// ISO 3166-1 alpha-2 country code, if available.
  ///
  /// Null means the country could not be reliably determined.
  final String? countryCode;

  /// Resolved timezone database location.
  final tz.Location location;
}

/// Resolves geographic coordinates using the shared timezone database.
///
/// This class delegates timezone discovery to the core service.
/// It does not perform network requests.
class TimezoneDiscoveryService {
  TimezoneDiscoveryService({
    local_timezone.TimezoneDiscoveryService? resolver,
  }) : _resolver =
            resolver ?? local_timezone.TimezoneDiscoveryService();

  final local_timezone.TimezoneDiscoveryService _resolver;

  Future<DiscoveredTimezone> discover({
    required double latitude,
    required double longitude,
  }) async {
    _validateCoordinates(
      latitude: latitude,
      longitude: longitude,
    );

    final location = await _resolver.discover(
      latitude: latitude,
      longitude: longitude,
    );

    if (location == null) {
      throw StateError(
        'No timezone boundary was found for these coordinates. '
        'A manual timezone selection may be required.',
      );
    }

    final timezoneId = location.name.trim();

    if (timezoneId.isEmpty) {
      throw StateError(
        'The timezone resolver returned an invalid timezone.',
      );
    }

    return DiscoveredTimezone(
      timezoneId: timezoneId,
      countryCode: null,
      location: location,
    );
  }

  static void _validateCoordinates({
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
}
