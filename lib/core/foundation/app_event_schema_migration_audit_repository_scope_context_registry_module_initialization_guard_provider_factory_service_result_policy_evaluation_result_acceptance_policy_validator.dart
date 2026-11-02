
import 'app_event_schema_migration_audit_repository_scope_context_registry_module_initialization_guard_provider_factory_service_result_policy_evaluation_result_acceptance_policy.dart';

enum AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyValidationIssueType {
  decisionIssuesMismatch,
  acceptedWithInvalidValidationReport,
  rejectedWithoutIssues,
  issueCountMismatch,
  issuePresenceMismatch,
}

enum AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyValidationCode {
  decisionIssuesMismatch(
    'ACCEPTANCE_POLICY_DECISION_ISSUES_MISMATCH',
    'The acceptance decision does not match the presence of policy issues.',
  ),
  acceptedWithInvalidValidationReport(
    'ACCEPTANCE_POLICY_ACCEPTED_WITH_INVALID_VALIDATION_REPORT',
    'The acceptance report is accepted despite an invalid validation report.',
  ),
  rejectedWithoutIssues(
    'ACCEPTANCE_POLICY_REJECTED_WITHOUT_ISSUES',
    'The acceptance report is rejected but contains no policy issues.',
  ),
  issueCountMismatch(
    'ACCEPTANCE_POLICY_ISSUE_COUNT_MISMATCH',
    'The acceptance report issue count is inconsistent.',
  ),
  issuePresenceMismatch(
    'ACCEPTANCE_POLICY_ISSUE_PRESENCE_MISMATCH',
    'The acceptance report issue presence is inconsistent.',
  );

  const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyValidationCode(
    this.code,
    this.description,
  );

  final String code;
  final String description;
}

class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyValidationIssue {
  const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyValidationIssue({
    required this.type,
    required this.code,
    required this.description,
  });

  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyValidationIssueType
      type;

  final String code;

  final String description;
}

class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyValidationReport {
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyValidationReport._({
    required List<AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyValidationIssue>
        issues,
  }) : issues = List.unmodifiable(issues);

  final List<AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyValidationIssue>
      issues;

  bool get isValid => issues.isEmpty;

  bool get hasIssues => issues.isNotEmpty;

  int get issueCount => issues.length;

  List<String> get issueCodes =>
      List.unmodifiable(issues.map((issue) => issue.code));

  List<String> get issueDescriptions =>
      List.unmodifiable(issues.map((issue) => issue.description));

  factory AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyValidationReport.fromIssues({
    required List<AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyValidationIssue>
        issues,
  }) {
    return AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyValidationReport._(
      issues: issues,
    );
  }
}

class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyValidator {
  const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyValidator();

  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyValidationReport
      validate({
    required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptanceReport
        acceptanceReport,
  }) {
    final issues =
        <AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyValidationIssue>[];

    void addIssue({
      required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyValidationIssueType
          type,
      required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyValidationCode
          code,
    }) {
      issues.add(
        AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyValidationIssue(
          type: type,
          code: code.code,
          description: code.description,
        ),
      );
    }

    final hasPolicyIssues = acceptanceReport.issues.isNotEmpty;
    final isAccepted = acceptanceReport.isAccepted;
    final isRejected = acceptanceReport.isRejected;

    if (isAccepted == hasPolicyIssues) {
      addIssue(
        type: AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyValidationIssueType
            .decisionIssuesMismatch,
        code: AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyValidationCode
            .decisionIssuesMismatch,
      );
    }

    if (isAccepted && !acceptanceReport.validationReport.isValid) {
      addIssue(
        type: AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyValidationIssueType
            .acceptedWithInvalidValidationReport,
        code: AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyValidationCode
            .acceptedWithInvalidValidationReport,
      );
    }

    if (isRejected && !hasPolicyIssues) {
      addIssue(
        type: AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyValidationIssueType
            .rejectedWithoutIssues,
        code: AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyValidationCode
            .rejectedWithoutIssues,
      );
    }

    if (acceptanceReport.issueCount != acceptanceReport.issues.length) {
      addIssue(
        type: AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyValidationIssueType
            .issueCountMismatch,
        code: AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyValidationCode
            .issueCountMismatch,
      );
    }

    if (acceptanceReport.hasIssues != hasPolicyIssues) {
      addIssue(
        type: AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyValidationIssueType
            .issuePresenceMismatch,
        code: AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyValidationCode
            .issuePresenceMismatch,
      );
    }

    return AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyValidationReport.fromIssues(
      issues: issues,
    );
  }
}
