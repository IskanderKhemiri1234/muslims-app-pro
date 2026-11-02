
import 'dart:collection';

import 'app_event_schema_migration_audit_repository_scope.dart';

/// Identifies scope registry lifecycle and registration errors.
enum AppEventSchemaMigrationAuditRepositoryScopeRegistryErrorCode {
  invalidScopeId,
  duplicateScopeId,
  scopeNotFound,
  scopeDisposed,
  registryDisposed,
  scopeIdentityMismatch,
}

/// Represents a scope registry operation failure.
final class AppEventSchemaMigrationAuditRepositoryScopeRegistryException
    implements Exception {
  const AppEventSchemaMigrationAuditRepositoryScopeRegistryException({
    required this.code,
    required this.message,
  });

  final AppEventSchemaMigrationAuditRepositoryScopeRegistryErrorCode code;
  final String message;

  @override
  String toString() {
    return 'AppEventSchemaMigrationAuditRepositoryScopeRegistryException'
        '(code: ${code.name}, message: $message)';
  }
}

/// Maintains an isolated registry of audit repository scopes.
///
/// The registry indexes active scopes by their normalized identifiers.
/// Identifiers remain reserved until their associated scope has been
/// safely disposed and removed from the registry.
///
/// The registry never accesses a global provider and never disposes
/// repository instances.
final class AppEventSchemaMigrationAuditRepositoryScopeRegistry {
  AppEventSchemaMigrationAuditRepositoryScopeRegistry();

  final Map<String, AppEventSchemaMigrationAuditRepositoryScope>
      _activeScopes =
      <String, AppEventSchemaMigrationAuditRepositoryScope>{};

  final Set<String> _reservedScopeIds = <String>{};

  bool _disposed = false;

  /// Number of currently registered active scopes.
  int get activeScopeCount {
    _ensureRegistryActive();
    _removeExternallyDisposedScopes();
    return _activeScopes.length;
  }

  /// Number of identifiers currently reserved by this registry.
  int get reservedScopeCount {
    _ensureRegistryActive();
    return _reservedScopeIds.length;
  }

  /// Indicates whether the registry has been disposed.
  bool get isDisposed => _disposed;

  /// Returns an immutable snapshot of active scope identifiers.
  Set<String> get activeScopeIds {
    _ensureRegistryActive();
    _removeExternallyDisposedScopes();

    return UnmodifiableSetView<String>(
      Set<String>.of(_activeScopes.keys),
    );
  }

  /// Registers a scope and reserves its identifier.
  ///
  /// The scope must be active and its identifier must not already be
  /// reserved by this registry.
  void register(
    AppEventSchemaMigrationAuditRepositoryScope scope,
  ) {
    _ensureRegistryActive();
    _removeExternallyDisposedScopes();

    if (!scope.isActive) {
      throw const AppEventSchemaMigrationAuditRepositoryScopeRegistryException(
        code: AppEventSchemaMigrationAuditRepositoryScopeRegistryErrorCode
            .scopeDisposed,
        message: 'A disposed scope cannot be registered.',
      );
    }

    final scopeId = _normalizeScopeId(scope.scopeId);

    if (scopeId != scope.scopeId) {
      throw const AppEventSchemaMigrationAuditRepositoryScopeRegistryException(
        code: AppEventSchemaMigrationAuditRepositoryScopeRegistryErrorCode
            .scopeIdentityMismatch,
        message: 'The scope identifier is not normalized.',
      );
    }

    if (_reservedScopeIds.contains(scopeId)) {
      throw AppEventSchemaMigrationAuditRepositoryScopeRegistryException(
        code: AppEventSchemaMigrationAuditRepositoryScopeRegistryErrorCode
            .duplicateScopeId,
        message: 'The scope identifier "$scopeId" is already reserved.',
      );
    }

    _reservedScopeIds.add(scopeId);
    _activeScopes[scopeId] = scope;
  }

  /// Retrieves an active scope by its identifier.
  AppEventSchemaMigrationAuditRepositoryScope get(
    String scopeId,
  ) {
    _ensureRegistryActive();

    final normalizedId = _normalizeScopeId(scopeId);
    final scope = _activeScopes[normalizedId];

    if (scope == null) {
      throw AppEventSchemaMigrationAuditRepositoryScopeRegistryException(
        code: AppEventSchemaMigrationAuditRepositoryScopeRegistryErrorCode
            .scopeNotFound,
        message: 'No active scope matches "$normalizedId".',
      );
    }

    if (!scope.isActive) {
      _activeScopes.remove(normalizedId);

      throw AppEventSchemaMigrationAuditRepositoryScopeRegistryException(
        code: AppEventSchemaMigrationAuditRepositoryScopeRegistryErrorCode
            .scopeDisposed,
        message: 'The scope "$normalizedId" has already been disposed.',
      );
    }

    return scope;
  }

  /// Checks whether an active scope is registered.
  bool contains(String scopeId) {
    _ensureRegistryActive();

    final normalizedId = _normalizeScopeId(scopeId);
    final scope = _activeScopes[normalizedId];

    return scope != null && scope.isActive;
  }

  /// Checks whether an identifier is reserved.
  ///
  /// A reserved identifier cannot be reused until its scope is safely
  /// disposed and explicitly removed.
  bool isReserved(String scopeId) {
    _ensureRegistryActive();
    return _reservedScopeIds.contains(_normalizeScopeId(scopeId));
  }

  /// Disposes and unregisters a scope.
  ///
  /// The identifier is released only after the scope has been disposed
  /// successfully. The repository itself remains untouched.
  bool disposeAndUnregister(String scopeId) {
    _ensureRegistryActive();

    final normalizedId = _normalizeScopeId(scopeId);
    final scope = _activeScopes[normalizedId];

    if (scope == null) {
      return false;
    }

    scope.dispose();

    _activeScopes.remove(normalizedId);
    _reservedScopeIds.remove(normalizedId);

    return true;
  }

  /// Unregisters a scope without disposing it.
  ///
  /// The identifier remains reserved because the scope may still be active.
  /// This prevents another scope from taking the same identifier while the
  /// original scope remains usable.
  bool unregister(String scopeId) {
    _ensureRegistryActive();

    final normalizedId = _normalizeScopeId(scopeId);
    final scope = _activeScopes.remove(normalizedId);

    if (scope == null) {
      return false;
    }

    if (!scope.isDisposed) {
      _reservedScopeIds.add(normalizedId);
    } else {
      _reservedScopeIds.remove(normalizedId);
    }

    return true;
  }

  /// Releases a reserved identifier after safe disposal.
  ///
  /// The identifier can only be released when no active scope is registered
  /// under it and the original scope has already been disposed.
  bool releaseDisposedScopeId({
    required String scopeId,
    required AppEventSchemaMigrationAuditRepositoryScope scope,
  }) {
    _ensureRegistryActive();

    final normalizedId = _normalizeScopeId(scopeId);

    if (scope.scopeId != normalizedId) {
      throw const AppEventSchemaMigrationAuditRepositoryScopeRegistryException(
        code: AppEventSchemaMigrationAuditRepositoryScopeRegistryErrorCode
            .scopeIdentityMismatch,
        message: 'The supplied scope does not match the requested identifier.',
      );
    }

    if (!scope.isDisposed) {
      throw const AppEventSchemaMigrationAuditRepositoryScopeRegistryException(
        code: AppEventSchemaMigrationAuditRepositoryScopeRegistryErrorCode
            .scopeDisposed,
        message: 'The scope must be disposed before its identifier is released.',
      );
    }

    if (_activeScopes.containsKey(normalizedId)) {
      throw const AppEventSchemaMigrationAuditRepositoryScopeRegistryException(
        code: AppEventSchemaMigrationAuditRepositoryScopeRegistryErrorCode
            .scopeIdentityMismatch,
        message: 'The identifier is still associated with a registered scope.',
      );
    }

    return _reservedScopeIds.remove(normalizedId);
  }

  /// Disposes all registered scopes and clears the registry.
  ///
  /// Previously unregistered scopes are not owned by this registry and
  /// therefore are not disposed here.
  void dispose() {
    if (_disposed) {
      return;
    }

    for (final scope in _activeScopes.values) {
      scope.dispose();
    }

    _activeScopes.clear();
    _reservedScopeIds.clear();
    _disposed = true;
  }

  void _removeExternallyDisposedScopes() {
    final disposedIds = _activeScopes.entries
        .where((entry) => entry.value.isDisposed)
        .map((entry) => entry.key)
        .toList(growable: false);

    for (final scopeId in disposedIds) {
      _activeScopes.remove(scopeId);
    }

    // Reserved identifiers are intentionally retained here.
    // Their release requires explicit confirmation of the disposed scope.
  }

  void _ensureRegistryActive() {
    if (_disposed) {
      throw const AppEventSchemaMigrationAuditRepositoryScopeRegistryException(
        code: AppEventSchemaMigrationAuditRepositoryScopeRegistryErrorCode
            .registryDisposed,
        message: 'The audit repository scope registry has been disposed.',
      );
    }
  }

  String _normalizeScopeId(String value) {
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
