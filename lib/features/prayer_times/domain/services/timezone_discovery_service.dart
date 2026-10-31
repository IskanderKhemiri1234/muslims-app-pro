import 'package:timezone/timezone.dart' as tz;

import '../../../../core/services/timezone_discovery_service.dart'
    as local_timezone;

/// A validated timezone discovered from geographic coordinates.
class DiscoveredTimezone {
  final String timezoneId;
  final String? countryCode;
  final tz.Location location;

  const DiscoveredTimezone({
    required this.timezoneId,
    required this.countryCode,
    required this.location,
  });
}

/// Resolves geographic coordinates using the local timezone database.
class TimezoneDiscoveryService {
  final local_timezone.TimezoneDiscoveryService _resolver;

  TimezoneDiscoveryService({
    local_timezone.TimezoneDiscoveryService? resolver,
  }) : _resolver =
            resolver ?? local_timezone.TimezoneDiscoveryService();

  Future<DiscoveredTimezone> discover({
    required double latitude,
    required double longitude,
  }) async {
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

    return DiscoveredTimezone(
      timezoneId: location.name,
      countryCode: null,
      location: location,
    );
  }
}
