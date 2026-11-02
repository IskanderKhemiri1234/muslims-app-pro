
import 'app_event_schema_migration_audit_repository_scope_context_registry_module_initialization_guard_provider_factory_service_result_policy.dart';
import 'app_event_schema_migration_audit_repository_scope_context_registry_module_initialization_guard_provider_factory_service_result_policy_validator.dart';

/// Describes the overall structural outcome of a policy evaluation.
///
/// This status represents evaluation and consistency only.
/// It does not represent resource readiness or execution authorization.
enum AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationStatus {
  acceptedAndConsistent,
  rejectedAndConsistent,
  inconsistent,
}

/// Immutable aggregate containing a policy report and its consistency report.
class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluation {
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluation({
    required this.policyReport,
    required this.consistencyReport,
  }) {
    _validateConsistency();
  }

  /// Original acceptance-policy evaluation report.
  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyReport
      policyReport;

  /// Structural consistency report for the policy evaluation.
  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyValidationReport
      consistencyReport;

  /// Overall evaluation status derived from both reports.
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationStatus
      get status {
    if (!consistencyReport.isValid) {
      return AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationStatus
          .inconsistent;
    }

    if (policyReport.isAccepted) {
      return AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationStatus
          .acceptedAndConsistent;
    }

    return AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationStatus
        .rejectedAndConsistent;
  }

  /// Whether the policy accepted the result and its report is consistent.
  ///
  /// This is descriptive information, not permission to execute operations.
  bool get isAcceptedAndConsistent =>
      status ==
      AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationStatus
          .acceptedAndConsistent;

  /// Whether the policy rejected the result and its report is consistent.
  bool get isRejectedAndConsistent =>
      status ==
      AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationStatus
          .rejectedAndConsistent;

  /// Whether the policy report failed its structural consistency check.
  bool get isInconsistent =>
      status ==
      AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationStatus
          .inconsistent;

  /// Whether the aggregate contains any policy or consistency issues.
  bool get hasIssues =>
      policyReport.hasIssues || consistencyReport.hasIssues;

  /// Total number of issues across both reports.
  int get totalIssueCount =>
      policyReport.issueCount + consistencyReport.issueCount;

  /// Stable issue codes from both reports.
  ///
  /// The returned list is immutable.
  List<String> get issueCodes => List<String>.unmodifiable([
        ...policyReport.issueCodes,
        ...consistencyReport.issueCodes,
      ]);

  /// Human-readable descriptions from both reports.
  ///
  /// The returned list is immutable.
  List<String> get issueDescriptions => List<String>.unmodifiable([
        ...policyReport.issueDescriptions,
        ...consistencyReport.issueDescriptions,
      ]);

  /// Ensures the aggregate contains internally consistent report objects.
  ///
  /// The policy report and consistency report remain independently owned
  /// by their respective immutable report types.
  void _validateConsistency() {
    if (consistencyReport.isValid &&
        policyReport.isAccepted == policyReport.hasIssues) {
      throw StateError(
        'The policy evaluation reports an invalid accepted/rejected state.',
      );
    }
  }

  @override
  String toString() {
    return 'AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluation('
        'status: ${status.name}, '
        'policyAccepted: ${policyReport.isAccepted}, '
        'consistencyValid: ${consistencyReport.isValid}, '
        'totalIssueCount: $totalIssueCount'
        ')';
  }
}
