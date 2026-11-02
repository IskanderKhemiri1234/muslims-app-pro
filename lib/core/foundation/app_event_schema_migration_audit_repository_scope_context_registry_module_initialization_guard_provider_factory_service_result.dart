
import 'app_event_schema_migration_audit_repository_scope_context_registry_module_initialization_guard_provider_factory_service_validator.dart';

/// Represents the outcome of validating a service configuration.
enum AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultStatus {
  validationSucceeded,
  validationFailed,
}

/// Immutable result of service configuration validation.
///
/// This result describes validation only. It does not indicate that a
/// provider was created, a guard was initialized, or any resource is ready.
class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResult {
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResult._({
    required this.status,
    required this.validationReport,
  }) {
    _validateConsistency();
  }

  /// Creates a result from a validation report.
  ///
  /// The status is derived from the report, preventing callers from
  /// constructing a success result that contains validation issues.
  factory AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResult.fromReport({
    required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceValidationReport
        validationReport,
  }) {
    final status = validationReport.isValid
        ? AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultStatus
            .validationSucceeded
        : AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultStatus
            .validationFailed;

    return AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResult._(
      status: status,
      validationReport: validationReport,
    );
  }

  /// The normalized validation outcome.
  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultStatus
      status;

  /// The report containing the underlying validation details.
  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceValidationReport
      validationReport;

  /// Whether configuration validation completed without reported issues.
  bool get isSuccessful =>
      status ==
      AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultStatus
          .validationSucceeded;

  /// Whether configuration validation reported one or more issues.
  bool get isFailure =>
      status ==
      AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultStatus
          .validationFailed;

  /// Whether the result contains validation issues.
  bool get hasIssues => validationReport.hasIssues;

  /// Number of reported validation issues.
  int get issueCount => validationReport.issueCount;

  /// Stable issue codes from the validation report.
  List<String> get issueCodes => validationReport.issueCodes;

  /// Human-readable issue descriptions.
  List<String> get issueDescriptions =>
      validationReport.issueDescriptions;

  /// The result status as a stable descriptive string.
  String get statusName => status.name;

  /// Ensures the result status agrees with its validation report.
  ///
  /// This is an internal invariant check, not a resource-readiness check.
  void _validateConsistency() {
    final reportIndicatesSuccess = validationReport.isValid;
    final resultIndicatesSuccess =
        status ==
            AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultStatus
                .validationSucceeded;

    if (reportIndicatesSuccess != resultIndicatesSuccess) {
      throw StateError(
        'Service validation result status is inconsistent with its report.',
      );
    }
  }

  @override
  String toString() {
    return 'AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResult('
        'status: ${status.name}, '
        'isSuccessful: $isSuccessful, '
        'issueCount: $issueCount'
        ')';
  }
}
