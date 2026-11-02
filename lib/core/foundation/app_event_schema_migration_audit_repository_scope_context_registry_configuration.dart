
import 'app_event_schema_migration_audit_repository_scope_context_registry.dart';
import 'app_event_schema_migration_audit_repository_scope_context_registry_provider.dart';

/// Defines the configuration for accessing an externally managed
/// scope context registry.
///
/// This configuration is responsible only for validating the supplied
/// registry and assembling its access provider.
///
/// It does not create, own, or dispose the registry or its resources.
final class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryConfiguration {
  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistry _registry;

  const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryConfiguration({
    required AppEventSchemaMigrationAuditRepositoryScopeContextRegistry registry,
  }) : _registry = registry;

  /// Indicates whether the supplied registry is currently available.
  ///
  /// This is a point-in-time status and does not reserve the registry
  /// against disposal by its external lifecycle owner.
  bool get isRegistryAvailable => !_registry.isDisposed;

  /// Validates the externally supplied registry.
  ///
  /// Throws a configuration exception when the registry has already
  /// been disposed.
  void validate() {
    if (_registry.isDisposed) {
      throw const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryConfigurationException(
        AppEventSchemaMigrationAuditRepositoryScopeContextRegistryConfigurationError
            .registryDisposed,
      );
    }
  }

  /// Creates an access provider for the supplied registry.
  ///
  /// The returned provider does not own the registry. Its lifecycle must
  /// be managed independently by the composition root.
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

/// Configuration validation errors.
enum AppEventSchemaMigrationAuditRepositoryScopeContextRegistryConfigurationError {
  registryDisposed,
}

/// Exception raised when registry configuration is invalid.
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
