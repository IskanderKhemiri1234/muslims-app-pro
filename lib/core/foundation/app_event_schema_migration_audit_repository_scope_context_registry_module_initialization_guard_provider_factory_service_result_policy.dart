
import 'app_event_schema_migration_audit_repository_scope_context_registry_module_initialization_guard_provider_factory_service_result.dart';
import 'app_event_schema_migration_audit_repository_scope_context_registry_module_initialization_guard_provider_factory_service_result_validator.dart';

/// Defines the policy outcome for evaluating a service validation result.
///
/// These values describe policy evaluation only. They do not grant
/// permission to initialize resources or execute application operations.
enum AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyDecision {
  accepted,
  rejected,
}

/// Describes a policy requirement that was not satisfied.
enum AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyIssue {
  serviceValidationFailed(
    code: 'SERVICE_VALIDATION_FAILED',
    description:
        'The service configuration validation result contains reported issues.',
  ),

  resultConsistencyFailed(
    code: 'SERVICE_RESULT_CONSISTENCY_FAILED',
    description:
        'The service result failed its structural consistency validation.',
  );

  const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyIssue({
    required this.code,
    required this.description,
  });

  final String code;

  final String description;
}

/// Immutable outcome of evaluating the service result acceptance policy.
class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyReport {
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyReport({
    required this.decision,
    required List<
            AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyIssue>
        issues,
  }) : issues = List<
            AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyIssue>.unmodifiable(
          issues,
        ) {
    _validateConsistency();
  }

  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyDecision
      decision;

  final List<
      AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyIssue>
      issues;

  bool get isAccepted =>
      decision ==
      AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyDecision
          .accepted;

  bool get isRejected =>
      decision ==
      AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyDecision
          .rejected;

  bool get hasIssues => issues.isNotEmpty;

  int get issueCount => issues.length;

  List<String> get issueCodes =>
      List<String>.unmodifiable(issues.map((issue) => issue.code));

  List<String> get issueDescriptions =>
      List<String>.unmodifiable(
        issues.map((issue) => issue.description),
      );

  /// Ensures that the policy decision agrees with its issue collection.
  void _validateConsistency() {
    final decisionIndicatesAcceptance = isAccepted;

    final issuesIndicateAcceptance = issues.isEmpty;

    if (decisionIndicatesAcceptance != issuesIndicateAcceptance) {
      throw StateError(
        'The service result policy decision is inconsistent with its issues.',
      );
    }
  }
}

/// Evaluates whether a service validation result satisfies the acceptance
/// policy.
///
/// The policy is descriptive and does not authorize execution. The
/// Composition Root remains responsible for deciding whether any subsequent
/// application operation should proceed.
class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicy {
  const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicy({
    required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultValidator
        resultValidator,
  }) : _resultValidator = resultValidator;

  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultValidator
      _resultValidator;

  /// Evaluates the result against the acceptance requirements.
  ///
  /// Acceptance requires:
  /// - A successful service validation result.
  /// - A structurally consistent result according to the result validator.
  ///
  /// No service, executor, factory, provider, or guard is invoked or created.
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyReport
      evaluate({
    required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResult
        result,
  }) {
    final issues =
        <AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyIssue>[];

    if (!result.isSuccessful) {
      issues.add(
        AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyIssue
            .serviceValidationFailed,
      );
    }

    final consistencyReport = _resultValidator.validate(
      result: result,
    );

    if (!consistencyReport.isValid) {
      issues.add(
        AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyIssue
            .resultConsistencyFailed,
      );
    }

    final decision = issues.isEmpty
        ? AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyDecision
            .accepted
        : AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyDecision
            .rejected;

    return AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyReport(
      decision: decision,
      issues: issues,
    );
  }
}
