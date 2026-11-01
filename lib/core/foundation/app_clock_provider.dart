
import 'app_clock.dart';

/// Central owner of the application's clock instance.
///
/// The provider guarantees that all consumers accessing the same
/// provider instance receive the same AppClock instance.
///
/// Production applications should create one provider during
/// application bootstrap and inject it into dependent services.
final class AppClockProvider {
  AppClockProvider._(this._clock);

  static AppClockProvider? _instance;

  final AppClock _clock;

  /// Returns the centrally configured provider.
  ///
  /// Throws if the application has not initialized the provider.
  /// This prevents silently creating independent clocks throughout
  /// the application.
  static AppClockProvider get instance {
    final provider = _instance;

    if (provider == null) {
      throw StateError(
        'AppClockProvider has not been initialized. '
        'Initialize it during application bootstrap.',
      );
    }

    return provider;
  }

  /// Returns the clock managed by this provider.
  AppClock get clock => _clock;

  /// Returns the current civil time from the central clock.
  DateTime get now => _clock.now;

  /// Returns the current UTC instant from the central clock.
  DateTime get utcNow => _clock.utcNow;

  /// Returns the current monotonic timestamp in microseconds.
  int get monotonicNow => _clock.monotonicNow;

  /// Initializes the global provider exactly once.
  ///
  /// If [clock] is omitted, a production SystemAppClock is created.
  ///
  /// Repeated initialization is rejected to prevent accidental
  /// replacement of the application's time source.
  static AppClockProvider initialize({
    AppClock? clock,
  }) {
    if (_instance != null) {
      throw StateError(
        'AppClockProvider has already been initialized.',
      );
    }

    final provider = AppClockProvider._(
      clock ?? SystemAppClock(),
    );

    _instance = provider;
    return provider;
  }

  /// Creates an isolated provider for tests or independent
  /// application scopes without changing the global singleton.
  ///
  /// This factory is useful for injecting FixedAppClock instances
  /// into services under test.
  factory AppClockProvider.scoped({
    required AppClock clock,
  }) {
    return AppClockProvider._(clock);
  }

  /// Resets the global provider.
  ///
  /// This operation is intended exclusively for test teardown
  /// or controlled application lifecycle management.
  ///
  /// Production code must not reset the provider while services
  /// are using it.
  static void resetForTesting() {
    _instance = null;
  }

  /// Indicates whether the global provider has been initialized.
  static bool get isInitialized => _instance != null;
}
