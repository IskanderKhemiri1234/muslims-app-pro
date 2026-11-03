
import 'app_event_schema_migration_audit_repository_scope_context.dart';
import 'app_event_schema_migration_audit_repository_scope_executor.dart';
import 'app_event_schema_migration_audit_repository_scope_registry.dart';
import 'app_event_schema_migration_audit_scope_execution_result.dart';

final class AppEventSchemaMigrationAuditScopeAwareExecutionService<
    TRequest,
    TResult> {
  const AppEventSchemaMigrationAuditScopeAwareExecutionService({
    required AppEventSchemaMigrationAuditRepositoryScopeRegistry
        scopeRegistry,
    required AppEventSchemaMigrationAuditRepositoryScopeExecutor<
        TRequest, TResult> scopeExecutor,
  })  : _scopeRegistry = scopeRegistry,
        _scopeExecutor = scopeExecutor;

  final AppEventSchemaMigrationAuditRepositoryScopeRegistry
      _scopeRegistry;

  final AppEventSchemaMigrationAuditRepositoryScopeExecutor<
      TRequest, TResult> _scopeExecutor;

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

    final operationResult = await _scopeExecutor.execute(
      context: context,
      request: request,
    );

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

    return AppEventSchemaMigrationAuditScopeExecutionResult<TResult>(
      scopeId: normalizedScopeId,
      result: operationResult,
      validationResult: validationResult,
    );
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
