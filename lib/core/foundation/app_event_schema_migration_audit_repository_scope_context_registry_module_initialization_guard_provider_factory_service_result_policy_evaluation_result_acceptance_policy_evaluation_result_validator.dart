
import 'app_event_schema_migration_audit_repository_scope_context_registry_module_initialization_guard_provider_factory_service_result_policy_evaluation_result_acceptance_policy_evaluation_result.dart';

enum AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationResultValidationIssueType {
  statusReportMismatch,
  validStateMismatch,
  invalidStateMismatch,
  issuePresenceMismatch,
  issueCountMismatch,
  issueCodesMismatch,
  issueDescriptionsMismatch,
}

enum AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationResultValidationCode {
  statusReportMismatch(
    'ACCEPTANCE_EVALUATION_RESULT_STATUS_REPORT_MISMATCH',
    'The result status does not match its validation report.',
  ),
  validStateMismatch(
    'ACCEPTANCE_EVALUATION_RESULT_VALID_STATE_MISMATCH',
    'The result valid state is inconsistent with its status.',
  ),
  invalidStateMismatch(
    'ACCEPTANCE_EVALUATION_RESULT_INVALID_STATE_MISMATCH',
    'The result invalid state is inconsistent with its status.',
  ),
  issuePresenceMismatch(
    'ACCEPTANCE_EVALUATION_RESULT_ISSUE_PRESENCE_MISMATCH',
    'The result issue presence does not match its evaluation and validation reports.',
  ),
  issueCountMismatch(
    'ACCEPTANCE_EVALUATION_RESULT_ISSUE_COUNT_MISMATCH',
    'The result issue count does not match its evaluation and validation reports.',
  ),
  issueCodesMismatch(
    'ACCEPTANCE_EVALUATION_RESULT_ISSUE_CODES_MISMATCH',
    'The result issue codes do not match its source reports.',
  ),
  issueDescriptionsMismatch(
    'ACCEPTANCE_EVALUATION_RESULT_ISSUE_DESCRIPTIONS_MISMATCH',
    'The result issue descriptions do not match its source reports.',
  );

  const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationResultValidationCode(
    this.code,
    this.description,
  );

  final String code;
  final String description;
}

class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationResultValidationIssue {
  const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationResultValidationIssue({
    required this.type,
    required this.code,
    required this.description,
  });

  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationResultValidationIssueType
      type;

  final String code;
  final String description;
}

class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationResultValidationReport {
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationResultValidationReport._({
    required List<AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationResultValidationIssue>
        issues,
  }) : issues = List.unmodifiable(issues);

  final List<AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationResultValidationIssue>
      issues;

  bool get isValid => issues.isEmpty;

  bool get hasIssues => issues.isNotEmpty;

  int get issueCount => issues.length;

  List<String> get issueCodes =>
      List.unmodifiable(issues.map((issue) => issue.code));

  List<String> get issueDescriptions =>
      List.unmodifiable(issues.map((issue) => issue.description));

  factory AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationResultValidationReport.fromIssues({
    required List<AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationResultValidationIssue>
        issues,
  }) {
    return AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationResultValidationReport._(
      issues: issues,
    );
  }
}

class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationResultValidator {
  const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationResultValidator();

  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationResultValidationReport
      validate({
    required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationResult
        result,
  }) {
    final issues =
        <AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationResultValidationIssue>[];

    void addIssue({
      required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationResultValidationIssueType
          type,
      required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationResultValidationCode
          code,
    }) {
      issues.add(
        AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationResultValidationIssue(
          type: type,
          code: code.code,
          description: code.description,
        ),
      );
    }

    final reportIsValid = result.validationReport.isValid;
    final expectedStatus = reportIsValid
        ? AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationResultStatus
            .valid
        : AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationResultStatus
            .invalid;

    if (result.status != expectedStatus) {
      addIssue(
        type: AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationResultValidationIssueType
            .statusReportMismatch,
        code: AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationResultValidationCode
            .statusReportMismatch,
      );
    }

    if (result.isValid != reportIsValid) {
      addIssue(
        type: AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationResultValidationIssueType
            .validStateMismatch,
        code: AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationResultValidationCode
            .validStateMismatch,
      );
    }

    if (result.isInvalid == reportIsValid) {
      addIssue(
        type: AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationResultValidationIssueType
            .invalidStateMismatch,
        code: AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationResultValidationCode
            .invalidStateMismatch,
      );
    }

    final expectedHasIssues =
        result.evaluation.hasIssues || result.validationReport.hasIssues;

    if (result.hasIssues != expectedHasIssues) {
      addIssue(
        type: AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationResultValidationIssueType
            .issuePresenceMismatch,
        code: AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationResultValidationCode
            .issuePresenceMismatch,
      );
    }

    final expectedIssueCount =
        result.evaluation.totalIssueCount +
        result.validationReport.issueCount;

    if (result.issueCount != expectedIssueCount) {
      addIssue(
        type: AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationResultValidationIssueType
            .issueCountMismatch,
        code: AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationResultValidationCode
            .issueCountMismatch,
      );
    }

    final expectedIssueCodes = [
      ...result.evaluation.issueCodes,
      ...result.validationReport.issueCodes,
    ];

    if (!_sameOrderedValues(result.issueCodes, expectedIssueCodes)) {
      addIssue(
        type: AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationResultValidationIssueType
            .issueCodesMismatch,
        code: AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationResultValidationCode
            .issueCodesMismatch,
      );
    }

    final expectedIssueDescriptions = [
      ...result.evaluation.issueDescriptions,
      ...result.validationReport.issueDescriptions,
    ];

    if (!_sameOrderedValues(
      result.issueDescriptions,
      expectedIssueDescriptions,
    )) {
      addIssue(
        type: AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationResultValidationIssueType
            .issueDescriptionsMismatch,
        code: AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationResultValidationCode
            .issueDescriptionsMismatch,
      );
    }

    return AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationResultValidationReport.fromIssues(
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
