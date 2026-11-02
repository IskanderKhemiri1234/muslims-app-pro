
import 'app_event_schema_migration_audit_repository_scope_context_registry_lifecycle_module_configuration.dart';

/// Describes the final outcome of lifecycle module validation.
enum AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleValidationStatus {
  valid,
  invalid,
}

/// Represents a normalized validation issue.
class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleValidationIssue {
  final String code;
  final String description;

  const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleValidationIssue({
    required this.code,
    required this.description,
  });

  @override
  String toString() => '$code: $description';
}

/// Immutable validation report exposed to the composition root.
class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleValidationReport {
  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleValidationStatus
      status;

  final List<
      AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleValidationIssue>
      issues;

  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleValidationReport({
    required this.status,
    required List<
            AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleValidationIssue>
        issues,
  }) : issues = List.unmodifiable(issues);

  bool get isValid =>
      status ==
      AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleValidationStatus
          .valid;

  bool get isInvalid => !isValid;

  bool get hasIssues => issues.isNotEmpty;

  int get issueCount => issues.length;
}

/// Validates lifecycle module configuration without taking ownership of
/// the module or any of its dependencies.
class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleValidator {
  const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleValidator();

  /// Validates the configuration and translates its issues into a stable
  /// report for the composition root.
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleValidationReport
      validate(
    AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleConfiguration
        configuration,
  ) {
    final validation = configuration.validate();

    final issues =
        <AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleValidationIssue>[];

    for (final issue in validation.issues) {
      issues.add(
        AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleValidationIssue(
          code: _issueCode(issue),
          description: _issueDescription(issue),
        ),
      );
    }

    return AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleValidationReport(
      status: issues.isEmpty
          ? AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleValidationStatus
              .valid
          : AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleValidationStatus
              .invalid,
      issues: issues,
    );
  }

  String _issueCode(
    AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleConfigurationIssue
        issue,
  ) {
    switch (issue) {
      case AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleConfigurationIssue
            .lifecycleAssemblyDisposed:
        return 'lifecycle_assembly_disposed';

      case AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleConfigurationIssue
            .lifecycleControllerUnavailable:
        return 'lifecycle_controller_unavailable';

      case AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleConfigurationIssue
            .observerDispatcherUnavailable:
        return 'observer_dispatcher_mismatch';

      case AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleConfigurationIssue
            .registryModuleUnavailable:
        return 'registry_module_unavailable';
    }
  }

  String _issueDescription(
    AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleConfigurationIssue
        issue,
  ) {
    switch (issue) {
      case AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleConfigurationIssue
            .lifecycleAssemblyDisposed:
        return 'The lifecycle assembly is already disposed.';

      case AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleConfigurationIssue
            .lifecycleControllerUnavailable:
        return 'The lifecycle controller is unavailable.';

      case AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleConfigurationIssue
            .observerDispatcherUnavailable:
        return 'The configured observer dispatcher does not match the module dispatcher.';

      case AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleConfigurationIssue
            .registryModuleUnavailable:
        return 'The registry module is unavailable.';
    }
  }
}
