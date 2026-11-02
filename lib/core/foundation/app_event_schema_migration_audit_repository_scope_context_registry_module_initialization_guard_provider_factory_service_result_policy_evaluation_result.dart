
import 'app_event_schema_migration_audit_repository_scope_context_registry_module_initialization_guard_provider_factory_service_result_policy_evaluation.dart';
import 'app_event_schema_migration_audit_repository_scope_context_registry_module_initialization_guard_provider_factory_service_result_policy_evaluation_validator.dart';

/// Describes the outcome of validating a policy evaluation aggregate.
enum AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultStatus {
  valid,
  invalid,
}

/// Immutable result combining a policy evaluation and its validation report.
///
/// This result describes the integrity of the evaluation data only.
/// It does not indicate that resources are initialized, available, or
/// authorized for execution.
class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResult {
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResult._({
    required this.evaluation,
    required this.validationReport,
    required this.status,
  }) {
    _validateConsistency();
  }

  /// Creates a result from an evaluation and its validation report.
  ///
  /// The status is derived from the validation report, so callers cannot
  /// independently assign a contradictory status.
  factory AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResult.fromReports({
    required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluation
        evaluation,
    required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationValidationReport
        validationReport,
  }) {
    final status = validationReport.isValid
        ? AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultStatus
            .valid
        : AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultStatus
            .invalid;

    return AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResult._(
      evaluation: evaluation,
      validationReport: validationReport,
      status: status,
    );
  }

  /// The original policy evaluation aggregate.
  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluation
      evaluation;

  /// The consistency validation report for the evaluation.
  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationValidationReport
      validationReport;

  /// The derived integrity status of the evaluation result.
  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultStatus
      status;

  /// Whether the evaluation passed its structural validation.
  ///
  /// This is not execution permission or resource readiness.
  bool get isValid =>
      status ==
      AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultStatus
          .valid;

  /// Whether the evaluation failed its structural validation.
  bool get isInvalid =>
      status ==
      AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultStatus
          .invalid;

  /// Whether the validation report contains issues.
  bool get hasIssues => validationReport.hasIssues;

  /// Number of issues reported by the evaluation validator.
  int get issueCount => validationReport.issueCount;

  /// Stable validation issue codes.
  List<String> get issueCodes => validationReport.issueCodes;

  /// Human-readable validation issue descriptions.
  List<String> get issueDescriptions =>
      validationReport.issueDescriptions;

  /// The status as a descriptive string.
  String get statusName => status.name;

  /// Ensures the result status agrees with its validation report.
  void _validateConsistency() {
    final reportIndicatesValidity = validationReport.isValid;

    final resultIndicatesValidity =
        status ==
            AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultStatus
                .valid;

    if (reportIndicatesValidity != resultIndicatesValidity) {
      throw StateError(
        'Policy evaluation result status is inconsistent with its validation report.',
      );
    }
  }

  @override
  String toString() {
    return 'AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResult('
        'status: ${status.name}, '
        'evaluationStatus: ${evaluation.status.name}, '
        'issueCount: $issueCount'
        ')';
  }
}
