
import 'app_event_schema_migration_audit_repository_scope_context_registry.dart';

/// Provides access to an explicitly injected scope context registry.
///
/// This provider is a dependency access boundary only.
/// It does not create, register, unregister, or dispose registries.
/// It does not own providers, scopes, or repositories.
final class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryProvider {
  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistry _registry;

  bool _isDisposed = false;

  /// Creates an access provider around an externally managed registry.
  ///
  /// The registry must be created and managed by the composition root or
  /// another explicitly designated lifecycle owner.
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryProvider({
    required AppEventSchemaMigrationAuditRepositoryScopeContextRegistry
        registry,
  }) : _registry = registry;

  /// Indicates whether this access provider has been disposed.
  ///
  /// Disposing this provider does not dispose the injected registry.
  bool get isDisposed => _isDisposed;

  /// Returns the injected registry after validating both lifecycle states.
  ///
  /// The registry remains externally owned.
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistry get registry {
    _ensureProviderActive();
    _ensureRegistryActive();

    return _registry;
  }

  /// Provides a registered context through the injected registry.
  ///
  /// The registry performs provider lookup, scope identity verification,
  /// and active-context validation.
  AppEventSchemaMigrationAuditRepositoryScopeContext provideContext({
    required String scopeId,
  }) {
    _ensureProviderActive();
    _ensureRegistryActive();

    return _registry.provideContext(scopeId: scopeId);
  }

  /// Executes a synchronous operation using the injected registry.
  ///
  /// The registry is validated immediately before the callback is invoked.
  /// This method does not transfer ownership of the registry.
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
  /// The registry is validated before the callback starts. This provider
  /// does not lock the registry or prevent its external owner from disposing
  /// it while the asynchronous operation is pending.
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
  /// The injected registry and all resources reachable through it remain
  /// owned by their original lifecycle owner.
  void dispose() {
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
  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryProviderError
      code;

  const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryProviderException(
    this.code,
  );

  @override
  String toString() {
    return 'AppEventSchemaMigrationAuditRepositoryScopeContextRegistryProviderException'
        '(code: ${code.name})';
  }
}
