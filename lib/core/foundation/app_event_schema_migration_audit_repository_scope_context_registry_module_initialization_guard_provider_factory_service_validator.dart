
import 'package:your_app/core/foundation/app_event_schema_migration_audit_repository_scope_context_registry_module_initialization_guard_provider_factory_service_configuration.dart';

/// Stable validation issue codes for the service configuration validator.
enum AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceValidationCode {
  executorIdentityMismatch(
    code: 'GUARD_PROVIDER_FACTORY_SERVICE_EXECUTOR_IDENTITY_MISMATCH',
    description:
        'The executor referenced by the service is not identical to the configured executor.',
  ),

  factoryConfigurationMismatch(
    code: 'GUARD_PROVIDER_FACTORY_SERVICE_FACTORY_CONFIGURATION_MISMATCH',
    description:
        'The service factory configuration does not match the expected configuration.',
  );

  const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceValidationCode({
    required this.code,
    required this.description,
  });

  /// Machine-readable, stable validation code.
  final String code;

  /// Human-readable explanation of the validation issue.
  final String description;
}

/// A single normalized validation issue.
class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceValidationIssue {
  const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceValidationIssue({
    required this.validationCode,
  });

  final AppEventSchemaMigrationAuditRepositoryScopeContextContextRegistryModuleInitializationGuardProviderFactoryServiceValidationCode validationCode;

  String get code => validationCode.code;

  String get description => validationCode.description;
}

/// Immutable validation report produced by the service validator.
class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceValidationReport {
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceValidationReport({
    required List<
            AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceValidationIssue>
        issues,
  }) : issues = List<
            AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceValidationIssue>.unmodifiable(
          issues,
        );

  final List<
      AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceValidationIssue>
      issues;

  bool get isValid => issues.isEmpty;

  bool get hasIssues => issues.isNotEmpty;

  int get issueCount => issues.length;

  List<String> get issueCodes =>
      List<String>.unmodifiable(issues.map((issue) => issue.code));

  List<String> get issueDescriptions =>
      List<String>.unmodifiable(
        issues.map((issue) => issue.description),
      );
}

/// Validates service configuration without executing the service or executor.
///
/// This validator is deliberately stateless. It does not create, initialize,
/// dispose, or otherwise manage resources. Resource orchestration remains
/// the responsibility of the application Composition Root.
class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceValidator {
  const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceValidator();

  /// Converts configuration validation results into a normalized report.
  ///
  /// Only the configuration object's own validation method is invoked.
  /// The service and executor are never executed.
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceValidationReport
      validate({
    required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceConfiguration
        configuration,
  }) {
    final configurationReport = configuration.validate();

    final issues =
        <AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceValidationIssue>[];

    for (final issue in configurationReport.issues) {
      final validationCode = switch (issue) {
        AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceConfigurationIssue
            .executorIdentityMismatch =>
          AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceValidationCode
              .executorIdentityMismatch,
        AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceConfigurationIssue
            .factoryConfigurationMismatch =>
          AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceValidationCode
              .factoryConfigurationMismatch,
      };

      issues.add(
        AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceValidationIssue(
          validationCode: validationCode,
        ),
      );
    }

    return AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceValidationReport(
      issues: issues,
    );
  }
}
