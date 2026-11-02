
import 'app_event_schema_migration_audit_repository_scope_context_registry_module_initialization_guard.dart';
import 'app_event_schema_migration_audit_repository_scope_context_registry_module_initialization_guard_provider.dart';

/// Describes the validation issues that may be found in a guard provider
/// configuration.
enum AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderConfigurationIssue {
  providerDisposed,
  guardDisposed,
  providerUnavailable,
  guardIdentityMismatch,
}

/// Immutable result of validating a guard provider configuration.
final class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderConfigurationReport {
  final List<
      AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderConfigurationIssue>
      issues;

  const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderConfigurationReport({
    required this.issues,
  });

  /// Whether the configuration passed all validation checks.
  bool get isValid => issues.isEmpty;

  /// Whether at least one validation issue was found.
  bool get hasIssues => issues.isNotEmpty;

  /// Number of detected validation issues.
  int get issueCount => issues.length;
}

/// Holds references to an existing initialization guard and its provider.
///
/// This configuration object does not:
/// - Create an initialization guard.
/// - Create a provider.
/// - Take ownership of either object.
/// - Request or consume initialization permits.
/// - Initialize, disable, or dispose external resources.
///
/// Its responsibility is limited to describing and validating the
/// compatibility of the supplied references.
final class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderConfiguration {
  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProvider
      provider;

  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuard
      guard;

  const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderConfiguration({
    required this.provider,
    required this.guard,
  });

  /// Validates the provider, guard, and their identity relationship.
  ///
  /// The provider must be active, the guard must not be disabled, and
  /// the provider must reference the exact guard supplied to this
  /// configuration.
  ///
  /// This method performs validation only. It does not modify either
  /// object or perform initialization.
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderConfigurationReport
      validate() {
    final issues = <
        AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderConfigurationIssue>[];

    if (provider.isDisposed) {
      issues.add(
        AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderConfigurationIssue
            .providerDisposed,
      );
    }

    if (guard.isDisposed) {
      issues.add(
        AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderConfigurationIssue
            .guardDisposed,
      );
    }

    if (!provider.isAvailable) {
      issues.add(
        AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderConfigurationIssue
            .providerUnavailable,
      );
    }

    if (!provider.isDisposed) {
      final providedGuard = provider.guard;

      if (!identical(providedGuard, guard)) {
        issues.add(
          AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderConfigurationIssue
              .guardIdentityMismatch,
        );
      }
    }

    return AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderConfigurationReport(
      issues: List<
          AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderConfigurationIssue>.unmodifiable(
        issues,
      ),
    );
  }
}
