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

  final String timezoneId;

  final String? countryCode;

  final tz.Location location;
}

/// Domain-level timezone discovery adapter.
///
/// Delegates timezone resolution to the shared Core service.
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

    final resolved = await _resolver.discover(
      latitude: latitude,
      longitude: longitude,
    );

    final timezoneId = resolved.timezoneId?.trim();
    final location = resolved.location;
    final countryCode = resolved.countryCode?.trim();

    if (timezoneId == null ||
        timezoneId.isEmpty ||
        location == null) {
      throw StateError(
        'The timezone resolver returned incomplete timezone data.',
      );
    }

    if (timezoneId != location.name) {
      throw StateError(
        'The timezone resolver returned an invalid timezone.',
      );
    }

    return DiscoveredTimezone(
      timezoneId: timezoneId,
      countryCode:
          countryCode == null || countryCode.isEmpty
              ? null
              : countryCode,
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
