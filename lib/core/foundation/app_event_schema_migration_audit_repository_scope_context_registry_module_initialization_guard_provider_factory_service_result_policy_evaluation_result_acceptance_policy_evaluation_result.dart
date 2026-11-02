
import 'app_event_schema_migration_audit_repository_scope_context_registry_module_initialization_guard_provider_factory_service_result_policy_evaluation_result_acceptance_policy_evaluation.dart';
import 'app_event_schema_migration_audit_repository_scope_context_registry_module_initialization_guard_provider_factory_service_result_policy_evaluation_result_acceptance_policy_evaluation_validator.dart';

enum AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationResultStatus {
  valid,
  invalid,
}

class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationResult {
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationResult._({
    required this.evaluation,
    required this.validationReport,
  }) {
    _validateConsistency();
  }

  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluation evaluation;

  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationValidationReport validationReport;

  factory AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationResult.fromReports({
    required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluation evaluation,
    required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationValidationReport validationReport,
  }) {
    return AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationResult._(
      evaluation: evaluation,
      validationReport: validationReport,
    );
  }

  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationResultStatus
      get status {
    return validationReport.isValid
        ? AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationResultStatus.valid
        : AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationResultStatus.invalid;
  }

  bool get isValid =>
      status ==
      AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationResultStatus.valid;

  bool get isInvalid => !isValid;

  bool get hasIssues =>
      evaluation.hasIssues || validationReport.hasIssues;

  int get issueCount =>
      evaluation.totalIssueCount + validationReport.issueCount;

  List<String> get issueCodes => List.unmodifiable([
        ...evaluation.issueCodes,
        ...validationReport.issueCodes,
      ]);

  List<String> get issueDescriptions => List.unmodifiable([
        ...evaluation.issueDescriptions,
        ...validationReport.issueDescriptions,
      ]);

  String get statusName => status.name;

  void _validateConsistency() {
    if (isValid != validationReport.isValid) {
      throw StateError(
        'Acceptance policy evaluation result status does not match its validation report.',
      );
    }

    if (isInvalid == validationReport.isValid) {
      throw StateError(
        'Acceptance policy evaluation result invalid state does not match its validation report.',
      );
    }

    if (hasIssues !=
        (evaluation.hasIssues || validationReport.hasIssues)) {
      throw StateError(
        'Acceptance policy evaluation result issue presence is inconsistent.',
      );
    }

    if (issueCount !=
        evaluation.totalIssueCount + validationReport.issueCount) {
      throw StateError(
        'Acceptance policy evaluation result issue count is inconsistent.',
      );
    }
  }

  @override
  String toString() {
    return 'AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationResult('
        'status: $statusName, '
        'isValid: $isValid, '
        'evaluationStatus: ${evaluation.status.name}, '
        'evaluationIssueCount: ${evaluation.totalIssueCount}, '
        'validationIssueCount: ${validationReport.issueCount}, '
        'totalIssueCount: $issueCount'
        ')';
  }
}
