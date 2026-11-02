
import 'app_event_schema_migration_audit_repository_scope_context_registry_module_initialization_guard_provider_configuration.dart';

/// Stable validation codes for initialization guard provider configuration.
enum AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderValidationCode {
  providerDisposed(
    'INITIALIZATION_GUARD_PROVIDER_DISPOSED',
    'The initialization guard provider has been disabled or disposed.',
  ),
  guardDisposed(
    'INITIALIZATION_GUARD_DISPOSED',
    'The initialization guard is no longer active.',
  ),
  providerUnavailable(
    'INITIALIZATION_GUARD_PROVIDER_UNAVAILABLE',
    'The initialization guard provider is not available.',
  ),
  guardIdentityMismatch(
    'INITIALIZATION_GUARD_IDENTITY_MISMATCH',
    'The provider does not reference the guard supplied by the configuration.',
  );

  const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderValidationCode(
    this.value,
    this.description,
  );

  /// Stable machine-readable validation code.
  final String value;

  /// Human-readable explanation of the validation issue.
  final String description;
}

/// A single normalized validation finding.
final class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderValidationIssue {
  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderValidationCode
      code;

  const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderValidationIssue({
    required this.code,
  });

  String get errorCode => code.value;

  String get description => code.description;
}

/// Immutable result produced by the provider configuration validator.
final class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderValidationReport {
  final List<
      AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderValidationIssue>
      issues;

  const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderValidationReport({
    required this.issues,
  });

  /// True when no validation issues were detected.
  bool get isValid => issues.isEmpty;

  /// True when one or more validation issues were detected.
  bool get hasIssues => issues.isNotEmpty;

  /// Number of validation findings.
  int get issueCount => issues.length;

  /// Stable machine-readable codes in report order.
  List<String> get errorCodes => List<String>.unmodifiable(
        issues.map((issue) => issue.errorCode),
      );

  /// Human-readable descriptions in report order.
  List<String> get descriptions => List<String>.unmodifiable(
        issues.map((issue) => issue.description),
      );
}

/// Validates an initialization guard provider configuration.
///
/// This validator is deliberately stateless. It does not create providers
/// or guards, request or consume permits, initialize modules, or manage
/// resource lifecycles.
final class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderValidator {
  const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderValidator();

  /// Converts configuration validation findings into stable validation
  /// codes and descriptions.
  ///
  /// The configuration's [validate] method is the source of truth for
  /// provider and guard compatibility checks.
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderValidationReport
      validate({
    required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderConfiguration
        configuration,
  }) {
    final configurationReport = configuration.validate();

    final issues = <
        AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderValidationIssue>[];

    for (final configurationIssue in configurationReport.issues) {
      final code = _mapIssue(configurationIssue);

      if (code != null) {
        issues.add(
          AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderValidationIssue(
            code: code,
          ),
        );
      }
    }

    return AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderValidationReport(
      issues: List<
          AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderValidationIssue>.unmodifiable(
        issues,
      ),
    );
  }

  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderValidationCode?
      _mapIssue(
    AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderConfigurationIssue
        issue,
  ) {
    switch (issue) {
      case AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderConfigurationIssue
            .providerDisposed:
        return AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderValidationCode
            .providerDisposed;

      case AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderConfigurationIssue
            .guardDisposed:
        return AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderValidationCode
            .guardDisposed;

      case AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderConfigurationIssue
            .providerUnavailable:
        return AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderValidationCode
            .providerUnavailable;

      case AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderConfigurationIssue
            .guardIdentityMismatch:
        return AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderValidationCode
            .guardIdentityMismatch;
    }
  }
}
