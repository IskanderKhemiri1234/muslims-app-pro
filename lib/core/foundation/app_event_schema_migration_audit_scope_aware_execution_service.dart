import 'app_event_schema_migration_audit_repository_scope_context.dart';
import 'app_event_schema_migration_audit_repository_scope_executor.dart';
import 'app_event_schema_migration_audit_repository_scope_registry.dart';
import 'app_event_schema_migration_audit_scope_execution_result.dart';

/// Coordinates an explicitly requested operation within a verified
/// application event schema migration audit repository scope.
///
/// The service uses the existing scope registry, scope context,
/// injected scope executor, and immutable execution result contract.
///
/// Architectural responsibilities:
///
/// - Validate the requested scope identifier.
/// - Verify that the supplied context represents the requested scope.
/// - Verify that the registered scope and context are active.
/// - Verify that both components refer to the same scope instance.
/// - Delegate the explicit request to the injected scope executor.
/// - Preserve the original operation result.
/// - Associate the operation result with its verified scope identifier.
/// - Revalidate the scope after successful asynchronous execution.
/// - Propagate operation and validation failures without replacing them.
///
/// Architectural restrictions:
///
/// - Does not create or register scopes.
/// - Does not create repositories or providers.
/// - Does not initialize application modules.
/// - Does not dispose scopes or repositories.
/// - Does not construct an executor or an operation implementation.
/// - Does not infer authorization from successful scope validation.
/// - Does not claim lifecycle locking or atomic execution.
/// - Does not implement audit logging through an unavailable logger.
///
/// A successful operation followed by a failed post-execution validation
/// is reported as a validation failure. The operation may already have
/// completed and its side effects are not automatically reversed.
///
/// The Composition Root remains responsible for constructing this service,
/// supplying its dependencies, and controlling whether an operation
/// is authorized to execute.
final class AppEventSchemaMigrationAuditScopeAwareExecutionService<
    TRequest,
    TResult> {
  /// Creates a scope-aware execution service.
  ///
  /// All dependencies must be supplied by the Composition Root.
  ///
  /// No scope registration, initialization, or resource allocation occurs
  /// in this constructor.
  const AppEventSchemaMigrationAuditScopeAwareExecutionService({
    required AppEventSchemaMigrationAuditRepositoryScopeRegistry
        scopeRegistry,
    required AppEventSchemaMigrationAuditRepositoryScopeExecutor<
            TRequest, TResult>
        scopeExecutor,
  })  : _scopeRegistry = scopeRegistry,
        _scopeExecutor = scopeExecutor;

  final AppEventSchemaMigrationAuditRepositoryScopeRegistry _scopeRegistry;

  final AppEventSchemaMigrationAuditRepositoryScopeExecutor<
      TRequest, TResult> _scopeExecutor;

  /// Executes an explicitly supplied request within the requested scope.
  ///
  /// The supplied context must represent the same scope identifier as
  /// [scopeId], and the registry must still contain the corresponding
  /// active scope.
  ///
  /// The method validates the registry and context before execution.
  ///
  /// If execution throws, the original operation exception propagates
  /// unchanged and no execution result is created.
  ///
  /// If execution succeeds, the returned value is preserved and associated
  /// with the normalized scope identifier.
  ///
  /// The method then validates the scope again. If post-execution validation
  /// fails, that validation exception propagates. The operation may already
  /// have completed; this service does not undo its effects.
  ///
  /// This method does not lock the scope lifecycle. Another component may
  /// dispose the scope while the operation is running.
  Future<
      AppEventSchemaMigrationAuditScopeExecutionResult<TResult>> execute({
    required String scopeId,
    required AppEventSchemaMigrationAuditRepositoryScopeContext context,
    required TRequest request,
  }) async {
    final normalizedScopeId = _normalizeRequestedScopeId(scopeId);

    _verifyScopeBeforeExecution(
      normalizedScopeId: normalizedScopeId,
      context: context,
    );

    final operationResult = await _scopeExecutor.execute(
      request: request,
    );

    _verifyScopeAfterExecution(
      normalizedScopeId: normalizedScopeId,
      context: context,
    );

    return AppEventSchemaMigrationAuditScopeExecutionResult<TResult>(
      scopeId: normalizedScopeId,
      result: operationResult,
    );
  }

  /// Validates that the registry and context identify the same active scope.
  ///
  /// The registry remains the authority for registered scope ownership.
  /// The context remains the authority for resolver-backed scope validity.
  ///
  /// Neither successful check grants authorization to perform an operation.
  void _verifyScopeBeforeExecution({
    required String normalizedScopeId,
    required AppEventSchemaMigrationAuditRepositoryScopeContext context,
  }) {
    context.verifyActive();

    if (context.scopeId != normalizedScopeId) {
      throw const AppEventSchemaMigrationAuditRepositoryScopeContextException(
        AppEventSchemaMigrationAuditRepositoryScopeContextError
            .scopeIdentityMismatch,
      );
    }

    if (!_scopeRegistry.contains(normalizedScopeId)) {
      throw AppEventSchemaMigrationAuditRepositoryScopeRegistryException(
        code: AppEventSchemaMigrationAuditRepositoryScopeRegistryErrorCode
            .scopeNotFound,
        message:
            'No active registered scope matches "$normalizedScopeId".',
      );
    }

    final registeredScope = _scopeRegistry.get(normalizedScopeId);
    final contextualScope = context.scope;

    if (!identical(registeredScope, contextualScope)) {
      throw const AppEventSchemaMigrationAuditRepositoryScopeRegistryException(
        code: AppEventSchemaMigrationAuditRepositoryScopeRegistryErrorCode
            .scopeIdentityMismatch,
        message:
            'The execution context does not reference the registered scope instance.',
      );
    }

    context.verifyActive();
  }

  /// Revalidates scope identity and activity after successful execution.
  ///
  /// A failure here means that the operation returned successfully but
  /// the scope could not be confirmed as active afterward.
  ///
  /// The completed operation is not rolled back.
  void _verifyScopeAfterExecution({
    required String normalizedScopeId,
    required AppEventSchemaMigrationAuditRepositoryScopeContext context,
  }) {
    _verifyScopeBeforeExecution(
      normalizedScopeId: normalizedScopeId,
      context: context,
    );
  }

  /// Normalizes and validates an explicitly supplied scope identifier.
  ///
  /// The accepted identifier format follows the existing registry limit:
  /// between 1 and 128 characters after trimming whitespace.
  String _normalizeRequestedScopeId(String value) {
    final normalized = value.trim();

    if (normalized.isEmpty || normalized.length > 128) {
      throw const AppEventSchemaMigrationAuditRepositoryScopeRegistryException(
        code: AppEventSchemaMigrationAuditRepositoryScopeRegistryErrorCode
            .invalidScopeId,
        message: 'A scope identifier must contain 1 to 128 characters.',
      );
    }

    return normalized;
  }
    }
