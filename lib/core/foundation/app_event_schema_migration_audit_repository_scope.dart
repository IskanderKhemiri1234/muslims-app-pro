
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
/// The scope owns only its repository reference and lifecycle state.
/// It never disposes the repository itself. Repository lifecycle ownership
/// remains with the component that created the repository.
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

  /// Returns the repository only while this scope is active.
  AppEventSchemaMigrationAuditRepository get repository {
    _ensureActive();
    return _repository;
  }

  /// Returns the current lifecycle state.
  AppEventSchemaMigrationAuditRepositoryScopeState get state => _state;

  /// Indicates whether this scope can provide repository access.
  bool get isActive =>
      _state == AppEventSchemaMigrationAuditRepositoryScopeState.active;

  /// Indicates whether this scope has been disposed.
  bool get isDisposed =>
      _state == AppEventSchemaMigrationAuditRepositoryScopeState.disposed;

  /// Disposes this scope's access boundary.
  ///
  /// This operation is idempotent and never disposes the repository.
  void dispose() {
    if (isDisposed) {
      return;
    }

    _state = AppEventSchemaMigrationAuditRepositoryScopeState.disposed;
  }

  /// Verifies that an identifier belongs to this active scope.
  void verifyScope(String candidateScopeId) {
    _ensureActive();

    final normalizedCandidate = _validateScopeId(candidateScopeId);

    if (normalizedCandidate != scopeId) {
      throw const AppEventSchemaMigrationAuditRepositoryScopeException(
        code: AppEventSchemaMigrationAuditRepositoryScopeErrorCode
            .scopeMismatch,
        message: 'The requested operation belongs to another scope.',
      );
    }
  }

  void _ensureActive() {
    if (!isActive) {
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

  /// Normalizes an identifier using the same rules as scope construction.
  ///
  /// Kept private to this library so manager operations use the same
  /// validation contract as the scope itself.
  static String _normalizeManagerScopeId(String value) {
    return _validateScopeId(value);
  }
}

/// Creates and manages multiple independent audit repository scopes.
///
/// The manager stores existing scope references only. It does not create
/// repositories, select storage implementations, or use global providers.
final class AppEventSchemaMigrationAuditRepositoryScopeManager {
  final Map<String, AppEventSchemaMigrationAuditRepositoryScope> _scopes =
      <String, AppEventSchemaMigrationAuditRepositoryScope>{};

  bool _disposed = false;

  /// Returns the number of currently active registered scopes.
  int get activeScopeCount {
    _ensureManagerActive();
    _removeInactiveScopes();
    return _scopes.length;
  }

  /// Indicates whether this manager has been disposed.
  bool get isDisposed => _disposed;

  /// Registers an existing active scope.
  ///
  /// Each identifier can be registered only once at a time.
  void register(AppEventSchemaMigrationAuditRepositoryScope scope) {
    _ensureManagerActive();

    if (!scope.isActive || scope.isDisposed) {
      throw const AppEventSchemaMigrationAuditRepositoryScopeException(
        code: AppEventSchemaMigrationAuditRepositoryScopeErrorCode.disposed,
        message: 'A disposed scope cannot be registered.',
      );
    }

    final scopeId =
        AppEventSchemaMigrationAuditRepositoryScope._normalizeManagerScopeId(
      scope.scopeId,
    );

    _removeInactiveScopes();

    if (_scopes.containsKey(scopeId)) {
      throw AppEventSchemaMigrationAuditRepositoryScopeException(
        code: AppEventSchemaMigrationAuditRepositoryScopeErrorCode
            .duplicateRegistration,
        message: 'A scope with identifier "$scopeId" '
            'is already registered.',
      );
    }

    _scopes[scopeId] = scope;
  }

  /// Retrieves a registered active scope by identifier.
  AppEventSchemaMigrationAuditRepositoryScope getScope(String scopeId) {
    _ensureManagerActive();

    final normalizedId =
        AppEventSchemaMigrationAuditRepositoryScope._normalizeManagerScopeId(
      scopeId,
    );

    final scope = _scopes[normalizedId];

    if (scope == null) {
      throw const AppEventSchemaMigrationAuditRepositoryScopeException(
        code: AppEventSchemaMigrationAuditRepositoryScopeErrorCode
            .scopeMismatch,
        message: 'No active audit repository scope matches this identifier.',
      );
    }

    if (!scope.isActive || scope.isDisposed) {
      _scopes.remove(normalizedId);

      throw const AppEventSchemaMigrationAuditRepositoryScopeException(
        code: AppEventSchemaMigrationAuditRepositoryScopeErrorCode.disposed,
        message: 'The requested audit repository scope has been disposed.',
      );
    }

    return scope;
  }

  /// Removes a scope from the manager.
  ///
  /// When [disposeScope] is true, only the scope access boundary is disposed.
  /// The underlying repository remains untouched.
  bool unregister(
    String scopeId, {
    bool disposeScope = false,
  }) {
    _ensureManagerActive();

    final normalizedId =
        AppEventSchemaMigrationAuditRepositoryScope._normalizeManagerScopeId(
      scopeId,
    );

    final scope = _scopes.remove(normalizedId);

    if (scope == null) {
      return false;
    }

    if (disposeScope) {
      scope.dispose();
    }

    return true;
  }

  /// Disposes all registered scopes and clears the manager.
  ///
  /// Repository instances remain owned by their original creators.
  /// Calling this method repeatedly is safe.
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

  void _removeInactiveScopes() {
    _scopes.removeWhere(
      (scopeId, scope) => !scope.isActive || scope.isDisposed,
    );
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
