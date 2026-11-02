
import 'app_event_schema_migration_audit_repository_scope_context_registry_lifecycle_module_validator.dart';

/// Describes the actual initialization state reported by the composition root.
///
/// Validation and initialization are deliberately independent:
/// a valid configuration does not imply that initialization has occurred.
enum AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleInitializationStatus {
  notStarted,
  inProgress,
  succeeded,
  failed,
}

/// Describes the overall outcome of preparing the lifecycle module.
enum AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleResultStatus {
  validationFailed,
  validationSucceeded,
  initializationInProgress,
  initializationSucceeded,
  initializationFailed,
}

/// Immutable result of lifecycle module validation and preparation.
///
/// This class records outcomes only. It never initializes, mutates, or
/// disposes the module or any external dependency.
class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleResult {
  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleValidationReport
      validationReport;

  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleInitializationStatus
      initializationStatus;

  final String? initializationErrorCode;

  final String? initializationErrorDescription;

  final DateTime createdAt;

  const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleResult({
    required this.validationReport,
    required this.initializationStatus,
    required this.createdAt,
    this.initializationErrorCode,
    this.initializationErrorDescription,
  });

  /// Whether configuration validation succeeded.
  bool get isValidationSuccessful => validationReport.isValid;

  /// Whether initialization has actually succeeded.
  bool get isInitializationSuccessful =>
      initializationStatus ==
      AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleInitializationStatus
          .succeeded;

  /// Whether initialization has failed.
  bool get hasInitializationFailed =>
      initializationStatus ==
      AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleInitializationStatus
          .failed;

  /// Whether initialization has not yet been started.
  bool get initializationNotStarted =>
      initializationStatus ==
      AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleInitializationStatus
          .notStarted;

  /// Whether initialization is currently in progress.
  bool get isInitializationInProgress =>
      initializationStatus ==
      AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleInitializationStatus
          .inProgress;

  /// Whether validation and initialization have both succeeded.
  bool get isFullySuccessful =>
      isValidationSuccessful && isInitializationSuccessful;

  /// Computes the overall result status from the recorded states.
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleResultStatus
      get status {
    if (!isValidationSuccessful) {
      return AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleResultStatus
          .validationFailed;
    }

    switch (initializationStatus) {
      case AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleInitializationStatus
            .notStarted:
        return AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleResultStatus
            .validationSucceeded;

      case AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleInitializationStatus
            .inProgress:
        return AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleResultStatus
            .initializationInProgress;

      case AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleInitializationStatus
            .succeeded:
        return AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleResultStatus
            .initializationSucceeded;

      case AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleInitializationStatus
            .failed:
        return AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleResultStatus
            .initializationFailed;
    }
  }

  /// Creates a result representing validation without initialization.
  ///
  /// The composition root may use this immediately after validation.
  factory AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleResult
      validationOnly({
    required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleValidationReport
        validationReport,
    required DateTime createdAt,
  }) {
    return AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleResult(
      validationReport: validationReport,
      initializationStatus:
          AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleInitializationStatus
              .notStarted,
      createdAt: createdAt,
    );
  }

  /// Creates a result after the composition root reports initialization.
  ///
  /// This factory records the supplied outcome and performs no initialization.
  factory AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleResult
      initializationOutcome({
    required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleValidationReport
        validationReport,
    required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleInitializationStatus
        initializationStatus,
    required DateTime createdAt,
    String? errorCode,
    String? errorDescription,
  }) {
    if (initializationStatus ==
        AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleInitializationStatus
            .notStarted) {
      throw ArgumentError.value(
        initializationStatus,
        'initializationStatus',
        'Use validationOnly when initialization has not started.',
      );
    }

    if (initializationStatus ==
            AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleInitializationStatus
                .failed &&
        (errorCode == null || errorCode.trim().isEmpty)) {
      throw ArgumentError.value(
        errorCode,
        'errorCode',
        'A non-empty error code is required when initialization fails.',
      );
    }

    if (initializationStatus !=
            AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleInitializationStatus
                .failed &&
        (errorCode != null || errorDescription != null)) {
      throw ArgumentError(
        'Initialization error details are only valid for a failed outcome.',
      );
    }

    return AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleResult(
      validationReport: validationReport,
      initializationStatus: initializationStatus,
      createdAt: createdAt,
      initializationErrorCode: errorCode?.trim(),
      initializationErrorDescription: errorDescription?.trim(),
    );
  }
}
