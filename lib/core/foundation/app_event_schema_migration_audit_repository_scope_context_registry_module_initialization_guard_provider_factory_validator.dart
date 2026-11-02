
import 'app_event_schema_migration_audit_repository_scope_context_registry_module_initialization_guard_provider_factory_configuration.dart';

/// Stable machine-readable codes for factory configuration validation.
enum AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryValidationCode {
  providerDisposed(
    'GUARD_PROVIDER_DISPOSED',
    'The initialization guard provider has been disabled or disposed.',
  ),
  guardDisposed(
    'GUARD_DISPOSED',
    'The initialization guard is no longer active.',
  ),
  providerUnavailable(
    'GUARD_PROVIDER_UNAVAILABLE',
    'The initialization guard provider is not available.',
  ),
  guardIdentityMismatch(
    'GUARD_PROVIDER_IDENTITY_MISMATCH',
    'The provider does not reference the guard supplied to the factory configuration.',
  );

  const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryValidationCode(
    this.value,
    this.description,
  );

  /// Stable machine-readable validation code.
  final String value;

  /// Human-readable description of the validation finding.
  final String description;
}

/// A single normalized factory configuration validation finding.
final class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryValidationIssue {
  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryValidationCode
      code;

  const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryValidationIssue({
    required this.code,
  });

  String get errorCode => code.value;

  String get description => code.description;
}

/// Immutable validation report for a factory configuration.
final class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryValidationReport {
  final List<
      AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryValidationIssue>
      issues;

  const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryValidationReport({
    required this.issues,
  });

  /// True when the configuration has no validation findings.
  bool get isValid => issues.isEmpty;

  /// True when one or more validation findings exist.
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

/// Validates initialization guard provider factory configurations.
///
/// This validator delegates compatibility checks to the configuration
/// object and translates its findings into stable validation codes.
///
/// It deliberately does not:
/// - Invoke the factory.
/// - Create providers or guards.
/// - Request or consume initialization permits.
/// - Initialize modules.
/// - Disable or dispose resources.
/// - Coordinate concurrent operations.
final class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryValidator {
  const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryValidator();

  /// Validates [configuration] and returns a normalized report.
  ///
  /// The result describes the state observed during this validation call.
  /// It does not prove that the factory created the provider, nor does it
  /// guarantee that the provider or guard will remain active afterwards.
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryValidationReport
      validate({
    required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryConfiguration
        configuration,
  }) {
    final configurationReport = configuration.validate();

    final issues = <
        AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryValidationIssue>[];

    for (final configurationIssue in configurationReport.issues) {
      final code = _mapIssue(configurationIssue);

      if (code != null) {
        issues.add(
          AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryValidationIssue(
            code: code,
          ),
        );
      }
    }

    return AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryValidationReport(
      issues: List<
          AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryValidationIssue>.unmodifiable(
        issues,
      ),
    );
  }

  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryValidationCode?
      _mapIssue(
    AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryConfigurationIssue
        issue,
  ) {
    switch (issue) {
      case AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryConfigurationIssue
            .providerDisposed:
        return AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryValidationCode
            .providerDisposed;

      case AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryConfigurationIssue
            .guardDisposed:
        return AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryValidationCode
            .guardDisposed;

      case AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryConfigurationIssue
            .providerUnavailable:
        return AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryValidationCode
            .providerUnavailable;

      case AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryConfigurationIssue
            .guardIdentityMismatch:
        return AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryValidationCode
            .guardIdentityMismatch;
    }
  }
}
