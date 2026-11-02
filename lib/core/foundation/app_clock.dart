
/// Provides an injectable source of civil and monotonic time.
///
/// Wall-clock time represents the current civil date and time.
/// Monotonic time represents elapsed time and must not move backwards
/// when the device's civil clock is adjusted.
///
/// Implementations must document the epoch and unit used by
/// [monotonicNow].
abstract interface class AppClock {
  /// Returns the current civil time.
  ///
  /// The returned DateTime represents the system's current local
  /// civil time for production clocks.
  DateTime get now;

  /// Returns the current UTC instant.
  ///
  /// This is derived from [now] to keep the source consistent.
  DateTime get utcNow => now.toUtc();

  /// Returns a monotonic timestamp in microseconds.
  ///
  /// The value has an arbitrary origin. Only differences between
  /// readings from the same clock instance are meaningful.
  int get monotonicNow;
}

/// Production clock backed by the Dart runtime.
///
/// This implementation uses the system wall clock for civil time
/// and Stopwatch for monotonic elapsed-time measurements.
final class SystemAppClock implements AppClock {
  SystemAppClock() : _stopwatch = Stopwatch() {
    _stopwatch.start();
  }

  final Stopwatch _stopwatch;

  @override
  DateTime get now => DateTime.now();

  /// Returns the current instant in UTC.
  ///
  /// Explicitly implemented because this class uses `implements`
  /// rather than inheriting the default interface implementation.
  @override
  DateTime get utcNow => now.toUtc();

  @override
  int get monotonicNow => _stopwatch.elapsedMicroseconds;
}

/// A deterministic clock for tests and controlled simulations.
///
/// The wall clock and monotonic clock can be advanced independently.
/// This allows tests to simulate device clock corrections without
/// corrupting elapsed-time measurements.
final class FixedAppClock implements AppClock {
  FixedAppClock({
    required DateTime initialTime,
    int initialMonotonicMicroseconds = 0,
  })  : _currentTime = initialTime,
        _monotonicMicroseconds = initialMonotonicMicroseconds {
    if (initialMonotonicMicroseconds < 0) {
      throw ArgumentError.value(
        initialMonotonicMicroseconds,
        'initialMonotonicMicroseconds',
        'Must not be negative.',
      );
    }
  }

  DateTime _currentTime;
  int _monotonicMicroseconds;

  @override
  DateTime get now => _currentTime;

  /// Returns the current simulated instant in UTC.
  @override
  DateTime get utcNow => now.toUtc();

  @override
  int get monotonicNow => _monotonicMicroseconds;

  /// Replaces the civil clock without changing monotonic time.
  ///
  /// Useful for simulating manual clock changes and timezone-related
  /// civil-time transitions in tests.
  void setWallTime(DateTime value) {
    _currentTime = value;
  }

  /// Advances civil time by [duration].
  ///
  /// Monotonic time is intentionally unchanged.
  void advanceWallTime(Duration duration) {
    _currentTime = _currentTime.add(duration);
  }

  /// Moves civil time by [duration].
  ///
  /// Negative durations are allowed to simulate clock corrections.
  void adjustWallTime(Duration duration) {
    _currentTime = _currentTime.add(duration);
  }

  /// Advances monotonic time by [duration].
  ///
  /// Negative durations are rejected because a monotonic clock
  /// must never move backwards.
  void advanceMonotonic(Duration duration) {
    if (duration.isNegative) {
      throw ArgumentError.value(
        duration,
        'duration',
        'Monotonic time cannot move backwards.',
      );
    }

    _monotonicMicroseconds += duration.inMicroseconds;
  }

  /// Advances both civil and monotonic time by the same duration.
  ///
  /// Negative durations are rejected to preserve monotonic ordering.
  void elapse(Duration duration) {
    if (duration.isNegative) {
      throw ArgumentError.value(
        duration,
        'duration',
        'Elapsed time cannot be negative.',
      );
    }

    _currentTime = _currentTime.add(duration);
    _monotonicMicroseconds += duration.inMicroseconds;
  }

  /// Resets the clock to a new civil time and monotonic origin.
  ///
  /// This should be used only when starting a new test scenario.
  void reset({
    required DateTime wallTime,
    int monotonicMicroseconds = 0,
  }) {
    if (monotonicMicroseconds < 0) {
      throw ArgumentError.value(
        monotonicMicroseconds,
        'monotonicMicroseconds',
        'Must not be negative.',
      );
    }

    _currentTime = wallTime;
    _monotonicMicroseconds = monotonicMicroseconds;
  }
}
