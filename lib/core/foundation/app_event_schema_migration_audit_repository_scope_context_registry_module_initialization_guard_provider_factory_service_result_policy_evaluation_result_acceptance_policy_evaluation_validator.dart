
import 'app_event_schema_migration_audit_repository_scope_context_registry_module_initialization_guard_provider_factory_service_result_policy_evaluation_result_acceptance_policy_evaluation.dart';

enum AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationValidationIssueType {
  statusMismatch,
  acceptedStateMismatch,
  rejectedStateMismatch,
  inconsistentStateMismatch,
  issuePresenceMismatch,
  issueCountMismatch,
  issueCodesMismatch,
  issueDescriptionsMismatch,
}

enum AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationValidationCode {
  statusMismatch(
    'ACCEPTANCE_POLICY_EVALUATION_STATUS_MISMATCH',
    'The evaluation status does not match the acceptance and validation reports.',
  ),
  acceptedStateMismatch(
    'ACCEPTANCE_POLICY_EVALUATION_ACCEPTED_STATE_MISMATCH',
    'The accepted state is inconsistent with the evaluation reports.',
  ),
  rejectedStateMismatch(
    'ACCEPTANCE_POLICY_EVALUATION_REJECTED_STATE_MISMATCH',
    'The rejected state is inconsistent with the evaluation reports.',
  ),
  inconsistentStateMismatch(
    'ACCEPTANCE_POLICY_EVALUATION_INCONSISTENT_STATE_MISMATCH',
    'The inconsistent state does not match the validation report.',
  ),
  issuePresenceMismatch(
    'ACCEPTANCE_POLICY_EVALUATION_ISSUE_PRESENCE_MISMATCH',
    'The aggregate issue presence does not match its reports.',
  ),
  issueCountMismatch(
    'ACCEPTANCE_POLICY_EVALUATION_ISSUE_COUNT_MISMATCH',
    'The aggregate issue count does not match its reports.',
  ),
  issueCodesMismatch(
    'ACCEPTANCE_POLICY_EVALUATION_ISSUE_CODES_MISMATCH',
    'The aggregate issue codes do not match its reports.',
  ),
  issueDescriptionsMismatch(
    'ACCEPTANCE_POLICY_EVALUATION_ISSUE_DESCRIPTIONS_MISMATCH',
    'The aggregate issue descriptions do not match its reports.',
  );

  const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationValidationCode(
    this.code,
    this.description,
  );

  final String code;
  final String description;
}

class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationValidationIssue {
  const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationValidationIssue({
    required this.type,
    required this.code,
    required this.description,
  });

  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationValidationIssueType
      type;

  final String code;
  final String description;
}

class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationValidationReport {
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationValidationReport._({
    required List<AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationValidationIssue>
        issues,
  }) : issues = List.unmodifiable(issues);

  final List<AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationValidationIssue>
      issues;

  bool get isValid => issues.isEmpty;

  bool get hasIssues => issues.isNotEmpty;

  int get issueCount => issues.length;

  List<String> get issueCodes =>
      List.unmodifiable(issues.map((issue) => issue.code));

  List<String> get issueDescriptions =>
      List.unmodifiable(issues.map((issue) => issue.description));

  factory AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationValidationReport.fromIssues({
    required List<AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationValidationIssue>
        issues,
  }) {
    return AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationValidationReport._(
      issues: issues,
    );
  }
}

class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationValidator {
  const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationValidator();

  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationValidationReport
      validate({
    required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluation
        evaluation,
  }) {
    final issues =
        <AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationValidationIssue>[];

    void addIssue({
      required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationValidationIssueType
          type,
      required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationValidationCode
          code,
    }) {
      issues.add(
        AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationValidationIssue(
          type: type,
          code: code.code,
          description: code.description,
        ),
      );
    }

    final expectedStatus = !evaluation.validationReport.isValid
        ? AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationStatus
            .inconsistent
        : evaluation.acceptanceReport.isAccepted
            ? AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationStatus
                .acceptedAndConsistent
            : AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationStatus
                .rejectedAndConsistent;

    if (evaluation.status != expectedStatus) {
      addIssue(
        type: AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationValidationIssueType
            .statusMismatch,
        code: AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationValidationCode
            .statusMismatch,
      );
    }

    final expectedAccepted =
        expectedStatus ==
            AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationStatus
                .acceptedAndConsistent;

    if (evaluation.isAcceptedAndConsistent != expectedAccepted) {
      addIssue(
        type: AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationValidationIssueType
            .acceptedStateMismatch,
        code: AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationValidationCode
            .acceptedStateMismatch,
      );
    }

    final expectedRejected =
        expectedStatus ==
            AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationStatus
                .rejectedAndConsistent;

    if (evaluation.isRejectedAndConsistent != expectedRejected) {
      addIssue(
        type: AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationValidationIssueType
            .rejectedStateMismatch,
        code: AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationValidationCode
            .rejectedStateMismatch,
      );
    }

    final expectedInconsistent =
        expectedStatus ==
            AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationStatus
                .inconsistent;

    if (evaluation.isInconsistent != expectedInconsistent) {
      addIssue(
        type: AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationValidationIssueType
            .inconsistentStateMismatch,
        code: AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationValidationCode
            .inconsistentStateMismatch,
      );
    }

    final expectedHasIssues =
        evaluation.acceptanceReport.hasIssues ||
        evaluation.validationReport.hasIssues;

    if (evaluation.hasIssues != expectedHasIssues) {
      addIssue(
        type: AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationValidationIssueType
            .issuePresenceMismatch,
        code: AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationValidationCode
            .issuePresenceMismatch,
      );
    }

    final expectedIssueCount =
        evaluation.acceptanceReport.issueCount +
        evaluation.validationReport.issueCount;

    if (evaluation.totalIssueCount != expectedIssueCount) {
      addIssue(
        type: AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationValidationIssueType
            .issueCountMismatch,
        code: AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationValidationCode
            .issueCountMismatch,
      );
    }

    final expectedIssueCodes = [
      ...evaluation.acceptanceReport.issueCodes,
      ...evaluation.validationReport.issueCodes,
    ];

    if (!_sameOrderedValues(
      evaluation.issueCodes,
      expectedIssueCodes,
    )) {
      addIssue(
        type: AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationValidationIssueType
            .issueCodesMismatch,
        code: AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationValidationCode
            .issueCodesMismatch,
      );
    }

    final expectedIssueDescriptions = [
      ...evaluation.acceptanceReport.issueDescriptions,
      ...evaluation.validationReport.issueDescriptions,
    ];

    if (!_sameOrderedValues(
      evaluation.issueDescriptions,
      expectedIssueDescriptions,
    )) {
      addIssue(
        type: AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationValidationIssueType
            .issueDescriptionsMismatch,
        code: AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationValidationCode
            .issueDescriptionsMismatch,
      );
    }

    return AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationValidationReport.fromIssues(
      issues: issues,
    );
  }

  bool _sameOrderedValues(
    List<String> actual,
    List<String> expected,
  ) {
    if (actual.length != expected.length) {
      return false;
    }

    for (var index = 0; index < actual.length; index++) {
      if (actual[index] != expected[index]) {
        return false;
      }
    }

    return true;
  }
}
