
import 'app_event_schema_migration_audit_repository_scope_context_registry_lifecycle_module.dart';
import 'app_event_schema_migration_audit_repository_scope_context_registry_lifecycle_observer.dart';

/// Identifies a configuration validation issue.
enum AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleConfigurationIssue {
  lifecycleAssemblyDisposed,
  lifecycleControllerUnavailable,
  observerDispatcherUnavailable,
  registryModuleUnavailable,
}

/// Immutable validation report for lifecycle module configuration.
class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleConfigurationValidation {
  final List<
      AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleConfigurationIssue>
      issues;

  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleConfigurationValidation({
    required List<
            AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleConfigurationIssue>
        issues,
  }) : issues = List.unmodifiable(issues);

  bool get isValid => issues.isEmpty;

  bool get hasIssues => issues.isNotEmpty;

  bool hasIssue(
    AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleConfigurationIssue
        issue,
  ) {
    return issues.contains(issue);
  }
}

/// Describes the dependencies required by the registry lifecycle module.
///
/// This configuration is non-owning. It stores references supplied by the
/// composition root and never creates, initializes, or disposes resources.
class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleConfiguration {
  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModule
      lifecycleModule;

  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleObserverDispatcher
      observerDispatcher;

  const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleConfiguration({
    required this.lifecycleModule,
    required this.observerDispatcher,
  });

  /// Validates the supplied lifecycle module and its required dependencies.
  ///
  /// A valid result confirms that the assembly has not already been disposed
  /// and that the module exposes its required lifecycle dependencies.
  ///
  /// This method does not initialize or mutate any dependency.
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleConfigurationValidation
      validate() {
    final issues = <
        AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleConfigurationIssue>[];

    if (lifecycleModule.isLifecycleDisposed) {
      issues.add(
        AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleConfigurationIssue
            .lifecycleAssemblyDisposed,
      );
    }

    if (lifecycleModule.lifecycleController == null) {
      issues.add(
        AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleConfigurationIssue
            .lifecycleControllerUnavailable,
      );
    }

    if (lifecycleModule.observerDispatcher != observerDispatcher) {
      issues.add(
        AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleConfigurationIssue
            .observerDispatcherUnavailable,
      );
    }

    if (lifecycleModule.registryModule == null) {
      issues.add(
        AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleConfigurationIssue
            .registryModuleUnavailable,
      );
    }

    return AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleConfigurationValidation(
      issues: issues,
    );
  }

  bool get isValid => validate().isValid;
}
