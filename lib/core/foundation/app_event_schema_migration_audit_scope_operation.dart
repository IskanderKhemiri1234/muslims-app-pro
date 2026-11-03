
import 'app_event_schema_migration_audit_repository_scope_context.dart';

/// Defines the execution boundary for an explicitly requested
/// application event schema migration audit scope operation.
///
/// Every operation receives the exact scope context selected and
/// validated by the caller.
///
/// Implementations must access the audit repository through
/// [AppEventSchemaMigrationAuditRepositoryScopeContext.repository].
///
/// Implementations must not obtain or use a repository belonging
/// to another scope.
///
/// Implementations are supplied by the Composition Root.
///
/// This abstraction does not define initialization, disposal,
/// resource ownership, policy evaluation, or authorization.
abstract interface class AppEventSchemaMigrationAuditScopeOperation<
    TRequest,
    TResult> {
  /// Executes one explicitly supplied operation within the given scope.
  ///
  /// The supplied context identifies the scope and provides access
  /// to its repository while the scope remains active.
  ///
  /// Implementations must use [context.repository] for repository
  /// access and must not substitute an independently obtained
  /// repository instance.
  ///
  /// If the scope becomes inactive before repository access,
  /// the context or scope lifecycle validation may throw.
  ///
  /// Operation exceptions are propagated to the caller.
  Future<TResult> execute({
    required AppEventSchemaMigrationAuditRepositoryScopeContext context,
    required TRequest request,
  });
}
