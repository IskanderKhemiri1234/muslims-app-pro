
import 'app_event_schema_migration_audit_repository_scope_context_registry_configuration.dart';
import 'app_event_schema_migration_audit_repository_scope_context_registry_module.dart';

/// Contract for creating scope context registry modules.
///
/// Implementations receive an existing configuration and return a module
/// configured to use its externally managed registry.
///
/// Factories do not own the returned module or any resources referenced
/// by its configuration.
abstract interface class
    AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleFactory {
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModule create({
    required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryConfiguration
        configuration,
  });
}

/// Default factory for scope context registry modules.
///
/// This factory performs composition only:
/// - It validates the supplied configuration.
/// - It creates a module using that configuration.
/// - It does not create a registry.
/// - It does not initialize the module.
/// - It does not dispose the module or its resources.
final class
    DefaultAppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleFactory
    implements
        AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleFactory {
  const DefaultAppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleFactory();

  @override
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModule create({
    required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryConfiguration
        configuration,
  }) {
    configuration.validate();

    return AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModule(
      configuration: configuration,
    );
  }
}
