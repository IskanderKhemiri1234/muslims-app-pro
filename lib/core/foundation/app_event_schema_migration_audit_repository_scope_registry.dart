
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
/// The registry owns the lifecycle of scopes while they remain registered.
/// Unregistered scopes are no longer owned by this registry.
///
/// Repository instances are never disposed by this registry.
///
/// An identifier remains reserved while its scope is registered or while
/// an unregistered scope still requires explicit identifier release.
final class AppEventSchemaMigrationAuditRepositoryScopeRegistry {
  AppEventSchemaMigrationAuditRepositoryScopeRegistry();

  final Map<String, AppEventSchemaMigrationAuditRepositoryScope>
      _activeScopes =
      <String, AppEventSchemaMigrationAuditRepositoryScope>{};

  final Set<String> _reservedScopeIds = <String>{};

  bool _disposed = false;

  /// Number of currently registered, non-disposed scopes.
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

  /// Returns an immutable snapshot of registered scope identifiers.
  Set<String> get activeScopeIds {
    _ensureRegistryActive();
    _removeExternallyDisposedScopes();

    return UnmodifiableSetView<String>(
      Set<String>.of(_activeScopes.keys),
    );
  }

  /// Registers a scope and reserves its identifier.
  ///
  /// The scope must be active, not disposed, and have a normalized ID.
  ///
  /// A previously reserved identifier cannot be registered again.
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

    _reservedScopeIds.add(scopeId);
    _activeScopes[scopeId] = scope;
  }

  /// Retrieves a registered active scope by its identifier.
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
        message: 'No registered scope matches "$normalizedId".',
      );
    }

    _verifyScopeIdentity(
      scope: scope,
      normalizedId: normalizedId,
    );

    if (scope.isDisposed) {
      _activeScopes.remove(normalizedId);

      throw AppEventSchemaMigrationAuditRepositoryScopeRegistryException(
        code: AppEventSchemaMigrationAuditRepositoryScopeRegistryErrorCode
            .scopeDisposed,
        message: 'The scope "$normalizedId" has already been disposed.',
      );
    }

    if (!scope.isActive) {
      throw AppEventSchemaMigrationAuditRepositoryScopeRegistryException(
        code: AppEventSchemaMigrationAuditRepositoryScopeRegistryErrorCode
            .scopeDisposed,
        message: 'The scope "$normalizedId" is not currently active.',
      );
    }

    return scope;
  }

  /// Checks whether a registered scope is active.
  bool contains(String scopeId) {
    _ensureRegistryActive();

    final normalizedId = _normalizeScopeId(scopeId);
    final scope = _activeScopes[normalizedId];

    if (scope == null) {
      return false;
    }

    _verifyScopeIdentity(
      scope: scope,
      normalizedId: normalizedId,
    );

    if (scope.isDisposed) {
      _activeScopes.remove(normalizedId);
      return false;
    }

    return scope.isActive;
  }

  /// Checks whether an identifier is reserved.
  bool isReserved(String scopeId) {
    _ensureRegistryActive();

    return _reservedScopeIds.contains(
      _normalizeScopeId(scopeId),
    );
  }

  /// Disposes and unregisters a scope.
  ///
  /// The identifier is released only after the scope is confirmed disposed.
  ///
  /// If disposal fails before the scope reaches its disposed state,
  /// the scope remains registered and reserved for a later retry.
  ///
  /// If disposal throws after the scope has actually been disposed,
  /// the scope is still unregistered and its identifier is released.
  ///
  /// The repository instance itself remains untouched.
  bool disposeAndUnregister(String scopeId) {
    _ensureRegistryActive();

    final normalizedId = _normalizeScopeId(scopeId);
    final scope = _activeScopes[normalizedId];

    if (scope == null) {
      return false;
    }

    _verifyScopeIdentity(
      scope: scope,
      normalizedId: normalizedId,
    );

    Object? disposalError;
    StackTrace? disposalStackTrace;

    if (!scope.isDisposed) {
      try {
        scope.dispose();
      } catch (error, stackTrace) {
        disposalError = error;
        disposalStackTrace = stackTrace;
      }
    }

    if (!scope.isDisposed) {
      if (disposalError != null && disposalStackTrace != null) {
        Error.throwWithStackTrace(
          disposalError,
          disposalStackTrace,
        );
      }

      throw const AppEventSchemaMigrationAuditRepositoryScopeRegistryException(
        code: AppEventSchemaMigrationAuditRepositoryScopeRegistryErrorCode
            .scopeDisposed,
        message: 'The scope did not enter the disposed state.',
      );
    }

    _activeScopes.remove(normalizedId);
    _reservedScopeIds.remove(normalizedId);

    if (disposalError != null && disposalStackTrace != null) {
      Error.throwWithStackTrace(
        disposalError,
        disposalStackTrace,
      );
    }

    return true;
  }

  /// Unregisters a scope without disposing it.
  ///
  /// The registry relinquishes ownership of the scope.
  ///
  /// An active scope remains reserved after unregistration.
  ///
  /// A disposed scope has its identifier reservation released.
  bool unregister(String scopeId) {
    _ensureRegistryActive();

    final normalizedId = _normalizeScopeId(scopeId);
    final scope = _activeScopes[normalizedId];

    if (scope == null) {
      return false;
    }

    _verifyScopeIdentity(
      scope: scope,
      normalizedId: normalizedId,
    );

    _activeScopes.remove(normalizedId);

    if (scope.isDisposed) {
      _reservedScopeIds.remove(normalizedId);
    } else {
      _reservedScopeIds.add(normalizedId);
    }

    return true;
  }

  /// Releases a reserved identifier after its scope has been disposed.
  ///
  /// The supplied scope must match the identifier and must be disposed.
  ///
  /// No registered scope may still be associated with the identifier.
  bool releaseDisposedScopeId({
    required String scopeId,
    required AppEventSchemaMigrationAuditRepositoryScope scope,
  }) {
    _ensureRegistryActive();

    final normalizedId = _normalizeScopeId(scopeId);

    _verifyScopeIdentity(
      scope: scope,
      normalizedId: normalizedId,
    );

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
  /// Successfully disposed scopes are removed and their identifiers
  /// are released.
  ///
  /// Scopes whose disposal fails remain registered and reserved.
  /// The registry remains active so a later call can retry cleanup.
  ///
  /// Previously unregistered scopes are not owned or disposed here.
  ///
  /// Repository instances are never disposed by this operation.
  ///
  /// The first disposal error is rethrown after all registered scopes
  /// have been processed.
  void dispose() {
    if (_disposed) {
      return;
    }

    Object? firstError;
    StackTrace? firstStackTrace;

    final scopes = List<
        MapEntry<
            String,
            AppEventSchemaMigrationAuditRepositoryScope>>.of(
      _activeScopes.entries,
    );

    for (final entry in scopes) {
      final scopeId = entry.key;
      final scope = entry.value;

      try {
        _verifyScopeIdentity(
          scope: scope,
          normalizedId: scopeId,
        );

        if (!scope.isDisposed) {
          scope.dispose();
        }

        if (!scope.isDisposed) {
          throw const AppEventSchemaMigrationAuditRepositoryScopeRegistryException(
            code:
                AppEventSchemaMigrationAuditRepositoryScopeRegistryErrorCode
                    .scopeDisposed,
            message: 'A registered scope did not enter the disposed state.',
          );
        }

        _activeScopes.remove(scopeId);
        _reservedScopeIds.remove(scopeId);
      } catch (error, stackTrace) {
        firstError ??= error;
        firstStackTrace ??= stackTrace;

        if (scope.isDisposed) {
          _activeScopes.remove(scopeId);
          _reservedScopeIds.remove(scopeId);
        }
      }
    }

    if (_activeScopes.isEmpty) {
      _reservedScopeIds.clear();
      _disposed = true;
    }

    if (firstError != null && firstStackTrace != null) {
      Error.throwWithStackTrace(
        firstError,
        firstStackTrace,
      );
    }
  }

  /// Removes scopes that have already been disposed externally.
  ///
  /// Their identifiers remain reserved until explicitly released.
  ///
  /// Non-disposed scopes are retained even when inactive because the
  /// registry must not silently abandon ownership of those scopes.
  void _removeExternallyDisposedScopes() {
    final disposedIds = _activeScopes.entries
        .where((entry) => entry.value.isDisposed)
        .map((entry) => entry.key)
        .toList(growable: false);

    for (final scopeId in disposedIds) {
      _activeScopes.remove(scopeId);
    }
  }

  void _verifyScopeIdentity({
    required AppEventSchemaMigrationAuditRepositoryScope scope,
    required String normalizedId,
  }) {
    if (scope.scopeId != normalizedId) {
      throw const AppEventSchemaMigrationAuditRepositoryScopeRegistryException(
        code: AppEventSchemaMigrationAuditRepositoryScopeRegistryErrorCode
            .scopeIdentityMismatch,
        message: 'The registered scope identifier does not match its key.',
      );
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
