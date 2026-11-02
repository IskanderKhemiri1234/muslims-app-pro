
import 'app_event_schema_migration_audit_repository.dart';
import 'app_event_schema_migration_audit_repository_scope.dart';
import 'app_event_schema_migration_audit_repository_scope_resolver.dart';

/// Provides a verified execution context for one audit repository scope.
///
/// The context does not create, register, unregister, or dispose scopes.
/// It also does not own the repository lifecycle.
///
/// A context must be created from a successful resolver result. Before
/// exposing the scope or repository, it revalidates that the original scope
/// remains active and that its identity has not changed.
final class AppEventSchemaMigrationAuditRepositoryScopeContext {
  final AppEventSchemaMigrationAuditRepositoryScopeResolution _resolution;

  final String _scopeId;

  AppEventSchemaMigrationAuditRepositoryScopeContext._({
    required AppEventSchemaMigrationAuditRepositoryScopeResolution resolution,
    required String scopeId,
  })  : _resolution = resolution,
        _scopeId = scopeId;

  /// Creates a context from an existing resolver result.
  ///
  /// The supplied resolution must still represent an active, matching scope.
  /// Any resolver-specific exception is allowed to propagate unchanged.
  factory AppEventSchemaMigrationAuditRepositoryScopeContext.fromResolution({
    required AppEventSchemaMigrationAuditRepositoryScopeResolution resolution,
  }) {
    resolution.verifyActive();

    final normalizedScopeId = resolution.scopeId.trim();

    if (normalizedScopeId.isEmpty) {
      throw const AppEventSchemaMigrationAuditRepositoryScopeContextException(
        AppEventSchemaMigrationAuditRepositoryScopeContextError.invalidScopeId,
      );
    }

    return AppEventSchemaMigrationAuditRepositoryScopeContext._(
      resolution: resolution,
      scopeId: normalizedScopeId,
    );
  }

  /// The normalized identifier of the scope represented by this context.
  ///
  /// Reading the identifier does not expose the repository or scope.
  String get scopeId => _scopeId;

  /// Indicates whether the underlying resolution currently remains active.
  ///
  /// This is a point-in-time check. Call [verifyActive] immediately before
  /// starting a sensitive operation.
  bool get isActive => _resolution.isActive;

  /// Returns the original scope after revalidating its current state.
  ///
  /// The returned scope is not owned by this context.
  AppEventSchemaMigrationAuditRepositoryScope get scope {
    verifyActive();
    return _resolution.scope;
  }

  /// Returns the audit repository after revalidating its current state.
  ///
  /// The returned repository is not owned or disposed by this context.
  /// Call [verifyActive] again before subsequent sensitive operations.
  AppEventSchemaMigrationAuditRepository get repository {
    verifyActive();
    return _resolution.repository;
  }

  /// Revalidates the underlying scope before a sensitive operation.
  ///
  /// The resolver result remains the authority for scope identity and
  /// lifecycle validation. Its exceptions are deliberately not swallowed.
  void verifyActive() {
    _resolution.verifyActive();

    final resolvedScopeId = _resolution.scopeId.trim();

    if (resolvedScopeId != _scopeId) {
      throw const AppEventSchemaMigrationAuditRepositoryScopeContextException(
        AppEventSchemaMigrationAuditRepositoryScopeContextError
            .scopeIdentityMismatch,
      );
    }

    if (!_resolution.scope.isActive) {
      throw const AppEventSchemaMigrationAuditRepositoryScopeContextException(
        AppEventSchemaMigrationAuditRepositoryScopeContextError.scopeDisposed,
      );
    }
  }

  /// Executes a synchronous operation after validating the scope.
  ///
  /// Validation happens immediately before the callback. This method does
  /// not lock the scope or prevent another component from disposing it while
  /// the callback is running.
  T execute<T>(
    T Function(AppEventSchemaMigrationAuditRepository repository) operation,
  ) {
    verifyActive();

    final verifiedRepository = _resolution.repository;

    return operation(verifiedRepository);
  }

  /// Executes an asynchronous operation after validating the scope.
  ///
  /// Validation is performed before invoking the callback. It is not a
  /// lifecycle lock: the scope may be disposed while the future is pending.
  Future<T> executeAsync<T>(
    Future<T> Function(
      AppEventSchemaMigrationAuditRepository repository,
    ) operation,
  ) {
    verifyActive();

    final verifiedRepository = _resolution.repository;

    return operation(verifiedRepository);
  }
}

/// Errors raised by the scope execution context itself.
enum AppEventSchemaMigrationAuditRepositoryScopeContextError {
  invalidScopeId,
  scopeIdentityMismatch,
  scopeDisposed,
}

/// Exception raised when a scope context cannot safely expose its resources.
final class AppEventSchemaMigrationAuditRepositoryScopeContextException
    implements Exception {
  final AppEventSchemaMigrationAuditRepositoryScopeContextError code;

  const AppEventSchemaMigrationAuditRepositoryScopeContextException(
    this.code,
  );

  @override
  String toString() {
    return 'AppEventSchemaMigrationAuditRepositoryScopeContextException'
        '(code: ${code.name})';
  }
}
