
/// Defines the clock contract used by scope-aware execution diagnostics.
///
/// The clock exposes two independent time sources:
///
/// - UTC wall-clock time for diagnostic timestamps.
/// - Monotonic elapsed-time readings for measuring execution duration.
///
/// Architectural responsibilities:
///
/// - Provide the current UTC wall-clock timestamp.
/// - Provide a monotonic elapsed-time reading.
/// - Allow clock implementations to be injected into higher layers.
///
/// Architectural restrictions:
///
/// - Does not execute repository operations.
/// - Does not generate execution identifiers.
/// - Does not create diagnostic records.
/// - Does not record diagnostic events.
/// - Does not resolve or validate repository scopes.
/// - Does not access repositories or scope registries.
/// - Does not define a specific clock implementation.
///
/// Contract requirements:
///
/// - [nowUtc] must return a UTC timestamp.
/// - [elapsedRealtime] must return a monotonic reading.
/// - Successive [elapsedRealtime] readings must never move backwards
///   during the lifetime of the same clock instance.
///
/// Consumers should measure execution duration by subtracting two
/// readings obtained from [elapsedRealtime], rather than subtracting
/// wall-clock timestamps.
///
/// The monotonic reading is intended for elapsed-time measurement only.
/// It must not be interpreted as a calendar timestamp.
abstract interface class
    AppEventSchemaMigrationAuditExecutionClock {
  /// Returns the current wall-clock timestamp in UTC.
  ///
  /// Implementations must return a DateTime whose isUtc property is true.
  DateTime nowUtc();

  /// Returns a monotonic elapsed-time reading.
  ///
  /// The returned value must use a consistent origin and time unit
  /// throughout the lifetime of this clock instance.
  ///
  /// Successive readings must never move backwards.
  ///
  /// Consumers may subtract an earlier reading from a later reading
  /// to obtain an elapsed Duration.
  Duration elapsedRealtime();
}
