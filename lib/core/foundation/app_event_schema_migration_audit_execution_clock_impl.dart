
import 'app_event_schema_migration_audit_execution_clock.dart';

/// System-backed implementation of the execution clock.
///
/// Provides UTC wall-clock timestamps and monotonic elapsed-time
/// measurements for execution diagnostics.
///
/// Architectural responsibilities:
///
/// - Provide the current UTC date and time.
/// - Measure elapsed time using a monotonic Stopwatch.
/// - Keep elapsed-time measurements independent of system-clock changes.
///
/// Architectural restrictions:
///
/// - Does not generate execution identifiers.
/// - Does not create or record diagnostic events.
/// - Does not execute repository operations.
/// - Does not resolve or validate repository scopes.
/// - Does not introduce external package dependencies.
final class AppEventSchemaMigrationAuditSystemExecutionClock
    implements AppEventSchemaMigrationAuditExecutionClock {
  /// Creates an execution clock and starts its monotonic timer.
  AppEventSchemaMigrationAuditSystemExecutionClock()
      : _stopwatch = Stopwatch()..start();

  final Stopwatch _stopwatch;

  /// Returns the current system date and time in UTC.
  @override
  DateTime nowUtc() {
    return DateTime.now().toUtc();
  }

  /// Returns monotonic elapsed time since this clock was created.
  ///
  /// The returned duration is not affected by changes to the
  /// device's wall-clock date or time.
  @override
  Duration elapsedRealtime() {
    return _stopwatch.elapsed;
  }
}
