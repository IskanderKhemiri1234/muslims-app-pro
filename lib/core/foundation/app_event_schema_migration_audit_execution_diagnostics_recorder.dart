
import 'app_event_schema_migration_audit_execution_diagnostic.dart';

/// Defines the contract for recording scope-aware execution diagnostics.
///
/// Implementations receive diagnostic records and decide how they are
/// handled or stored.
///
/// Architectural responsibilities:
///
/// - Accept execution diagnostic records.
/// - Provide an asynchronous recording contract.
/// - Preserve the diagnostic model as the source of recorded metadata.
/// - Allow recording implementations to be injected into higher layers.
///
/// Architectural restrictions:
///
/// - Does not execute repository operations.
/// - Does not resolve or validate repository scopes.
/// - Does not generate execution identifiers.
/// - Does not measure execution duration.
/// - Does not create or modify diagnostic records.
/// - Does not retain operation results or audit record contents.
/// - Does not define a storage technology.
/// - Does not define retention or deletion policies.
/// - Does not suppress recording failures.
///
/// Error handling:
///
/// Implementations may propagate recording failures to their callers.
/// The caller is responsible for deciding whether a recording failure
/// should affect the surrounding execution workflow.
///
/// This contract does not guarantee persistence, ordering, deduplication,
/// or atomicity.
abstract interface class
    AppEventSchemaMigrationAuditExecutionDiagnosticsRecorder {
  /// Records one execution diagnostic.
  ///
  /// The supplied diagnostic is treated as immutable input.
  ///
  /// The returned future completes when the implementation has completed
  /// its recording responsibility.
  ///
  /// Implementations must not silently suppress recording failures.
  Future<void> record(
    AppEventSchemaMigrationAuditExecutionDiagnostic diagnostic,
  );
}
