
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Timezone-safe date and time operations.
///
/// Uses IANA timezone identifiers such as:
/// Africa/Casablanca
/// Europe/Paris
/// America/New_York
///
/// GPS coordinates are intentionally not converted into timezones here.
class TimeZoneService {
  TimeZoneService._();

  static final TimeZoneService instance = TimeZoneService._();

  static bool _initialized = false;

  /// Initializes the IANA timezone database exactly once.
  void initialize() {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    _initialized = true;
  }

  bool get isInitialized => _initialized;

  /// Resolves and validates an IANA timezone identifier.
  tz.Location getLocation(String timezoneId) {
    _ensureInitialized();

    final normalizedId = timezoneId.trim();

    if (normalizedId.isEmpty) {
      throw ArgumentError.value(
        timezoneId,
        'timezoneId',
        'Timezone identifier cannot be empty.',
      );
    }

    try {
      return tz.getLocation(normalizedId);
    } on Exception {
      throw ArgumentError.value(
        normalizedId,
        'timezoneId',
        'Unknown IANA timezone identifier.',
      );
    }
  }

  /// Returns the current time in the requested timezone.
  tz.TZDateTime now(String timezoneId) {
    return tz.TZDateTime.now(
      getLocation(timezoneId),
    );
  }

  /// Converts an absolute instant into the requested timezone.
  ///
  /// The represented instant remains unchanged.
  tz.TZDateTime convert(
    DateTime instant,
    String timezoneId,
  ) {
    return tz.TZDateTime.from(
      instant,
      getLocation(timezoneId),
    );
  }

  /// Creates a timezone-aware local date and time.
  ///
  /// Note: ambiguous or nonexistent local times during DST transitions
  /// follow the timezone package's constructor behavior.
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
      throw ArgumentError.value(year, 'year');
    }

    if (month < 1 || month > 12) {
      throw ArgumentError.value(month, 'month');
    }

    if (day < 1 || day > _daysInMonth(year, month)) {
      throw ArgumentError.value(day, 'day');
    }

    if (hour < 0 || hour > 23) {
      throw ArgumentError.value(hour, 'hour');
    }

    if (minute < 0 || minute > 59) {
      throw ArgumentError.value(minute, 'minute');
    }

    if (second < 0 || second > 59) {
      throw ArgumentError.value(second, 'second');
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

    // Detect normalization caused by invalid or nonexistent local time.
    if (result.year != year ||
        result.month != month ||
        result.day != day ||
        result.hour != hour ||
        result.minute != minute ||
        result.second != second) {
      throw ArgumentError(
        'The requested local date or time is invalid '
        'in timezone $timezoneId.',
      );
    }

    return result;
  }

  /// Returns the beginning of the local calendar day.
  tz.TZDateTime startOfDay(
    DateTime instant,
    String timezoneId,
  ) {
    final local = convert(instant, timezoneId);

    return tz.TZDateTime(
      local.location,
      local.year,
      local.month,
      local.day,
    );
  }

  /// Returns the beginning of the next local calendar day.
  ///
  /// Uses calendar arithmetic instead of adding 24 hours.
  tz.TZDateTime startOfNextDay(
    DateTime instant,
    String timezoneId,
  ) {
    final local = convert(instant, timezoneId);

    return tz.TZDateTime(
      local.location,
      local.year,
      local.month,
      local.day + 1,
    );
  }

  /// Compares two instants using their local calendar dates.
  bool isSameLocalDate({
    required DateTime first,
    required DateTime second,
    required String timezoneId,
  }) {
    final location = getLocation(timezoneId);

    final firstLocal = tz.TZDateTime.from(first, location);
    final secondLocal = tz.TZDateTime.from(second, location);

    return firstLocal.year == secondLocal.year &&
        firstLocal.month == secondLocal.month &&
        firstLocal.day == secondLocal.day;
  }

  /// Returns the UTC offset at the requested instant.
  Duration utcOffset(
    DateTime instant,
    String timezoneId,
  ) {
    return convert(
      instant,
      timezoneId,
    ).timeZoneOffset;
  }

  static int _daysInMonth(int year, int month) {
    final firstDayOfNextMonth = month == 12
        ? DateTime(year + 1, 1, 1)
        : DateTime(year, month + 1, 1);

    return firstDayOfNextMonth
        .subtract(const Duration(days: 1))
        .day;
  }

  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError(
        'Call TimeZoneService.initialize() before using timezone operations.',
      );
    }
  }
}
