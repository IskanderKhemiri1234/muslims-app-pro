
import 'dart:collection';

import 'app_event_schema_migration_audit_repository_scope_context.dart';
import 'app_event_schema_migration_audit_repository_scope_context_provider.dart';

/// Manages the registration of injected scope context providers.
///
/// The registry owns only its provider-to-identifier associations.
/// It does not own providers, scopes, repositories, or their lifecycles.
final class AppEventSchemaMigrationAuditRepositoryScopeContextRegistry {
  final Map<String, AppEventSchemaMigrationAuditRepositoryScopeContextProvider>
      _providers = {};

  final Set<String> _reservedScopeIds = {};

  bool _isDisposed = false;

  /// Indicates whether this registry has been disposed.
  bool get isDisposed => _isDisposed;

  /// Number of currently registered providers.
  int get registeredProviderCount {
    _ensureNotDisposed();
    return _providers.length;
  }

  /// Returns an immutable snapshot of registered scope identifiers.
  Set<String> get registeredScopeIds {
    _ensureNotDisposed();

    return UnmodifiableSetView<String>(
      _providers.keys.toSet(),
    );
  }

  /// Returns an immutable snapshot of all identifiers reserved during
  /// this registry's lifetime.
  ///
  /// Reserved identifiers cannot be reused after unregistration.
  Set<String> get reservedScopeIds {
    _ensureNotDisposed();

    return UnmodifiableSetView<String>(
      Set<String>.from(_reservedScopeIds),
    );
  }

  /// Registers an already-created and injected context provider.
  ///
  /// The identifier is normalized before registration.
  /// Duplicate and previously reserved identifiers are rejected.
  ///
  /// The provider is stored by reference and is not copied or disposed.
  void register({
    required String scopeId,
    required AppEventSchemaMigrationAuditRepositoryScopeContextProvider
        provider,
  }) {
    _ensureNotDisposed();

    final normalizedScopeId = _normalizeScopeId(scopeId);

    if (_reservedScopeIds.contains(normalizedScopeId)) {
      throw AppEventSchemaMigrationAuditRepositoryScopeContextRegistryException(
        code:
            AppEventSchemaMigrationAuditRepositoryScopeContextRegistryError
                .duplicateScopeId,
        scopeId: normalizedScopeId,
      );
    }

    _providers[normalizedScopeId] = provider;
    _reservedScopeIds.add(normalizedScopeId);
  }

  /// Returns the provider registered for the supplied identifier.
  ///
  /// The returned provider remains owned by its original composition
  /// boundary, not by this registry.
  AppEventSchemaMigrationAuditRepositoryScopeContextProvider getProvider({
    required String scopeId,
  }) {
    _ensureNotDisposed();

    final normalizedScopeId = _normalizeScopeId(scopeId);
    final provider = _providers[normalizedScopeId];

    if (provider == null) {
      throw AppEventSchemaMigrationAuditRepositoryScopeContextRegistryException(
        code:
            AppEventSchemaMigrationAuditRepositoryScopeContextRegistryError
                .providerNotFound,
        scopeId: normalizedScopeId,
      );
    }

    return provider;
  }

  /// Resolves a context through the provider registered for the identifier.
  ///
  /// The provider remains responsible for resolving and validating the
  /// underlying scope through its injected resolver.
  AppEventSchemaMigrationAuditRepositoryScopeContext provideContext({
    required String scopeId,
  }) {
    _ensureNotDisposed();

    final normalizedScopeId = _normalizeScopeId(scopeId);
    final provider = getProvider(
      scopeId: normalizedScopeId,
    );

    final context = provider.provide(
      scopeId: normalizedScopeId,
    );

    if (context.scopeId != normalizedScopeId) {
      throw AppEventSchemaMigrationAuditRepositoryScopeContextRegistryException(
        code:
            AppEventSchemaMigrationAuditRepositoryScopeContextRegistryError
                .scopeIdentityMismatch,
        scopeId: normalizedScopeId,
      );
    }

    context.verifyActive();

    return context;
  }

  /// Checks whether an identifier currently has a registered provider.
  bool contains({
    required String scopeId,
  }) {
    _ensureNotDisposed();

    final normalizedScopeId = _normalizeScopeId(scopeId);

    return _providers.containsKey(normalizedScopeId);
  }

  /// Checks whether an identifier has ever been reserved by this registry.
  bool isReserved({
    required String scopeId,
  }) {
    _ensureNotDisposed();

    final normalizedScopeId = _normalizeScopeId(scopeId);

    return _reservedScopeIds.contains(normalizedScopeId);
  }

  /// Unregisters a provider without disposing it.
  ///
  /// The identifier remains reserved and cannot be registered again during
  /// this registry's lifetime. This prevents accidental reassignment of a
  /// scope identifier to a different provider.
  bool unregister({
    required String scopeId,
  }) {
    _ensureNotDisposed();

    final normalizedScopeId = _normalizeScopeId(scopeId);

    return _providers.remove(normalizedScopeId) != null;
  }

  /// Disposes the registry's internal associations.
  ///
  /// This operation does not dispose providers, scopes, or repositories.
  /// After disposal, the registry cannot be used again.
  void dispose() {
    if (_isDisposed) {
      return;
    }

    _providers.clear();
    _reservedScopeIds.clear();
    _isDisposed = true;
  }

  String _normalizeScopeId(String value) {
    final normalized = value.trim();

    if (normalized.isEmpty) {
      throw const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryException(
        code:
            AppEventSchemaMigrationAuditRepositoryScopeContextRegistryError
                .invalidScopeId,
      );
    }

    if (normalized.length > 128) {
      throw const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryException(
        code:
            AppEventSchemaMigrationAuditRepositoryScopeContextRegistryError
                .scopeIdTooLong,
      );
    }

    return normalized;
  }

  void _ensureNotDisposed() {
    if (_isDisposed) {
      throw const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryException(
        code:
            AppEventSchemaMigrationAuditRepositoryScopeContextRegistryError
                .registryDisposed,
      );
    }
  }
}

/// Error codes emitted by the context provider registry.
enum AppEventSchemaMigrationAuditRepositoryScopeContextRegistryError {
  invalidScopeId,
  scopeIdTooLong,
  duplicateScopeId,
  providerNotFound,
  scopeIdentityMismatch,
  registryDisposed,
}

/// Exception raised by context provider registry operations.
final class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryException
    implements Exception {
  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryError code;
  final String? scopeId;

  const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryException({
    required this.code,
    this.scopeId,
  });

  @override
  String toString() {
    final identifier = scopeId;

    if (identifier == null) {
      return 'AppEventSchemaMigrationAuditRepositoryScopeContextRegistryException'
          '(code: ${code.name})';
    }

    return 'AppEventSchemaMigrationAuditRepositoryScopeContextRegistryException'
        '(code: ${code.name}, scopeId: $identifier)';
  }
}
