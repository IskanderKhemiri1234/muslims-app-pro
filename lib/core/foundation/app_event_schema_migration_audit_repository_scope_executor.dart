
/// Defines the execution boundary for an explicitly requested
/// application event schema migration audit scope operation.
///
/// Implementations are supplied by the Composition Root.
///
/// This abstraction does not define initialization, disposal,
/// resource ownership, policy evaluation, or authorization.
abstract interface class AppEventSchemaMigrationAuditScopeOperation<
    TRequest,
    TResult> {
  /// Executes one explicitly supplied scope operation.
  ///
  /// Implementations must not assume that this method grants permission
  /// to initialize unrelated modules or manage external resource lifecycles.
  Future<TResult> execute({
    required TRequest request,
  });
}

/// Executes an explicitly requested application event schema migration
/// audit scope operation through an injected operation implementation.
///
/// Architectural responsibilities:
///
/// - Accept an operation implementation supplied by the Composition Root.
/// - Forward an explicit request to that implementation.
/// - Return the operation result without changing its meaning.
/// - Propagate operation failures to the caller.
///
/// Architectural restrictions:
///
/// - Does not construct repositories, providers, services, or guards.
/// - Does not initialize application modules.
/// - Does not dispose or otherwise manage resources.
/// - Does not evaluate acceptance policies.
/// - Does not run validation pipelines implicitly.
/// - Does not infer resource readiness.
/// - Does not grant execution or initialization permission.
///
/// The Composition Root remains responsible for dependency construction,
/// lifecycle ownership, execution decisions, and integration boundaries.
final class AppEventSchemaMigrationAuditRepositoryScopeExecutor<
    TRequest,
    TResult> {
  /// Creates an executor around an externally supplied scope operation.
  ///
  /// The operation must be constructed and supplied by the Composition Root.
  ///
  /// No initialization or resource allocation occurs in this constructor.
  const AppEventSchemaMigrationAuditRepositoryScopeExecutor({
    required AppEventSchemaMigrationAuditScopeOperation<TRequest, TResult>
        operation,
  }) : _operation = operation;

  final AppEventSchemaMigrationAuditScopeOperation<TRequest, TResult>
      _operation;

  /// Forwards an explicit request to the injected scope operation.
  ///
  /// This method:
  ///
  /// - Does not create or initialize dependencies.
  /// - Does not perform policy evaluation.
  /// - Does not interpret validation results as authorization.
  /// - Does not catch or suppress operation exceptions.
  /// - Does not dispose resources after execution.
  ///
  /// The caller is responsible for obtaining any required authorization
  /// and invoking this method only through the Composition Root's
  /// controlled execution flow.
  Future<TResult> execute({
    required TRequest request,
  }) {
    return _operation.execute(
      request: request,
    );
  }
}
