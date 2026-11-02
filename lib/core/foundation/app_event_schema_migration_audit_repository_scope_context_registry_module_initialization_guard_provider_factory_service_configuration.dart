
import 'app_event_schema_migration_audit_repository_scope_context_registry_module_initialization_guard_provider_factory_configuration.dart';
import 'app_event_schema_migration_audit_repository_scope_context_registry_module_initialization_guard_provider_factory_executor.dart';
import 'app_event_schema_migration_audit_repository_scope_context_registry_module_initialization_guard_provider_factory_service.dart';

/// Validation findings for the factory service configuration.
enum AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceConfigurationIssue {
  executorIdentityMismatch,
  factoryConfigurationMismatch,
}

/// Immutable validation report for the factory service configuration.
final class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceConfigurationReport {
  final List<
      AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceConfigurationIssue>
      issues;

  const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceConfigurationReport({
    required this.issues,
  });

  bool get isValid => issues.isEmpty;

  bool get hasIssues => issues.isNotEmpty;

  int get issueCount => issues.length;
}

/// Describes the dependencies and compatibility requirements of the
/// initialization guard provider factory service.
///
/// This object is descriptive and validation-only. It does not:
/// - Create a service, executor, factory, provider, or guard.
/// - Invoke the factory or executor.
/// - Take ownership of any supplied dependency.
/// - Dispose or disable external resources.
/// - Request or consume initialization permits.
/// - Initialize modules or coordinate concurrent operations.
final class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceConfiguration {
  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryService
      service;

  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryExecutor
      executor;

  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryConfiguration
      factoryConfiguration;

  const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceConfiguration({
    required this.service,
    required this.executor,
    required this.factoryConfiguration,
  });

  /// Validates the service's executor identity.
  ///
  /// The service must reference the exact executor supplied to this
  /// configuration.
  ///
  /// The factory configuration is retained as the intended configuration
  /// context. The service API does not expose its internal configuration
  /// because it receives that configuration as an argument per operation.
  ///
  /// Consequently, this method cannot prove that the service has previously
  /// processed, or will process, [factoryConfiguration].
  ///
  /// No service method or executor operation is invoked.
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceConfigurationReport
      validate() {
    final issues = <
        AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceConfigurationIssue>[];

    if (!identical(service.executor, executor)) {
      issues.add(
        AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceConfigurationIssue
            .executorIdentityMismatch,
      );
    }

    return AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceConfigurationReport(
      issues: List<
          AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceConfigurationIssue>.unmodifiable(
        issues,
      ),
    );
  }
}
