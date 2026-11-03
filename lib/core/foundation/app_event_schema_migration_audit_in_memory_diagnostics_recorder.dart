
import 'app_event_schema_migration_audit_execution_diagnostic.dart';
import 'app_event_schema_migration_audit_execution_diagnostics_recorder.dart';

/// In-memory implementation of the execution diagnostics recorder.
///
/// Diagnostic records are retained only for the lifetime of this
/// recorder instance.
///
/// Architectural responsibilities:
///
/// - Accept execution diagnostic records.
/// - Retain accepted records in memory.
/// - Prevent duplicate execution identifiers.
/// - Provide read-only access to recorded diagnostics.
/// - Allow explicitly clearing retained diagnostics.
///
/// Architectural restrictions:
///
/// - Does not persist records across application restarts.
/// - Does not execute repository operations.
/// - Does not resolve or validate repository scopes.
/// - Does not generate execution identifiers.
/// - Does not measure execution duration.
/// - Does not modify diagnostic records.
/// - Does not retain operation results or audit record contents.
/// - Does not access repositories or scope registries.
///
/// This implementation is intended for in-process diagnostic
/// collection. It does not provide database durability or
/// cross-isolate synchronization.
final class
    AppEventSchemaMigrationAuditInMemoryDiagnosticsRecorder
    implements
        AppEventSchemaMigrationAuditExecutionDiagnosticsRecorder {
  /// Creates an empty in-memory diagnostics recorder.
  AppEventSchemaMigrationAuditInMemoryDiagnosticsRecorder();

  final List<AppEventSchemaMigrationAuditExecutionDiagnostic>
      _diagnostics =
      <AppEventSchemaMigrationAuditExecutionDiagnostic>[];

  final Set<String> _executionIds = <String>{};

  /// Returns an immutable snapshot of all recorded diagnostics.
  ///
  /// The returned list cannot be used to modify the recorder's
  /// internal collection.
  List<AppEventSchemaMigrationAuditExecutionDiagnostic>
      get diagnostics {
    return List<
        AppEventSchemaMigrationAuditExecutionDiagnostic>.unmodifiable(
      _diagnostics,
    );
  }

  /// Returns the number of retained diagnostic records.
  int get length => _diagnostics.length;

  /// Indicates whether the recorder contains no diagnostic records.
  bool get isEmpty => _diagnostics.isEmpty;

  /// Indicates whether the recorder contains diagnostic records.
  bool get isNotEmpty => _diagnostics.isNotEmpty;

  /// Records one diagnostic.
  ///
  /// Duplicate execution identifiers are rejected.
  ///
  /// The supplied diagnostic is retained without modification.
  @override
  Future<void> record(
    AppEventSchemaMigrationAuditExecutionDiagnostic diagnostic,
  ) async {
    if (!_executionIds.add(diagnostic.executionId)) {
      throw StateError(
        'A diagnostic with this execution identifier already exists.',
      );
    }

    _diagnostics.add(diagnostic);
  }

  /// Finds a diagnostic by its execution identifier.
  ///
  /// Returns null when no matching diagnostic exists.
  AppEventSchemaMigrationAuditExecutionDiagnostic? findByExecutionId(
    String executionId,
  ) {
    for (final diagnostic in _diagnostics) {
      if (diagnostic.executionId == executionId) {
        return diagnostic;
      }
    }

    return null;
  }

  /// Removes all retained diagnostics.
  ///
  /// This operation affects only this recorder instance.
  void clear() {
    _diagnostics.clear();
    _executionIds.clear();
  }
}
