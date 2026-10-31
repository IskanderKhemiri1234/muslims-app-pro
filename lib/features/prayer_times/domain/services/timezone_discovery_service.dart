
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../data/datasources/timezone_lookup_datasource.dart';

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

/// Converts geographic coordinates into a validated IANA timezone.
class TimezoneDiscoveryService {
  final TimezoneLookupDataSource dataSource;

  static bool _timezoneDatabaseInitialized = false;

  TimezoneDiscoveryService({
    required this.dataSource,
  });

  Future<DiscoveredTimezone> discover({
    required double latitude,
    required double longitude,
  }) async {
    _validateCoordinates(latitude, longitude);
    _initializeTimezoneDatabase();

    final result = await dataSource.lookup(
      latitude: latitude,
      longitude: longitude,
    );

    final timezoneId = result.timezoneId.trim();

    if (!_isValidTimezoneId(timezoneId)) {
      throw const FormatException(
        'The provider returned an invalid IANA timezone ID.',
      );
    }

    final tz.Location location;

    try {
      location = tz.getLocation(timezoneId);
    } on Exception {
      throw FormatException(
        'Timezone "$timezoneId" is not available in the local timezone database.',
      );
    }

    return DiscoveredTimezone(
      timezoneId: timezoneId,
      countryCode: result.countryCode,
      location: location,
    );
  }

  static void _initializeTimezoneDatabase() {
    if (_timezoneDatabaseInitialized) return;

    tz_data.initializeTimeZones();
    _timezoneDatabaseInitialized = true;
  }

  static bool _isValidTimezoneId(String value) {
    if (value.isEmpty || value.length > 100) {
      return false;
    }

    if (value.startsWith('/') || value.endsWith('/')) {
      return false;
    }

    if (value.contains('..') || value.contains('\\')) {
      return false;
    }

    return RegExp(
      r'^[A-Za-z0-9_+-]+(?:/[A-Za-z0-9_+-]+)*$',
    ).hasMatch(value);
  }

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
}
