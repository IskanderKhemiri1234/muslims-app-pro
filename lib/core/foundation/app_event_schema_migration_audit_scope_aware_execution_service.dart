
import 'app_event_schema_migration_audit_execution_clock.dart';
import 'app_event_schema_migration_audit_execution_diagnostic.dart';
import 'app_event_schema_migration_audit_execution_diagnostics_recorder.dart';
import 'app_event_schema_migration_audit_execution_id_generator.dart';
import 'app_event_schema_migration_audit_repository_scope_context.dart';
import 'app_event_schema_migration_audit_repository_scope_executor.dart';
import 'app_event_schema_migration_audit_repository_scope_registry.dart';
import 'app_event_schema_migration_audit_scope_execution_result.dart';

/// Executes an audit scope operation while verifying the identity
/// and lifecycle state of the selected repository scope.
///
/// Diagnostic infrastructure is best-effort and never replaces
/// the primary operation result or its original exception.
final class AppEventSchemaMigrationAuditScopeAwareExecutionService<
    TRequest,
    TResult> {
  const AppEventSchemaMigrationAuditScopeAwareExecutionService({
    required AppEventSchemaMigrationAuditRepositoryScopeRegistry
        scopeRegistry,
    required AppEventSchemaMigrationAuditRepositoryScopeExecutor<
        TRequest, TResult> scopeExecutor,
    required AppEventSchemaMigrationAuditExecutionOperation operation,
    required AppEventSchemaMigrationAuditExecutionDiagnosticsRecorder
        diagnosticsRecorder,
    required AppEventSchemaMigrationAuditExecutionIdGenerator
        executionIdGenerator,
    required AppEventSchemaMigrationAuditExecutionClock executionClock,
  })  : _scopeRegistry = scopeRegistry,
        _scopeExecutor = scopeExecutor,
        _operation = operation,
        _diagnosticsRecorder = diagnosticsRecorder,
        _executionIdGenerator = executionIdGenerator,
        _executionClock = executionClock;

  final AppEventSchemaMigrationAuditRepositoryScopeRegistry
      _scopeRegistry;

  final AppEventSchemaMigrationAuditRepositoryScopeExecutor<
      TRequest, TResult> _scopeExecutor;

  final AppEventSchemaMigrationAuditExecutionOperation _operation;

  final AppEventSchemaMigrationAuditExecutionDiagnosticsRecorder
      _diagnosticsRecorder;

  final AppEventSchemaMigrationAuditExecutionIdGenerator
      _executionIdGenerator;

  final AppEventSchemaMigrationAuditExecutionClock _executionClock;

  /// Executes an operation against the explicitly selected scope.
  ///
  /// Scope validation before execution remains authoritative.
  ///
  /// Diagnostic initialization and recording failures do not prevent
  /// the primary operation from executing or replace its outcome.
  ///
  /// A failed operation is recorded when possible, then its original
  /// exception and stack trace are rethrown.
  Future<AppEventSchemaMigrationAuditScopeExecutionResult<TResult>>
      execute({
    required String scopeId,
    required AppEventSchemaMigrationAuditRepositoryScopeContext context,
    required TRequest request,
  }) async {
    final normalizedScopeId = _validateScopeId(scopeId);

    _verifyScopeBeforeExecution(
      scopeId: normalizedScopeId,
      context: context,
    );

    String? executionId;
    DateTime? startedAt;
    Duration? startedElapsed;

    // Diagnostic initialization must never block the operation.
    try {
      executionId = _executionIdGenerator.generate();
      startedAt = _executionClock.nowUtc();
      startedElapsed = _executionClock.elapsedRealtime();
    } catch (_) {
      executionId = null;
      startedAt = null;
      startedElapsed = null;
    }

    late final TResult operationResult;

    try {
      operationResult = await _scopeExecutor.execute(
        context: context,
        request: request,
      );
    } catch (error, stackTrace) {
      await _tryRecordDiagnostic(
        executionId: executionId,
        scopeId: normalizedScopeId,
        outcome: AppEventSchemaMigrationAuditExecutionOutcome.failure,
        startedAt: startedAt,
        startedElapsed: startedElapsed,
        failureCode: 'scope_operation_failed',
      );

      Error.throwWithStackTrace(error, stackTrace);
    }

    var validationResult =
        AppEventSchemaMigrationAuditScopeExecutionValidationResult
            .verified;

    try {
      _verifyScopeAfterExecution(
        scopeId: normalizedScopeId,
        context: context,
      );
    } catch (_) {
      validationResult =
          AppEventSchemaMigrationAuditScopeExecutionValidationResult
              .notVerified;
    }

    await _tryRecordDiagnostic(
      executionId: executionId,
      scopeId: normalizedScopeId,
      outcome: AppEventSchemaMigrationAuditExecutionOutcome.success,
      startedAt: startedAt,
      startedElapsed: startedElapsed,
      validationResult: validationResult,
    );

    return AppEventSchemaMigrationAuditScopeExecutionResult<TResult>(
      scopeId: normalizedScopeId,
      result: operationResult,
      validationResult: validationResult,
    );
  }

  /// Records one completed diagnostic if all required metadata
  /// is available. Diagnostic failures are intentionally isolated.
  Future<void> _tryRecordDiagnostic({
    required String? executionId,
    required String scopeId,
    required AppEventSchemaMigrationAuditExecutionOutcome outcome,
    required DateTime? startedAt,
    required Duration? startedElapsed,
    AppEventSchemaMigrationAuditScopeExecutionValidationResult?
        validationResult,
    String? failureCode,
  }) async {
    if (executionId == null ||
        startedAt == null ||
        startedElapsed == null) {
      return;
    }

    try {
      final completedAt = _executionClock.nowUtc();
      final completedElapsed = _executionClock.elapsedRealtime();

      final duration = completedElapsed - startedElapsed;

      if (duration.isNegative) {
        return;
      }

      // Preserve valid timestamp ordering if the device wall clock
      // was adjusted while the operation was running.
      final normalizedCompletedAt =
          completedAt.isBefore(startedAt) ? startedAt : completedAt;

      final diagnostic =
          AppEventSchemaMigrationAuditExecutionDiagnostic(
        executionId: executionId,
        scopeId: scopeId,
        operation: _operation,
        startedAt: startedAt,
        completedAt: normalizedCompletedAt,
        duration: duration,
        outcome: outcome,
        validationResult: validationResult,
        failureCode: failureCode,
      );

      await _diagnosticsRecorder.record(diagnostic);
    } catch (_) {
      // Recording failure must not replace the primary outcome.
    }
  }

  void _verifyScopeBeforeExecution({
    required String scopeId,
    required AppEventSchemaMigrationAuditRepositoryScopeContext context,
  }) {
    context.verifyActive();

    if (context.scopeId != scopeId) {
      throw StateError(
        'The execution scope does not match the supplied context scope.',
      );
    }

    if (!_scopeRegistry.contains(scopeId)) {
      throw StateError(
        'The requested execution scope is not registered or is inactive.',
      );
    }

    final registeredScope = _scopeRegistry.get(scopeId);

    if (!identical(registeredScope, context.scope)) {
      throw StateError(
        'The registered scope does not match the supplied context scope.',
      );
    }
  }

  void _verifyScopeAfterExecution({
    required String scopeId,
    required AppEventSchemaMigrationAuditRepositoryScopeContext context,
  }) {
    context.verifyActive();

    if (context.scopeId != scopeId) {
      throw StateError(
        'The execution scope changed during operation execution.',
      );
    }

    if (!_scopeRegistry.contains(scopeId)) {
      throw StateError(
        'The execution scope is no longer registered or active.',
      );
    }

    final registeredScope = _scopeRegistry.get(scopeId);

    if (!identical(registeredScope, context.scope)) {
      throw StateError(
        'The registered scope identity changed during operation execution.',
      );
    }
  }

  String _validateScopeId(String value) {
    final normalized = value.trim();

    if (normalized.isEmpty || normalized.length > 128) {
      throw ArgumentError.value(
        value,
        'scopeId',
        'A scope identifier must contain 1 to 128 characters.',
      );
    }

    if (normalized != value) {
      throw ArgumentError.value(
        value,
        'scopeId',
        'The scope identifier must already be normalized.',
      );
    }

    return normalized;
  }
}
