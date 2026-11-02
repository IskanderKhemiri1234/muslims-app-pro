
import 'app_event_schema_migration_audit_repository_scope_context_registry_module_initialization_guard_provider_factory_configuration.dart';
import 'app_event_schema_migration_audit_repository_scope_context_registry_module_initialization_guard_provider_factory_result.dart';
import 'app_event_schema_migration_audit_repository_scope_context_registry_module_initialization_guard_provider_factory_validator.dart';

/// Executes validation of an initialization guard provider factory setup.
///
/// This executor is deliberately limited to:
/// - Invoking the factory configuration validator.
/// - Converting its validation report into a unified result.
///
/// It does not:
/// - Invoke the provider factory.
/// - Create or replace a provider or guard.
/// - Take ownership of external resources.
/// - Request or consume initialization permits.
/// - Initialize or dispose modules.
/// - Coordinate concurrent initialization operations.
///
/// The Composition Root remains responsible for deciding when this
/// executor is called and for coordinating subsequent operations.
final class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryExecutor {
  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryValidator
      _validator;

  /// Creates an executor using an externally supplied validator.
  ///
  /// The executor does not own the validator and does not manage its
  /// lifecycle.
  const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryExecutor({
    required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryValidator
        validator,
  }) : _validator = validator;

  /// Validates [configuration] and returns a unified result.
  ///
  /// A successful result indicates only that validation found no issues
  /// during this call. It does not authorize or perform initialization.
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryResult
      execute({
    required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryConfiguration
        configuration,
  }) {
    final validationReport = _validator.validate(
      configuration: configuration,
    );

    return AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryResult.fromReport(
      validationReport: validationReport,
    );
  }
}
