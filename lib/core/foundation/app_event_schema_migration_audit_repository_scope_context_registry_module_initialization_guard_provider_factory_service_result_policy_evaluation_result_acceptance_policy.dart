
import 'app_event_schema_migration_audit_repository_scope_context_registry_module_initialization_guard_provider_factory_service_result_policy_evaluation_result.dart';
import 'app_event_schema_migration_audit_repository_scope_context_registry_module_initialization_guard_provider_factory_service_result_policy_evaluation_result_validator.dart';

enum AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptanceDecision {
  accepted,
  rejected,
}

enum AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptanceIssueType {
  evaluationResultRejected,
  evaluationResultInconsistent,
  evaluationResultValidationFailed,
}

enum AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptanceIssueCode {
  evaluationResultRejected(
    'POLICY_EVALUATION_RESULT_REJECTED',
    'The evaluation result does not satisfy the acceptance policy.',
  ),
  evaluationResultInconsistent(
    'POLICY_EVALUATION_RESULT_INCONSISTENT',
    'The evaluation result contains internal consistency violations.',
  ),
  evaluationResultValidationFailed(
    'POLICY_EVALUATION_RESULT_VALIDATION_FAILED',
    'The evaluation result failed structural validation.',
  );

  const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptanceIssueCode(
    this.code,
    this.description,
  );

  final String code;
  final String description;
}

class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptanceIssue {
  const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptanceIssue({
    required this.type,
    required this.code,
    required this.description,
  });

  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptanceIssueType
      type;

  final String code;

  final String description;
}

class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptanceReport {
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptanceReport._({
    required this.decision,
    required List<AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptanceIssue>
        issues,
    required this.validationReport,
  }) : issues = List.unmodifiable(issues) {
    _validateDecisionConsistency();
  }

  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptanceDecision
      decision;

  final List<AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptanceIssue>
      issues;

  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultValidationReport
      validationReport;

  bool get isAccepted =>
      decision ==
      AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptanceDecision
          .accepted;

  bool get isRejected => !isAccepted;

  bool get hasIssues => issues.isNotEmpty;

  int get issueCount => issues.length;

  List<String> get issueCodes =>
      List.unmodifiable(issues.map((issue) => issue.code));

  List<String> get issueDescriptions =>
      List.unmodifiable(issues.map((issue) => issue.description));

  bool get isStructurallyValid => validationReport.isValid;

  void _validateDecisionConsistency() {
    final shouldBeAccepted = issues.isEmpty;

    if (isAccepted != shouldBeAccepted) {
      throw StateError(
        'Acceptance decision must agree with the presence of policy issues.',
      );
    }
  }
}

class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicy {
  const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicy({
    required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultValidator
        resultValidator,
  }) : _resultValidator = resultValidator;

  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultValidator
      _resultValidator;

  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptanceReport
      evaluate({
    required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResult
        result,
  }) {
    final validationReport = _resultValidator.validate(
      result: result,
    );

    final issues =
        <AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptanceIssue>[];

    void addIssue({
      required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptanceIssueType
          type,
      required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptanceIssueCode
          code,
    }) {
      issues.add(
        AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptanceIssue(
          type: type,
          code: code.code,
          description: code.description,
        ),
      );
    }

    if (result.isInvalid) {
      addIssue(
        type: AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptanceIssueType
            .evaluationResultRejected,
        code: AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptanceIssueCode
            .evaluationResultRejected,
      );
    }

    if (!validationReport.isValid) {
      addIssue(
        type: AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptanceIssueType
            .evaluationResultInconsistent,
        code: AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptanceIssueCode
            .evaluationResultInconsistent,
      );

      addIssue(
        type: AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptanceIssueType
            .evaluationResultValidationFailed,
        code: AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptanceIssueCode
            .evaluationResultValidationFailed,
      );
    }

    final decision = issues.isEmpty
        ? AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptanceDecision
            .accepted
        : AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptanceDecision
            .rejected;

    return AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptanceReport._(
      decision: decision,
      issues: issues,
      validationReport: validationReport,
    );
  }
}
