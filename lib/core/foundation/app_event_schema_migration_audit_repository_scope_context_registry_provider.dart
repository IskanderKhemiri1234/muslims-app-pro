
import 'app_event_schema_migration_audit_repository_scope_context_registry.dart';

/// Provides controlled access to an externally managed scope context
/// registry.
///
/// This provider is an access boundary only.
///
/// It does not:
/// - Create or dispose the registry.
/// - Register or unregister scope providers.
/// - Own scope contexts.
/// - Own repositories.
/// - Prevent the external registry owner from disposing the registry.
final class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryProvider {
  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistry _registry;

  bool _isDisposed = false;

  /// Creates an access provider around an externally managed registry.
  ///
  /// The registry must be created and managed by the composition root
  /// or another explicitly designated lifecycle owner.
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
  /// Throws a provider exception if either the provider or registry
  /// is no longer available.
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistry get registry {
    _ensureProviderActive();
    _ensureRegistryActive();

    return _registry;
  }

  /// Provides a registered context through the injected registry.
  ///
  /// The registry remains responsible for:
  /// - Scope provider lookup.
  /// - Scope identity verification.
  /// - Active-context validation.
  AppEventSchemaMigrationAuditRepositoryScopeContext provideContext({
    required String scopeId,
  }) {
    _ensureProviderActive();
    _ensureRegistryActive();

    return _registry.provideContext(scopeId: scopeId);
  }

  /// Executes a synchronous operation using the injected registry.
  ///
  /// Both lifecycle states are validated immediately before the callback
  /// is invoked.
  ///
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
  /// The provider and registry are validated before the callback starts.
  ///
  /// This method does not lock the registry and does not prevent its
  /// external owner from disposing it while the asynchronous operation
  /// is pending.
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
  /// This operation is idempotent.
  ///
  /// The injected registry and all resources reachable through it remain
  /// owned by their original lifecycle owner.
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
