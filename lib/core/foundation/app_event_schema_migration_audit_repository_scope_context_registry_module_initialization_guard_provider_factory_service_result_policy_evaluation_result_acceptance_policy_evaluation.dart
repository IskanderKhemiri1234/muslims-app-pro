
import 'app_event_schema_migration_audit_repository_scope_context_registry_module_initialization_guard_provider_factory_service_result_policy_evaluation_result_acceptance_policy.dart';
import 'app_event_schema_migration_audit_repository_scope_context_registry_module_initialization_guard_provider_factory_service_result_policy_evaluation_result_acceptance_policy_validator.dart';

enum AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationStatus {
  acceptedAndConsistent,
  rejectedAndConsistent,
  inconsistent,
}

class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluation {
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluation._({
    required this.acceptanceReport,
    required this.validationReport,
  }) {
    _validateConsistency();
  }

  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptanceReport
      acceptanceReport;

  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyValidationReport
      validationReport;

  factory AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluation.fromReports({
    required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptanceReport
        acceptanceReport,
    required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyValidationReport
        validationReport,
  }) {
    return AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluation._(
      acceptanceReport: acceptanceReport,
      validationReport: validationReport,
    );
  }

  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationStatus
      get status {
    if (!validationReport.isValid) {
      return AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationStatus
          .inconsistent;
    }

    if (acceptanceReport.isAccepted) {
      return AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationStatus
          .acceptedAndConsistent;
    }

    return AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationStatus
        .rejectedAndConsistent;
  }

  bool get isAcceptedAndConsistent =>
      status ==
      AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationStatus
          .acceptedAndConsistent;

  bool get isRejectedAndConsistent =>
      status ==
      AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationStatus
          .rejectedAndConsistent;

  bool get isInconsistent =>
      status ==
      AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationStatus
          .inconsistent;

  bool get hasIssues =>
      acceptanceReport.hasIssues || validationReport.hasIssues;

  int get totalIssueCount =>
      acceptanceReport.issueCount + validationReport.issueCount;

  List<String> get issueCodes => List.unmodifiable([
        ...acceptanceReport.issueCodes,
        ...validationReport.issueCodes,
      ]);

  List<String> get issueDescriptions => List.unmodifiable([
        ...acceptanceReport.issueDescriptions,
        ...validationReport.issueDescriptions,
      ]);

  void _validateConsistency() {
    final expectedStatus = !validationReport.isValid
        ? AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationStatus
            .inconsistent
        : acceptanceReport.isAccepted
            ? AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationStatus
                .acceptedAndConsistent
            : AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationStatus
                .rejectedAndConsistent;

    if (status != expectedStatus) {
      throw StateError(
        'Acceptance policy evaluation status is inconsistent with its reports.',
      );
    }

    if (totalIssueCount !=
        acceptanceReport.issues.length + validationReport.issues.length) {
      throw StateError(
        'Acceptance policy evaluation issue count is inconsistent with its reports.',
      );
    }
  }

  @override
  String toString() {
    return 'AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluation('
        'status: ${status.name}, '
        'acceptanceDecision: ${acceptanceReport.decision.name}, '
        'acceptanceIssueCount: ${acceptanceReport.issueCount}, '
        'validationIssueCount: ${validationReport.issueCount}, '
        'totalIssueCount: $totalIssueCount'
        ')';
  }
}
