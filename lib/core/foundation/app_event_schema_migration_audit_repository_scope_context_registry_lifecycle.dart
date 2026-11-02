
import 'app_event_schema_migration_audit_repository_scope_context_registry_module.dart';

/// Describes the outcome of validating a registry-module lifecycle transition.
enum AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleStatus {
  accepted,
  rejected,
}

/// Identifies why a lifecycle transition was rejected.
enum AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleError {
  /// The transition was accepted and no error occurred.
  none,

  /// The requested transition is not permitted from the current state.
  invalidTransition,

  /// The module has already reached its terminal disposed state.
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

  /// State from which the transition was requested.
  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleState
      currentState;

  /// State requested by the caller.
  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleState
      requestedState;

  /// Whether the requested transition was accepted.
  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleStatus
      status;

  /// Reason for rejection, or [none] when accepted.
  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleError
      error;

  /// Whether the requested transition was accepted.
  bool get isAccepted =>
      status ==
      AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleStatus
          .accepted;

  /// Whether the requested transition was rejected.
  bool get isRejected => !isAccepted;
}

/// Defines the permitted state transitions for the registry module.
///
/// This class is deliberately stateless. It does not own the module,
/// mutate its state, initialize it, or dispose any resource.
///
/// Permitted transitions:
///
/// - uninitialized -> initializing
/// - uninitialized -> disposed
/// - initializing -> initialized
/// - initializing -> failed
/// - initializing -> disposed
/// - initialized -> disposed
/// - failed -> initializing
/// - failed -> disposed
///
/// The disposed state is terminal. No transition can leave it.
abstract final class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycle {
  /// Validates a proposed transition without changing either state.
  ///
  /// Repeating the current state is accepted for every non-disposed state.
  /// Repeating or leaving the disposed state is rejected with
  /// [moduleAlreadyDisposed].
  ///
  /// The result always describes the original current state and requested
  /// state. This method never mutates a lifecycle controller or module.
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

  /// Creates an accepted validation result.
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

  /// Creates a rejected validation result.
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
