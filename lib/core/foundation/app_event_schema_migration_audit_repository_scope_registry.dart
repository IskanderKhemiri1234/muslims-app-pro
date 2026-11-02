
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
    return 'AppEventSchemaMigrationAuditRepositoryScopeRegistryException('
        'code: ${code.name}, message: $message)';
  }
}

/// Maintains an isolated registry of audit repository scopes.
///
/// The registry indexes active scopes by normalized identifiers.
///
/// Registered scope identifiers remain reserved until their associated
/// scopes have been safely disposed and explicitly released.
///
/// The registry owns the lifecycle of registered scopes, but never
/// disposes repository instances.
///
/// Unregistered scopes are not owned by this registry.
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
  /// The scope must be active and its identifier must be normalized.
  ///
  /// A reserved identifier cannot be registered again.
  void register(
    AppEventSchemaMigrationAuditRepositoryScope scope,
  ) {
    _ensureRegistryActive();
    _removeExternallyDisposedScopes();

    if (!scope.isActive || scope.isDisposed) {
      throw const AppEventSchemaMigrationAuditRepositoryScopeRegistryException(
        code: AppEventSchemaMigrationAuditRepositoryScopeRegistryErrorCode
            .scopeDisposed,
        message: 'An inactive or disposed scope cannot be registered.',
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

    if (_reservedScopeIds.contains(scopeId) ||
        _activeScopes.containsKey(scopeId)) {
      throw AppEventSchemaMigrationAuditRepositoryScopeRegistryException(
        code: AppEventSchemaMigrationAuditRepositoryScopeRegistryErrorCode
            .duplicateScopeId,
        message: 'The scope identifier "$scopeId" is already reserved.',
      );
    }

    // Both mutations happen only after all validation succeeds.
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

    if (scope.scopeId != normalizedId) {
      throw const AppEventSchemaMigrationAuditRepositoryScopeRegistryException(
        code: AppEventSchemaMigrationAuditRepositoryScopeRegistryErrorCode
            .scopeIdentityMismatch,
        message: 'The registered scope identifier does not match its key.',
      );
    }

    if (scope.isDisposed || !scope.isActive) {
      _activeScopes.remove(normalizedId);

      // Keep the identifier reserved until explicit release.
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

    if (scope == null) {
      return false;
    }

    if (scope.scopeId != normalizedId) {
      throw const AppEventSchemaMigrationAuditRepositoryScopeRegistryException(
        code: AppEventSchemaMigrationAuditRepositoryScopeRegistryErrorCode
            .scopeIdentityMismatch,
        message: 'The registered scope identifier does not match its key.',
      );
    }

    if (scope.isDisposed || !scope.isActive) {
      _activeScopes.remove(normalizedId);

      // Reservation is intentionally retained.
      return false;
    }

    return true;
  }

  /// Checks whether an identifier is reserved.
  ///
  /// A reserved identifier cannot be reused until its scope is safely
  /// disposed and its reservation is explicitly released.
  bool isReserved(String scopeId) {
    _ensureRegistryActive();

    return _reservedScopeIds.contains(
      _normalizeScopeId(scopeId),
    );
  }

  /// Disposes and unregisters a scope.
  ///
  /// The identifier is released only after disposal succeeds.
  ///
  /// The repository instance itself remains untouched.
  bool disposeAndUnregister(String scopeId) {
    _ensureRegistryActive();

    final normalizedId = _normalizeScopeId(scopeId);
    final scope = _activeScopes[normalizedId];

    if (scope == null) {
      return false;
    }

    if (scope.scopeId != normalizedId) {
      throw const AppEventSchemaMigrationAuditRepositoryScopeRegistryException(
        code: AppEventSchemaMigrationAuditRepositoryScopeRegistryErrorCode
            .scopeIdentityMismatch,
        message: 'The registered scope identifier does not match its key.',
      );
    }

    // If disposal throws, the registration and reservation are retained.
    // This allows the owner to inspect the failure and retry safely.
    if (!scope.isDisposed) {
      scope.dispose();
    }

    if (!scope.isDisposed) {
      throw const AppEventSchemaMigrationAuditRepositoryScopeRegistryException(
        code: AppEventSchemaMigrationAuditRepositoryScopeRegistryErrorCode
            .scopeDisposed,
        message: 'The scope did not enter the disposed state.',
      );
    }

    _activeScopes.remove(normalizedId);
    _reservedScopeIds.remove(normalizedId);

    return true;
  }

  /// Unregisters a scope without disposing it.
  ///
  /// An active scope remains reserved after unregistration.
  ///
  /// This registry no longer owns the unregistered scope's lifecycle.
  bool unregister(String scopeId) {
    _ensureRegistryActive();

    final normalizedId = _normalizeScopeId(scopeId);
    final scope = _activeScopes[normalizedId];

    if (scope == null) {
      return false;
    }

    if (scope.scopeId != normalizedId) {
      throw const AppEventSchemaMigrationAuditRepositoryScopeRegistryException(
        code: AppEventSchemaMigrationAuditRepositoryScopeRegistryErrorCode
            .scopeIdentityMismatch,
        message: 'The registered scope identifier does not match its key.',
      );
    }

    _activeScopes.remove(normalizedId);

    if (scope.isDisposed) {
      _reservedScopeIds.remove(normalizedId);
    } else {
      _reservedScopeIds.add(normalizedId);
    }

    return true;
  }

  /// Releases a reserved identifier after safe disposal.
  ///
  /// The identifier can only be released when:
  /// - The supplied scope has the requested identifier.
  /// - The supplied scope has been disposed.
  /// - No active scope is registered under that identifier.
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
  /// Every registered scope receives a disposal attempt.
  ///
  /// Previously unregistered scopes are not owned by this registry
  /// and are therefore not disposed here.
  ///
  /// The registry becomes disposed even if one or more scope disposals fail.
  /// The first disposal error is rethrown after all scopes are processed.
  void dispose() {
    if (_disposed) {
      return;
    }

    Object? firstError;
    StackTrace? firstStackTrace;

    final scopes = List<AppEventSchemaMigrationAuditRepositoryScope>.of(
      _activeScopes.values,
    );

    for (final scope in scopes) {
      try {
        if (!scope.isDisposed) {
          scope.dispose();
        }
      } catch (error, stackTrace) {
        firstError ??= error;
        firstStackTrace ??= stackTrace;
      }
    }

    _activeScopes.clear();
    _reservedScopeIds.clear();
    _disposed = true;

    if (firstError != null && firstStackTrace != null) {
      Error.throwWithStackTrace(
        firstError,
        firstStackTrace,
      );
    }
  }

  /// Removes scopes that have already been disposed externally.
  ///
  /// Their identifiers remain reserved until explicit release.
  void _removeExternallyDisposedScopes() {
    final disposedIds = _activeScopes.entries
        .where((entry) => entry.value.isDisposed)
        .map((entry) => entry.key)
        .toList(growable: false);

    for (final scopeId in disposedIds) {
      _activeScopes.remove(scopeId);
    }
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
