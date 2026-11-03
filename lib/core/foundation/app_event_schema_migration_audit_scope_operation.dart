
import 'app_event_schema_migration_audit_repository_scope_context.dart';

/// Defines the execution boundary for an explicitly requested
/// application event schema migration audit scope operation.
///
/// Implementations are supplied by the Composition Root.
///
/// Every operation receives an explicit repository scope context.
///
/// Implementations must access the audit repository exclusively
/// through the supplied context.
///
/// This abstraction does not define initialization, disposal,
/// resource ownership, policy evaluation, or authorization.
abstract interface class AppEventSchemaMigrationAuditScopeOperation<
    TRequest,
    TResult> {
  /// Executes one explicitly supplied scope operation.
  ///
  /// The supplied context identifies the selected repository scope
  /// and provides access to its repository while the scope is active.
  ///
  /// Implementations must use context.repository for repository access.
  ///
  /// Implementations must not substitute a repository belonging
  /// to another scope.
  ///
  /// Operation exceptions are propagated to the caller.
  Future<TResult> execute({
    required AppEventSchemaMigrationAuditRepositoryScopeContext context,
    required TRequest request,
  });
}
