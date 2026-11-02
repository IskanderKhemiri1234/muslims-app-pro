
import 'app_event_schema_migration_audit_repository_scope_context_registry_module_initialization_guard_provider_factory_service_result_policy_evaluation.dart';

/// Stable issue codes for policy evaluation aggregate validation.
enum AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationValidationCode {
  evaluationStatusMismatch(
    code: 'POLICY_EVALUATION_STATUS_MISMATCH',
    description:
        'The derived evaluation status does not agree with the policy and consistency reports.',
  ),

  acceptedStateMismatch(
    code: 'POLICY_EVALUATION_ACCEPTED_STATE_MISMATCH',
    description:
        'The accepted state does not agree with the policy report.',
  ),

  rejectedStateMismatch(
    code: 'POLICY_EVALUATION_REJECTED_STATE_MISMATCH',
    description:
        'The rejected state does not agree with the policy report.',
  ),

  inconsistentStateMismatch(
    code: 'POLICY_EVALUATION_INCONSISTENT_STATE_MISMATCH',
    description:
        'The inconsistent state does not agree with the consistency report.',
  ),

  issuePresenceMismatch(
    code: 'POLICY_EVALUATION_ISSUE_PRESENCE_MISMATCH',
    description:
        'The aggregate issue state does not agree with its underlying reports.',
  ),

  issueCountMismatch(
    code: 'POLICY_EVALUATION_ISSUE_COUNT_MISMATCH',
    description:
        'The aggregate issue count does not agree with the sum of its underlying report issue counts.',
  );

  const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationValidationCode({
    required this.code,
    required this.description,
  });

  final String code;

  final String description;
}

/// A single normalized aggregate validation issue.
class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationValidationIssue {
  const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationValidationIssue({
    required this.validationCode,
  });

  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationValidationCode
      validationCode;

  String get code => validationCode.code;

  String get description => validationCode.description;
}

/// Immutable report containing aggregate consistency validation issues.
class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationValidationReport {
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationValidationReport({
    required List<
            AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationValidationIssue>
        issues,
  }) : issues = List<
            AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationValidationIssue>.unmodifiable(
          issues,
        );

  final List<
      AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationValidationIssue>
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

/// Validates the internal consistency of a policy evaluation aggregate.
///
/// This validator only reads the aggregate and its existing reports.
/// It does not reevaluate the policy, recreate reports, invoke services,
/// initialize resources, or grant execution permission.
class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationValidator {
  const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationValidator();

  /// Inspects the aggregate's derived status and report relationships.
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationValidationReport
      validate({
    required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluation
        evaluation,
  }) {
    final issues =
        <AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationValidationIssue>[];

    final policyReport = evaluation.policyReport;
    final consistencyReport = evaluation.consistencyReport;

    final expectedAccepted =
        policyReport.isAccepted && consistencyReport.isValid;

    final expectedRejected =
        policyReport.isRejected && consistencyReport.isValid;

    final expectedInconsistent = !consistencyReport.isValid;

    final actualAccepted = evaluation.isAcceptedAndConsistent;
    final actualRejected = evaluation.isRejectedAndConsistent;
    final actualInconsistent = evaluation.isInconsistent;

    if (actualAccepted != expectedAccepted ||
        actualRejected != expectedRejected ||
        actualInconsistent != expectedInconsistent) {
      issues.add(
        const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationValidationIssue(
          validationCode:
              AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationValidationCode
                  .evaluationStatusMismatch,
        ),
      );
    }

    if (actualAccepted != expectedAccepted) {
      issues.add(
        const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationValidationIssue(
          validationCode:
              AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationValidationCode
                  .acceptedStateMismatch,
        ),
      );
    }

    if (actualRejected != expectedRejected) {
      issues.add(
        const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationValidationIssue(
          validationCode:
              AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationValidationCode
                  .rejectedStateMismatch,
        ),
      );
    }

    if (actualInconsistent != expectedInconsistent) {
      issues.add(
        const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationValidationIssue(
          validationCode:
              AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationValidationCode
                  .inconsistentStateMismatch,
        ),
      );
    }

    final expectedHasIssues =
        policyReport.hasIssues || consistencyReport.hasIssues;

    if (evaluation.hasIssues != expectedHasIssues) {
      issues.add(
        const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationValidationIssue(
          validationCode:
              AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationValidationCode
                  .issuePresenceMismatch,
        ),
      );
    }

    final expectedIssueCount =
        policyReport.issueCount + consistencyReport.issueCount;

    if (evaluation.totalIssueCount != expectedIssueCount) {
      issues.add(
        const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationValidationIssue(
          validationCode:
              AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationValidationCode
                  .issueCountMismatch,
        ),
      );
    }

    return AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationValidationReport(
      issues: issues,
    );
  }
}
