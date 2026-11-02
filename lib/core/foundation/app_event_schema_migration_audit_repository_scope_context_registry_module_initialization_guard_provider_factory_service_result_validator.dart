
import 'app_event_schema_migration_audit_repository_scope_context_registry_module_initialization_guard_provider_factory_service_result.dart';

/// Stable issue codes produced when a service result is inconsistent.
enum AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultValidationCode {
  statusReportMismatch(
    code: 'SERVICE_RESULT_STATUS_REPORT_MISMATCH',
    description:
        'The service result status does not agree with the validation report.',
  );

  const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultValidationCode({
    required this.code,
    required this.description,
  });

  final String code;

  final String description;
}

/// A normalized issue found while inspecting a service result.
class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultValidationIssue {
  const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultValidationIssue({
    required this.validationCode,
  });

  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultValidationCode
      validationCode;

  String get code => validationCode.code;

  String get description => validationCode.description;
}

/// Immutable report describing the structural consistency of a service result.
class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultValidationReport {
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultValidationReport({
    required List<
            AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultValidationIssue>
        issues,
  }) : issues = List<
            AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultValidationIssue>.unmodifiable(
          issues,
        );

  final List<
      AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultValidationIssue>
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

/// Inspects the consistency of a service validation result.
///
/// This validator does not rerun configuration validation, execute the
/// service, invoke an executor, create resources, or control initialization.
/// It only compares the result status with the report already contained
/// in that result.
class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultValidator {
  const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultValidator();

  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultValidationReport
      validate({
    required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResult
        result,
  }) {
    final issues =
        <AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultValidationIssue>[];

    final reportIndicatesSuccess = result.validationReport.isValid;

    final resultIndicatesSuccess = result.isSuccessful;

    if (reportIndicatesSuccess != resultIndicatesSuccess) {
      issues.add(
        const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultValidationIssue(
          validationCode:
              AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultValidationCode
                  .statusReportMismatch,
        ),
      );
    }

    return AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultValidationReport(
      issues: issues,
    );
  }
}
