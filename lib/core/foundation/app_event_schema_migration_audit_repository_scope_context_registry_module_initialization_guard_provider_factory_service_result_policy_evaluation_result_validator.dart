
import 'app_event_schema_migration_audit_repository_scope_context_registry_module_initialization_guard_provider_factory_service_result_policy_evaluation_result.dart';

enum AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultValidationIssue {
  statusReportMismatch,
  validStateMismatch,
  invalidStateMismatch,
  issuePresenceMismatch,
  issueCountMismatch,
}

enum AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultValidationCode {
  statusReportMismatch(
    'POLICY_EVALUATION_RESULT_STATUS_REPORT_MISMATCH',
    'The evaluation result status does not match its validation report.',
  ),
  validStateMismatch(
    'POLICY_EVALUATION_RESULT_VALID_STATE_MISMATCH',
    'The evaluation result valid state is inconsistent with its status.',
  ),
  invalidStateMismatch(
    'POLICY_EVALUATION_RESULT_INVALID_STATE_MISMATCH',
    'The evaluation result invalid state is inconsistent with its status.',
  ),
  issuePresenceMismatch(
    'POLICY_EVALUATION_RESULT_ISSUE_PRESENCE_MISMATCH',
    'The evaluation result issue presence is inconsistent with its validation report.',
  ),
  issueCountMismatch(
    'POLICY_EVALUATION_RESULT_ISSUE_COUNT_MISMATCH',
    'The evaluation result issue count is inconsistent with its validation report.',
  );

  const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultValidationCode(
    this.code,
    this.description,
  );

  final String code;
  final String description;
}

class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultValidationIssue {
  const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultValidationIssue({
    required this.type,
    required this.code,
    required this.description,
  });

  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultValidationIssue type;
  final String code;
  final String description;
}

class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultValidationReport {
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultValidationReport._({
    required List<AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultValidationIssue>
        issues,
  }) : issues = List.unmodifiable(issues);

  final List<AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultValidationIssue>
      issues;

  bool get isValid => issues.isEmpty;

  bool get hasIssues => issues.isNotEmpty;

  int get issueCount => issues.length;

  List<String> get issueCodes =>
      List.unmodifiable(issues.map((issue) => issue.code));

  List<String> get issueDescriptions =>
      List.unmodifiable(issues.map((issue) => issue.description));

  factory AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultValidationReport.fromIssues({
    required List<AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultValidationIssue>
        issues,
  }) {
    return AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultValidationReport._(
      issues: issues,
    );
  }
}

class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultValidator {
  const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultValidator();

  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultValidationReport
      validate({
    required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResult
        result,
  }) {
    final issues =
        <AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultValidationIssue>[];

    void addIssue({
      required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultValidationIssue
          type,
      required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultValidationCode
          code,
    }) {
      issues.add(
        AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultValidationIssue(
          type: type,
          code: code.code,
          description: code.description,
        ),
      );
    }

    final reportIsValid = result.validationReport.isValid;
    final statusIsValid =
        result.status ==
            AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultStatus
                .valid;

    if (statusIsValid != reportIsValid) {
      addIssue(
        type: AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultValidationIssue
            .statusReportMismatch,
        code: AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultValidationCode
            .statusReportMismatch,
      );
    }

    if (result.isValid != statusIsValid) {
      addIssue(
        type: AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultValidationIssue
            .validStateMismatch,
        code: AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultValidationCode
            .validStateMismatch,
      );
    }

    if (result.isInvalid == statusIsValid) {
      addIssue(
        type: AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultValidationIssue
            .invalidStateMismatch,
        code: AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultValidationCode
            .invalidStateMismatch,
      );
    }

    if (result.hasIssues != result.validationReport.hasIssues) {
      addIssue(
        type: AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultValidationIssue
            .issuePresenceMismatch,
        code: AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultValidationCode
            .issuePresenceMismatch,
      );
    }

    if (result.issueCount != result.validationReport.issueCount) {
      addIssue(
        type: AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultValidationIssue
            .issueCountMismatch,
        code: AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultValidationCode
            .issueCountMismatch,
      );
    }

    return AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultValidationReport.fromIssues(
      issues: issues,
    );
  }
}
