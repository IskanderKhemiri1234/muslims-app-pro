
import 'app_event_schema_migration_audit_repository_scope_context_registry_lifecycle_module_result.dart';

/// Describes the lifecycle state observed before initialization is requested.
enum AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleObservedState {
  uninitialized,
  initializing,
  initialized,
  failed,
  disposed,
  unknown,
}

/// Describes why initialization is allowed or rejected.
enum AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationPolicyCode {
  allowed,
  validationFailed,
  initializationAlreadyInProgress,
  alreadyInitialized,
  previousInitializationNotResolved,
  moduleDisposed,
  invalidObservedState,
  invalidPreparationResult,
}

/// Immutable decision returned by the initialization policy.
class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationDecision {
  final bool isAllowed;

  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationPolicyCode
      code;

  final String description;

  const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationDecision({
    required this.isAllowed,
    required this.code,
    required this.description,
  });

  bool get isRejected => !isAllowed;
}

/// Defines whether a lifecycle module may begin initialization.
///
/// This policy is a pure decision component. It does not initialize,
/// mutate, own, or dispose any resource.
class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationPolicy {
  const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationPolicy();

  /// Evaluates whether initialization may begin.
  ///
  /// A successful preparation result is mandatory. The observed module state
  /// must also be uninitialized or failed. A failed state is retryable only
  /// after the composition root has resolved the previous attempt.
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationDecision
      evaluate({
    required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleResult
        preparationResult,
    required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleObservedState
        observedState,
    bool previousFailureResolved = false,
  }) {
    if (!preparationResult.isValidationSuccessful ||
        preparationResult.initializationStatus !=
            AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleInitializationStatus
                .notStarted) {
      return _reject(
        AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationPolicyCode
            .invalidPreparationResult,
        'Initialization requires a successful preparation result that has not started initialization.',
      );
    }

    switch (observedState) {
      case AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleObservedState
            .uninitialized:
        return _allow();

      case AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleObservedState
            .initializing:
        return _reject(
          AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationPolicyCode
              .initializationAlreadyInProgress,
          'Initialization is already in progress.',
        );

      case AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleObservedState
            .initialized:
        return _reject(
          AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationPolicyCode
              .alreadyInitialized,
          'The module has already been initialized.',
        );

      case AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleObservedState
            .failed:
        if (previousFailureResolved) {
          return _allow();
        }

        return _reject(
          AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationPolicyCode
              .previousInitializationNotResolved,
          'The previous initialization failure must be resolved before retrying.',
        );

      case AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleObservedState
            .disposed:
        return _reject(
          AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationPolicyCode
              .moduleDisposed,
          'A disposed module cannot be initialized.',
        );

      case AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleObservedState
            .unknown:
        return _reject(
          AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationPolicyCode
              .invalidObservedState,
          'The observed module state is unknown.',
        );
    }
  }

  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationDecision
      _allow() {
    return const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationDecision(
      isAllowed: true,
      code: AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationPolicyCode
          .allowed,
      description: 'Initialization is permitted by the configured policy.',
    );
  }

  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationDecision
      _reject(
    AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationPolicyCode
        code,
    String description,
  ) {
    return AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationDecision(
      isAllowed: false,
      code: code,
      description: description,
    );
  }
}
