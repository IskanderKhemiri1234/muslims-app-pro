
import 'app_event_schema_migration_audit_repository_scope_context_registry_configuration.dart';
import 'app_event_schema_migration_audit_repository_scope_context_registry_module.dart';
import 'app_event_schema_migration_audit_repository_scope_context_registry_module_factory.dart';

/// Composes a registry module from an externally supplied configuration
/// and an injected module factory.
///
/// This component performs dependency composition only.
///
/// Ownership boundaries:
/// - The composition root creates and owns the registry.
/// - The composition root supplies the configuration.
/// - The composition component does not retain created modules.
/// - The composition component does not initialize or dispose modules.
/// - The module does not own the externally supplied registry.
final class
    AppEventSchemaMigrationAuditRepositoryScopeContextRegistryComposition {
  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleFactory
      _factory;

  const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryComposition({
    required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleFactory
        factory,
  }) : _factory = factory;

  /// Composes a new, uninitialized registry module.
  ///
  /// The configuration must reference an existing, externally managed
  /// registry. It is validated before the factory is invoked.
  ///
  /// The returned module is not initialized automatically. Its lifecycle
  /// remains the responsibility of the composition root.
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModule compose({
    required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryConfiguration
        configuration,
  }) {
    configuration.validate();

    return _factory.create(
      configuration: configuration,
    );
  }
}
