
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Provides timezone-safe date and time operations.
///
/// Requires an IANA timezone identifier, for example:
/// Africa/Casablanca
/// Europe/Paris
/// America/New_York
///
/// This service does not guess a timezone from GPS coordinates.
class TimeZoneService {
  TimeZoneService._();

  static final TimeZoneService instance =
      TimeZoneService._();

  static bool _initialized = false;

  /// Initialize the timezone database once.
  void initialize() {
    if (_initialized) return;

    tz_data.initializeTimeZones();

    _initialized = true;
  }

  bool get isInitialized => _initialized;

  /// Resolve and validate an IANA timezone identifier.
  tz.Location getLocation(String timezoneId) {
    _ensureInitialized();

    final normalizedId = timezoneId.trim();

    if (normalizedId.isEmpty) {
      throw ArgumentError(
        'Timezone identifier cannot be empty.',
      );
    }

    try {
      return tz.getLocation(normalizedId);
    } catch (_) {
      throw ArgumentError(
        'Unknown timezone identifier: $normalizedId',
      );
    }
  }

  /// Return the current time in the requested timezone.
  tz.TZDateTime now(String timezoneId) {
    final location = getLocation(timezoneId);

    return tz.TZDateTime.now(location);
  }

  /// Convert an absolute DateTime instant into a timezone.
  ///
  /// The instant is preserved; only its displayed timezone changes.
  tz.TZDateTime convert(
    DateTime instant,
    String timezoneId,
  ) {
    final location = getLocation(timezoneId);

    return tz.TZDateTime.from(
      instant,
      location,
    );
  }

  /// Create a timezone-aware date from calendar components.
  tz.TZDateTime createDateTime({
    required String timezoneId,
    required int year,
    required int month,
    required int day,
    int hour = 0,
    int minute = 0,
    int second = 0,
  }) {
    final location = getLocation(timezoneId);

    if (year < 1 || year > 9999) {
      throw ArgumentError('Invalid year.');
    }

    if (month < 1 || month > 12) {
      throw ArgumentError('Invalid month.');
    }

    if (day < 1 || day > 31) {
      throw ArgumentError('Invalid day.');
    }

    if (hour < 0 || hour > 23) {
      throw ArgumentError('Invalid hour.');
    }

    if (minute < 0 || minute > 59) {
      throw ArgumentError('Invalid minute.');
    }

    if (second < 0 || second > 59) {
      throw ArgumentError('Invalid second.');
    }

    final result = tz.TZDateTime(
      location,
      year,
      month,
      day,
      hour,
      minute,
      second,
    );

    // Reject invalid calendar dates such as February 31.
    if (result.year != year ||
        result.month != month ||
        result.day != day ||
        result.hour != hour ||
        result.minute != minute ||
        result.second != second) {
      throw ArgumentError(
        'Invalid local calendar date or time.',
      );
    }

    return result;
  }

  /// Get the beginning of the local calendar day.
  tz.TZDateTime startOfDay(
    DateTime instant,
    String timezoneId,
  ) {
    final local = convert(
      instant,
      timezoneId,
    );

    return tz.TZDateTime(
      local.location,
      local.year,
      local.month,
      local.day,
    );
  }

  /// Get the beginning of the next local calendar day.
  ///
  /// This uses calendar arithmetic, not a fixed 24-hour duration.
  /// Therefore, daylight-saving transitions are respected.
  tz.TZDateTime startOfNextDay(
    DateTime instant,
    String timezoneId,
  ) {
    final local = convert(
      instant,
      timezoneId,
    );

    return tz.TZDateTime(
      local.location,
      local.year,
      local.month,
      local.day + 1,
    );
  }

  /// Compare two absolute instants by their local calendar date.
  bool isSameLocalDate({
    required DateTime first,
    required DateTime second,
    required String timezoneId,
  }) {
    final firstLocal = convert(
      first,
      timezoneId,
    );

    final secondLocal = convert(
      second,
      timezoneId,
    );

    return firstLocal.year == secondLocal.year &&
        firstLocal.month == secondLocal.month &&
        firstLocal.day == secondLocal.day;
  }

  /// Return the UTC offset at a specific instant.
  Duration utcOffset(
    DateTime instant,
    String timezoneId,
  ) {
    return convert(
      instant,
      timezoneId,
    ).timeZoneOffset;
  }

  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError(
        'TimeZoneService.initialize() must be called first.',
      );
    }
  }
}
