
import 'app_event_schema_migration_audit_repository_scope_context_registry_module.dart';

/// Describes the outcome of validating a registry-module lifecycle transition.
enum AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleStatus {
  accepted,
  rejected,
}

/// Identifies why a lifecycle transition was rejected.
enum AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleError {
  none,
  invalidTransition,
  moduleAlreadyDisposed,
}

/// Immutable result of a lifecycle transition validation.
final class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleResult {
  const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleResult({
    required this.currentState,
    required this.requestedState,
    required this.status,
    required this.error,
  });

  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleState
      currentState;

  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleState
      requestedState;

  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleStatus
      status;

  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleError
      error;

  bool get isAccepted =>
      status ==
      AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleStatus
          .accepted;

  bool get isRejected => !isAccepted;
}

/// Defines the permitted state transitions for the registry module.
///
/// This class is deliberately stateless. It does not own the module,
/// mutate its state, initialize it, or dispose any resource.
abstract final class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycle {
  /// Validates a proposed transition without changing either state.
  static AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleResult
      validateTransition({
    required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleState
        currentState,
    required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleState
        requestedState,
  }) {
    if (currentState ==
        AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleState
            .disposed) {
      return _rejected(
        currentState: currentState,
        requestedState: requestedState,
        error:
            AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleError
                .moduleAlreadyDisposed,
      );
    }

    if (currentState == requestedState) {
      return _accepted(
        currentState: currentState,
        requestedState: requestedState,
      );
    }

    final allowed = switch (currentState) {
      AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleState
            .uninitialized =>
        requestedState ==
            AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleState
                .initializing ||
            requestedState ==
                AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleState
                    .disposed,

      AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleState
            .initializing =>
        requestedState ==
            AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleState
                .initialized ||
            requestedState ==
                AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleState
                    .failed ||
            requestedState ==
                AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleState
                    .disposed,

      AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleState
            .initialized =>
        requestedState ==
            AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleState
                .disposed,

      AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleState
            .failed =>
        requestedState ==
            AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleState
                .initializing ||
            requestedState ==
                AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleState
                    .disposed,

      AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleState
            .disposed =>
        false,
    };

    if (!allowed) {
      return _rejected(
        currentState: currentState,
        requestedState: requestedState,
        error:
            AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleError
                .invalidTransition,
      );
    }

    return _accepted(
      currentState: currentState,
      requestedState: requestedState,
    );
  }

  static AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleResult
      _accepted({
    required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleState
        currentState,
    required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleState
        requestedState,
  }) {
    return AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleResult(
      currentState: currentState,
      requestedState: requestedState,
      status:
          AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleStatus
              .accepted,
      error:
          AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleError
              .none,
    );
  }

  static AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleResult
      _rejected({
    required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleState
        currentState,
    required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleState
        requestedState,
    required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleError
        error,
  }) {
    return AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleResult(
      currentState: currentState,
      requestedState: requestedState,
      status:
          AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleStatus
              .rejected,
      error: error,
    );
  }
}
