
import 'app_event_schema_migration_audit_repository_scope_context_registry.dart';

/// Provides controlled access to an externally managed scope context
/// registry.
///
/// This provider is an access boundary only.
///
/// Ownership contract:
/// - The registry is externally owned.
/// - This provider owns no registry resources.
/// - This provider does not register or unregister scope providers.
/// - This provider does not own scope contexts or repositories.
/// - Disposing this provider never disposes the injected registry.
/// - The external registry owner may dispose the registry independently.
final class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryProvider {
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryProvider({
    required AppEventSchemaMigrationAuditRepositoryScopeContextRegistry
        registry,
  }) : _registry = registry;

  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistry _registry;

  bool _isDisposed = false;

  /// Indicates whether this access provider has been disposed.
  bool get isDisposed => _isDisposed;

  /// Returns the injected registry after validating both lifecycle states.
  ///
  /// Throws [AppEventSchemaMigrationAuditRepositoryScopeContextRegistryProviderException]
  /// when the provider or external registry is no longer available.
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistry get registry {
    _ensureProviderActive();
    _ensureRegistryActive();

    return _registry;
  }

  /// Provides a registered context through the injected registry.
  ///
  /// Scope lookup, identity verification, and active-context validation
  /// remain the responsibility of the registry.
  AppEventSchemaMigrationAuditRepositoryScopeContext provideContext({
    required String scopeId,
  }) {
    final activeRegistry = registry;

    return activeRegistry.provideContext(scopeId: scopeId);
  }

  /// Executes a synchronous operation using the injected registry.
  ///
  /// The provider and registry are checked immediately before invoking
  /// the callback.
  ///
  /// The callback must not retain the registry beyond its intended
  /// lifecycle boundary.
  T execute<T>(
    T Function(
      AppEventSchemaMigrationAuditRepositoryScopeContextRegistry registry,
    ) operation,
  ) {
    final activeRegistry = registry;

    return operation(activeRegistry);
  }

  /// Executes an asynchronous operation using the injected registry.
  ///
  /// The provider and registry are checked before the callback begins.
  ///
  /// This method does not lock the registry or prevent its external owner
  /// from disposing it while the asynchronous operation is pending.
  ///
  /// The operation is responsible for handling failures caused by external
  /// registry disposal during its execution.
  Future<T> executeAsync<T>(
    Future<T> Function(
      AppEventSchemaMigrationAuditRepositoryScopeContextRegistry registry,
    ) operation,
  ) {
    final activeRegistry = registry;

    return operation(activeRegistry);
  }

  /// Disables further access through this provider.
  ///
  /// Idempotent.
  ///
  /// Does not dispose the injected registry or any resources reachable
  /// through it.
  void dispose() {
    if (_isDisposed) {
      return;
    }

    _isDisposed = true;
  }

  void _ensureProviderActive() {
    if (_isDisposed) {
      throw const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryProviderException(
        AppEventSchemaMigrationAuditRepositoryScopeContextRegistryProviderError
            .providerDisposed,
      );
    }
  }

  void _ensureRegistryActive() {
    if (_registry.isDisposed) {
      throw const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryProviderException(
        AppEventSchemaMigrationAuditRepositoryScopeContextRegistryProviderError
            .registryDisposed,
      );
    }
  }
}

/// Error codes emitted by the registry access provider.
enum AppEventSchemaMigrationAuditRepositoryScopeContextRegistryProviderError {
  providerDisposed,
  registryDisposed,
}

/// Exception raised when registry access is unavailable.
final class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryProviderException
    implements Exception {
  const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryProviderException(
    this.code,
  );

  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryProviderError
      code;

  @override
  String toString() {
    return 'AppEventSchemaMigrationAuditRepositoryScopeContextRegistryProviderException'
        '(code: ${code.name})';
  }
}
