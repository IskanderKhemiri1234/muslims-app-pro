import 'app_event_schema_migration_audit_repository_scope_context.dart';
import 'app_event_schema_migration_audit_repository_scope_executor.dart';
import 'app_event_schema_migration_audit_repository_scope_registry.dart';

/// Coordinates an explicitly requested operation within a verified
/// application event schema migration audit repository scope.
///
/// The service uses the existing scope registry, scope context, and
/// injected scope executor.
///
/// Architectural responsibilities:
///
/// - Resolve the requested scope from the existing registry.
/// - Verify that the supplied context represents the requested scope.
/// - Verify that the registered scope and context are active.
/// - Verify that both components refer to the same scope identity.
/// - Delegate the explicit request to the injected scope executor.
/// - Revalidate the context after successful asynchronous execution.
/// - Propagate execution and validation failures without replacing them.
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
  /// After successful execution, it validates them again to detect
  /// scope disposal or identity changes that occurred while the operation
  /// was pending.
  ///
  /// This method does not lock the scope lifecycle. Another component may
  /// dispose the scope while the operation is running.
  ///
  /// Execution failures are propagated unchanged. Post-execution
  /// validation is performed only when the operation completes
  /// successfully.
  Future<TResult> execute({
    required String scopeId,
    required AppEventSchemaMigrationAuditRepositoryScopeContext context,
    required TRequest request,
  }) async {
    final normalizedScopeId = _normalizeRequestedScopeId(scopeId);

    _verifyScopeBeforeExecution(
      normalizedScopeId: normalizedScopeId,
      context: context,
    );

    final result = await _scopeExecutor.execute(
      request: request,
    );

    _verifyScopeAfterExecution(
      normalizedScopeId: normalizedScopeId,
      context: context,
    );

    return result;
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
  /// A failure here indicates that the operation completed but the scope
  /// could not be confirmed as active afterward.
  ///
  /// The method does not undo the completed operation.
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
