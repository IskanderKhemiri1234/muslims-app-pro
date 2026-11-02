import 'app_event_schema_migration_audit_repository_scope_context_registry_module_initialization_guard_provider_factory_configuration.dart';
import 'app_event_schema_migration_audit_repository_scope_context_registry_module_initialization_guard_provider_factory_executor.dart';
import 'app_event_schema_migration_audit_repository_scope_context_registry_module_initialization_guard_provider_factory_result.dart';

/// Coordinates validation requests for an initialization guard provider
/// factory configuration.
///
/// This service is intentionally limited to delegating validation to an
/// externally supplied executor and returning its unified result.
///
/// It does not:
/// - Create or invoke a provider factory.
/// - Create, replace, or own a provider or initialization guard.
/// - Request or consume initialization permits.
/// - Initialize, disable, or dispose external resources.
/// - Coordinate concurrent operations across the Composition Root.
final class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryService {
  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryExecutor
      _executor;

  /// Creates the service with an externally supplied executor.
  ///
  /// The service does not own the executor or manage its lifecycle.
  const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryService({
    required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryExecutor
        executor,
  }) : _executor = executor;

  /// Exposes the injected executor for identity validation.
  ///
  /// This does not transfer ownership.
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryExecutor
      get executor => _executor;

  /// Validates the supplied factory configuration.
  ///
  /// Returns a unified validation result.
  ///
  /// A successful result means only that no validation issues were found
  /// during this operation. It does not indicate that a provider was
  /// created or that a module is initialized.
  ///
  /// Unexpected exceptions from the executor are deliberately propagated
  /// to the caller.
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryResult
      validateConfiguration({
    required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryConfiguration
        configuration,
  }) {
    return _executor.execute(
      configuration: configuration,
    );
  }
}
