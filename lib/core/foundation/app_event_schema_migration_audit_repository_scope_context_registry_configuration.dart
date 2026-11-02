
import 'app_event_schema_migration_audit_repository_scope_context_registry.dart';
import 'app_event_schema_migration_audit_repository_scope_context_registry_provider.dart';

/// Defines the configuration for accessing an externally managed
/// scope context registry.
///
/// This configuration validates the supplied registry and creates
/// access providers for it.
///
/// Ownership remains external:
/// - The configuration does not create the registry.
/// - The configuration does not own the registry.
/// - The configuration does not dispose the registry.
/// - Providers created by this configuration do not own the registry.
final class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryConfiguration {
  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistry _registry;

  const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryConfiguration({
    required AppEventSchemaMigrationAuditRepositoryScopeContextRegistry registry,
  }) : _registry = registry;

  /// Indicates whether the externally managed registry is currently active.
  ///
  /// This is a point-in-time status check. It does not prevent the external
  /// owner from disposing the registry immediately afterward.
  bool get isRegistryAvailable => !_registry.isDisposed;

  /// Validates that the supplied registry is still active.
  ///
  /// Throws a configuration exception if the registry has been disposed.
  void validate() {
    if (_registry.isDisposed) {
      throw const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryConfigurationException(
        AppEventSchemaMigrationAuditRepositoryScopeContextRegistryConfigurationError
            .registryDisposed,
      );
    }
  }

  /// Creates a new access provider for the externally managed registry.
  ///
  /// Each invocation creates a distinct provider instance.
  /// The returned provider owns only its own access lifecycle and never
  /// owns or disposes the injected registry.
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryProvider
      createProvider() {
    validate();

    return AppEventSchemaMigrationAuditRepositoryScopeContextRegistryProvider(
      registry: _registry,
    );
  }

  /// Returns the original externally managed registry.
  ///
  /// Access is permitted only while the registry remains active.
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistry get registry {
    validate();
    return _registry;
  }
}

/// Errors emitted during registry configuration validation.
enum AppEventSchemaMigrationAuditRepositoryScopeContextRegistryConfigurationError {
  registryDisposed,
}

/// Exception raised when the supplied registry configuration is unavailable.
final class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryConfigurationException
    implements Exception {
  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryConfigurationError
      code;

  const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryConfigurationException(
    this.code,
  );

  @override
  String toString() {
    return 'AppEventSchemaMigrationAuditRepositoryScopeContextRegistryConfigurationException'
        '(code: ${code.name})';
  }
}
