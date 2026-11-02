
import 'app_event_schema_migration_audit_repository_scope_context_registry_lifecycle_module_configuration.dart';
import 'app_event_schema_migration_audit_repository_scope_context_registry_lifecycle_module_result.dart';
import 'app_event_schema_migration_audit_repository_scope_context_registry_lifecycle_module_validator.dart';

/// Coordinates lifecycle module validation and initialization outcome
/// reporting without performing initialization itself.
///
/// The composition root remains responsible for:
/// - Creating and retaining the module.
/// - Deciding when initialization starts.
/// - Executing the actual initialization.
/// - Managing resource ownership.
/// - Disposing externally owned resources.
class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializer {
  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleValidator
      _validator;

  const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializer({
    required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleValidator
        validator,
  }) : _validator = validator;

  /// Validates the supplied configuration and records the validation result.
  ///
  /// No initialization is performed. The returned result explicitly reports
  /// that initialization has not started.
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleResult
      prepare({
    required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleConfiguration
        configuration,
    required DateTime createdAt,
  }) {
    final validationReport = _validator.validate(configuration);

    return AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleResult
        .validationOnly(
      validationReport: validationReport,
      createdAt: createdAt,
    );
  }

  /// Records an initialization outcome reported by the composition root.
  ///
  /// This method does not inspect, initialize, or dispose the module.
  /// It only creates an immutable result from the externally reported state.
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleResult
      recordInitializationOutcome({
    required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleResult
        preparationResult,
    required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleInitializationStatus
        initializationStatus,
    required DateTime createdAt,
    String? errorCode,
    String? errorDescription,
  }) {
    if (!preparationResult.isValidationSuccessful) {
      throw StateError(
        'Initialization outcome cannot be recorded because configuration validation failed.',
      );
    }

    if (preparationResult.initializationStatus !=
        AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleInitializationStatus
            .notStarted) {
      throw StateError(
        'Initialization outcome can only be recorded from a preparation result.',
      );
    }

    return AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleResult
        .initializationOutcome(
      validationReport: preparationResult.validationReport,
      initializationStatus: initializationStatus,
      createdAt: createdAt,
      errorCode: errorCode,
      errorDescription: errorDescription,
    );
  }
}
