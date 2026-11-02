
import 'app_event_schema_migration_audit_repository_scope_context_registry_module_initialization_guard_provider_factory_validator.dart';

/// Describes the outcome of validating a guard provider factory setup.
enum AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryResultStatus {
  validationSucceeded,
  validationFailed,
}

/// Immutable result of a guard provider factory validation operation.
///
/// A successful result means only that the associated validation report
/// contains no findings. It does not mean that:
/// - A provider was created.
/// - A guard was created.
/// - A module was initialized.
/// - An initialization permit was requested or consumed.
/// - Any external resource became owned by this result.
final class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryResult {
  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryResultStatus
      status;

  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryValidationReport
      validationReport;

  const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryResult._({
    required this.status,
    required this.validationReport,
  });

  /// Creates a successful validation result.
  ///
  /// Throws [ArgumentError] if [validationReport] contains validation issues.
  factory AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryResult.validationSucceeded({
    required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryValidationReport
        validationReport,
  }) {
    if (!validationReport.isValid) {
      throw ArgumentError.value(
        validationReport,
        'validationReport',
        'A successful validation result requires a report without issues.',
      );
    }

    return AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryResult._(
      status: AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryResultStatus
          .validationSucceeded,
      validationReport: validationReport,
    );
  }

  /// Creates a failed validation result.
  ///
  /// Throws [ArgumentError] if [validationReport] contains no validation
  /// issues.
  factory AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryResult.validationFailed({
    required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryValidationReport
        validationReport,
  }) {
    if (!validationReport.hasIssues) {
      throw ArgumentError.value(
        validationReport,
        'validationReport',
        'A failed validation result requires at least one validation issue.',
      );
    }

    return AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryResult._(
      status: AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryResultStatus
          .validationFailed,
      validationReport: validationReport,
    );
  }

  /// Creates a result whose status is derived from the validation report.
  factory AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryResult.fromReport({
    required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryValidationReport
        validationReport,
  }) {
    if (validationReport.isValid) {
      return AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryResult.validationSucceeded(
        validationReport: validationReport,
      );
    }

    return AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryResult.validationFailed(
      validationReport: validationReport,
    );
  }

  /// Whether validation completed without findings.
  bool get isValidationSuccessful =>
      status ==
      AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryResultStatus
          .validationSucceeded;

  /// Whether validation found one or more issues.
  bool get isValidationFailed =>
      status ==
      AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryResultStatus
          .validationFailed;

  /// Whether the result contains any validation findings.
  bool get hasIssues => validationReport.hasIssues;

  /// Number of validation findings.
  int get issueCount => validationReport.issueCount;

  /// Stable machine-readable validation codes.
  List<String> get errorCodes => validationReport.errorCodes;

  /// Human-readable validation descriptions.
  List<String> get descriptions => validationReport.descriptions;
}
