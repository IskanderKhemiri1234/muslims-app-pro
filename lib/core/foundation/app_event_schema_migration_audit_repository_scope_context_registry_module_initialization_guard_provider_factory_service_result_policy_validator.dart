
import 'app_event_schema_migration_audit_repository_scope_context_registry_module_initialization_guard_provider_factory_service_result_policy.dart';

/// Stable validation codes for policy report consistency checks.
enum AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyValidationCode {
  decisionIssuesMismatch(
    code: 'SERVICE_RESULT_POLICY_DECISION_ISSUES_MISMATCH',
    description:
        'The policy decision does not agree with the issues contained in the policy report.',
  );

  const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyValidationCode({
    required this.code,
    required this.description,
  });

  /// Stable machine-readable identifier.
  final String code;

  /// Human-readable explanation.
  final String description;
}

/// A normalized issue found during policy report validation.
class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyValidationIssue {
  const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyValidationIssue({
    required this.validationCode,
  });

  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyValidationCode
      validationCode;

  String get code => validationCode.code;

  String get description => validationCode.description;
}

/// Immutable report describing the structural validity of a policy report.
class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyValidationReport {
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyValidationReport({
    required List<
            AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyValidationIssue>
        issues,
  }) : issues = List<
            AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyValidationIssue>.unmodifiable(
          issues,
        );

  final List<
      AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyValidationIssue>
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

/// Validates the internal consistency of a service result policy report.
///
/// This validator only inspects the supplied report. It does not:
/// - Re-evaluate the service result acceptance policy.
/// - Invoke the service, executor, factory, provider, or guard.
/// - Initialize, create, or dispose resources.
/// - Grant permission to continue application execution.
///
/// The Composition Root remains responsible for all execution decisions.
class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyValidator {
  const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyValidator();

  /// Checks whether the policy decision agrees with its issue collection.
  ///
  /// A report is structurally consistent when:
  /// - `accepted` is paired with an empty issue collection.
  /// - `rejected` is paired with a non-empty issue collection.
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyValidationReport
      validate({
    required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyReport
        policyReport,
  }) {
    final decisionIndicatesAcceptance = policyReport.isAccepted;

    final issuesIndicateAcceptance = !policyReport.hasIssues;

    final issues =
        <AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyValidationIssue>[];

    if (decisionIndicatesAcceptance != issuesIndicateAcceptance) {
      issues.add(
        const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyValidationIssue(
          validationCode:
              AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyValidationCode
                  .decisionIssuesMismatch,
        ),
      );
    }

    return AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyValidationReport(
      issues: issues,
    );
  }
}
