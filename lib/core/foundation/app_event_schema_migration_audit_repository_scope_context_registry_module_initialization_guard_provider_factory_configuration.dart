
import 'app_event_schema_migration_audit_repository_scope_context_registry_module_initialization_guard.dart';
import 'app_event_schema_migration_audit_repository_scope_context_registry_module_initialization_guard_provider.dart';
import 'app_event_schema_migration_audit_repository_scope_context_registry_module_initialization_guard_provider_factory.dart';

/// Validation findings for the guard provider factory configuration.
enum AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryConfigurationIssue {
  providerDisposed,
  guardDisposed,
  providerUnavailable,
  guardIdentityMismatch,
}

/// Immutable validation report for the factory configuration.
final class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryConfigurationReport {
  final List<
      AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryConfigurationIssue>
      issues;

  const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryConfigurationReport({
    required this.issues,
  });

  bool get isValid => issues.isEmpty;

  bool get hasIssues => issues.isNotEmpty;

  int get issueCount => issues.length;
}

/// Describes the compatibility requirements for an existing factory,
/// provider, and initialization guard.
///
/// This configuration is descriptive and validation-only.
///
/// It does not:
/// - Invoke the factory.
/// - Create a provider or guard.
/// - Take ownership of any supplied object.
/// - Dispose or disable resources.
/// - Request or consume initialization permits.
/// - Coordinate initialization operations.
final class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryConfiguration {
  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactory
      factory;

  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProvider
      provider;

  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuard
      guard;

  const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryConfiguration({
    required this.factory,
    required this.provider,
    required this.guard,
  });

  /// Validates the supplied provider and guard references.
  ///
  /// The factory is retained as a descriptive dependency. It is deliberately
  /// not invoked because configuration validation must not create resources.
  ///
  /// The provider must be active and available, the guard must be active,
  /// and the provider must reference the exact supplied guard instance.
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryConfigurationReport
      validate() {
    final issues = <
        AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryConfigurationIssue>[];

    if (provider.isDisposed) {
      issues.add(
        AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryConfigurationIssue
            .providerDisposed,
      );
    }

    if (guard.isDisposed) {
      issues.add(
        AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryConfigurationIssue
            .guardDisposed,
      );
    }

    if (!provider.isAvailable) {
      issues.add(
        AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryConfigurationIssue
            .providerUnavailable,
      );
    }

    if (!provider.isDisposed) {
      final providedGuard = provider.guard;

      if (!identical(providedGuard, guard)) {
        issues.add(
          AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryConfigurationIssue
              .guardIdentityMismatch,
        );
      }
    }

    return AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryConfigurationReport(
      issues: List<
          AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryConfigurationIssue>.unmodifiable(
        issues,
      ),
    );
  }
}
