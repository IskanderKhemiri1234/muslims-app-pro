
import 'app_event_schema_migration_audit_repository.dart';

/// Represents the lifecycle state of an audit repository scope.
enum AppEventSchemaMigrationAuditRepositoryScopeState {
  active,
  disposed,
}

/// Identifies scope lifecycle errors.
enum AppEventSchemaMigrationAuditRepositoryScopeErrorCode {
  disposed,
  invalidIdentifier,
  duplicateRegistration,
  scopeMismatch,
}

/// Represents an audit repository scope lifecycle exception.
final class AppEventSchemaMigrationAuditRepositoryScopeException
    implements Exception {
  const AppEventSchemaMigrationAuditRepositoryScopeException({
    required this.code,
    required this.message,
  });

  final AppEventSchemaMigrationAuditRepositoryScopeErrorCode code;
  final String message;

  @override
  String toString() {
    return 'AppEventSchemaMigrationAuditRepositoryScopeException'
        '(code: ${code.name}, message: $message)';
  }
}

/// Provides an isolated repository access boundary.
///
/// Each scope owns its repository reference and lifecycle state.
/// It does not use a global provider, register itself globally, or
/// dispose the repository because repository ownership belongs to
/// the component that created it.
final class AppEventSchemaMigrationAuditRepositoryScope {
  AppEventSchemaMigrationAuditRepositoryScope({
    required String scopeId,
    required AppEventSchemaMigrationAuditRepository repository,
  })  : scopeId = _validateScopeId(scopeId),
        _repository = repository;

  final String scopeId;

  final AppEventSchemaMigrationAuditRepository _repository;

  AppEventSchemaMigrationAuditRepositoryScopeState _state =
      AppEventSchemaMigrationAuditRepositoryScopeState.active;

  /// Returns the repository while this scope is active.
  AppEventSchemaMigrationAuditRepository get repository {
    _ensureActive();
    return _repository;
  }

  /// Returns the current lifecycle state.
  AppEventSchemaMigrationAuditRepositoryScopeState get state => _state;

  /// Indicates whether this scope can still provide its repository.
  bool get isActive =>
      _state == AppEventSchemaMigrationAuditRepositoryScopeState.active;

  /// Indicates whether this scope has been disposed.
  bool get isDisposed =>
      _state ==
      AppEventSchemaMigrationAuditRepositoryScopeState.disposed;

  /// Disposes this scope's access boundary.
  ///
  /// The repository itself remains untouched. Calling this method
  /// repeatedly is safe.
  void dispose() {
    if (isDisposed) {
      return;
    }

    _state = AppEventSchemaMigrationAuditRepositoryScopeState.disposed;
  }

  /// Verifies that an identifier belongs to this scope.
  ///
  /// This is useful when passing scope-bound operations between services.
  void verifyScope(String candidateScopeId) {
    _ensureActive();

    final normalizedCandidate = _validateScopeId(candidateScopeId);

    if (normalizedCandidate != scopeId) {
      throw AppEventSchemaMigrationAuditRepositoryScopeException(
        code: AppEventSchemaMigrationAuditRepositoryScopeErrorCode
            .scopeMismatch,
        message: 'The requested operation belongs to another scope.',
      );
    }
  }

  void _ensureActive() {
    if (isDisposed) {
      throw const AppEventSchemaMigrationAuditRepositoryScopeException(
        code: AppEventSchemaMigrationAuditRepositoryScopeErrorCode.disposed,
        message: 'The audit repository scope has been disposed.',
      );
    }
  }

  static String _validateScopeId(String value) {
    final normalized = value.trim();

    if (normalized.isEmpty || normalized.length > 128) {
      throw const AppEventSchemaMigrationAuditRepositoryScopeException(
        code: AppEventSchemaMigrationAuditRepositoryScopeErrorCode
            .invalidIdentifier,
        message: 'The scope identifier must contain 1 to 128 characters.',
      );
    }

    return normalized;
  }
}

/// Creates and manages multiple independent audit repository scopes.
///
/// The manager stores scope references only. It does not create repositories,
/// select storage implementations, or access global providers.
final class AppEventSchemaMigrationAuditRepositoryScopeManager {
  final Map<String, AppEventSchemaMigrationAuditRepositoryScope> _scopes =
      <String, AppEventSchemaMigrationAuditRepositoryScope>{};

  bool _disposed = false;

  /// Returns the number of active scopes.
  int get activeScopeCount {
    _ensureManagerActive();
    return _scopes.values.where((scope) => scope.isActive).length;
  }

  /// Indicates whether the manager has been disposed.
  bool get isDisposed => _disposed;

  /// Registers an existing isolated scope.
  ///
  /// A scope identifier may only be registered once at a time.
  void register(AppEventSchemaMigrationAuditRepositoryScope scope) {
    _ensureManagerActive();

    if (!scope.isActive) {
      throw const AppEventSchemaMigrationAuditRepositoryScopeException(
        code: AppEventSchemaMigrationAuditRepositoryScopeErrorCode.disposed,
        message: 'A disposed scope cannot be registered.',
      );
    }

    if (_scopes.containsKey(scope.scopeId)) {
      throw AppEventSchemaMigrationAuditRepositoryScopeException(
        code: AppEventSchemaMigrationAuditRepositoryScopeErrorCode
            .duplicateRegistration,
        message: 'A scope with identifier "${scope.scopeId}" '
            'is already registered.',
      );
    }

    _scopes[scope.scopeId] = scope;
  }

  /// Retrieves a registered scope by identifier.
  AppEventSchemaMigrationAuditRepositoryScope getScope(String scopeId) {
    _ensureManagerActive();

    final normalizedId = scopeId.trim();

    if (normalizedId.isEmpty) {
      throw const AppEventSchemaMigrationAuditRepositoryScopeException(
        code: AppEventSchemaMigrationAuditRepositoryScopeErrorCode
            .invalidIdentifier,
        message: 'The scope identifier cannot be empty.',
      );
    }

    final scope = _scopes[normalizedId];

    if (scope == null || !scope.isActive) {
      throw const AppEventSchemaMigrationAuditRepositoryScopeException(
        code: AppEventSchemaMigrationAuditRepositoryScopeErrorCode
            .scopeMismatch,
        message: 'No active audit repository scope matches this identifier.',
      );
    }

    return scope;
  }

  /// Removes a scope from the manager.
  ///
  /// When [disposeScope] is true, the scope access boundary is disposed.
  /// The underlying repository is never disposed by the manager.
  bool unregister(
    String scopeId, {
    bool disposeScope = false,
  }) {
    _ensureManagerActive();

    final normalizedId = scopeId.trim();

    if (normalizedId.isEmpty) {
      throw const AppEventSchemaMigrationAuditRepositoryScopeException(
        code: AppEventSchemaMigrationAuditRepositoryScopeErrorCode
            .invalidIdentifier,
        message: 'The scope identifier cannot be empty.',
      );
    }

    final scope = _scopes.remove(normalizedId);

    if (scope == null) {
      return false;
    }

    if (disposeScope) {
      scope.dispose();
    }

    return true;
  }

  /// Disposes all registered scopes and clears the registry.
  ///
  /// Repository instances remain owned by their original creators.
  void dispose() {
    if (_disposed) {
      return;
    }

    for (final scope in _scopes.values) {
      scope.dispose();
    }

    _scopes.clear();
    _disposed = true;
  }

  void _ensureManagerActive() {
    if (_disposed) {
      throw const AppEventSchemaMigrationAuditRepositoryScopeException(
        code: AppEventSchemaMigrationAuditRepositoryScopeErrorCode.disposed,
        message: 'The audit repository scope manager has been disposed.',
      );
    }
  }
}
