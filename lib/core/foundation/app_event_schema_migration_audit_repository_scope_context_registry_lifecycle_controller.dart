
import 'app_event_schema_migration_audit_repository_scope_context_registry_lifecycle.dart';
import 'app_event_schema_migration_audit_repository_scope_context_registry_module.dart';

/// Immutable snapshot of a registry module lifecycle transition.
///
/// The snapshot captures:
/// - The state before the requested transition.
/// - The state after the requested transition.
/// - The validation result.
/// - The lifecycle revision at the time of the transition.
///
/// A rejected transition never changes the controller state or revision.
final class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleSnapshot {
  const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleSnapshot({
    required this.previousState,
    required this.currentState,
    required this.transitionResult,
    required this.revision,
  });

  /// Lifecycle state before the requested transition.
  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleState
      previousState;

  /// Lifecycle state after the requested transition.
  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleState
      currentState;

  /// Result returned by lifecycle transition validation.
  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleResult
      transitionResult;

  /// Revision after processing the requested transition.
  ///
  /// This value increases only when an accepted transition changes state.
  final int revision;

  /// Whether the transition changed the lifecycle state.
  bool get changed => previousState != currentState;

  /// Whether the requested transition was accepted.
  bool get isAccepted => transitionResult.isAccepted;

  /// Whether the requested transition was rejected.
  bool get isRejected => transitionResult.isRejected;
}

/// Controls lifecycle state transitions for the registry module.
///
/// Ownership contract:
/// - The controller owns only its local lifecycle state and revision.
/// - It does not own the registry module.
/// - It does not own the registry or provider.
/// - It does not create, initialize, or dispose external resources.
/// - Lifecycle notifications are handled by the lifecycle coordinator.
final class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleController {
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleController({
    AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleState
        initialState =
        AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleState
            .uninitialized,
  }) : _currentState = initialState;

  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleState
      _currentState;

  int _revision = 0;

  /// Returns the current lifecycle state.
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleState
      get currentState =>
          _currentState;

  /// Returns the number of accepted state changes.
  ///
  /// Accepted transitions to the same state do not increment this value.
  int get revision => _revision;

  /// Indicates whether the lifecycle has reached its terminal state.
  bool get isDisposed =>
      _currentState ==
      AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleState
          .disposed;

  /// Requests a lifecycle state transition.
  ///
  /// The lifecycle validator is the single authority for transition rules.
  ///
  /// If the transition is rejected:
  /// - The current state remains unchanged.
  /// - The revision remains unchanged.
  ///
  /// If the transition is accepted:
  /// - The state is updated only when the requested state differs.
  /// - The revision increases only when the state actually changes.
  ///
  /// An accepted transition to the current state returns an accepted snapshot
  /// without changing the revision.
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleSnapshot
      transitionTo({
    required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleState
        nextState,
  }) {
    final previousState = _currentState;

    final validation =
        AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycle
            .validateTransition(
      currentState: previousState,
      requestedState: nextState,
    );

    if (!validation.isAccepted) {
      return AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleSnapshot(
        previousState: previousState,
        currentState: _currentState,
        transitionResult: validation,
        revision: _revision,
      );
    }

    if (previousState != nextState) {
      _currentState = nextState;
      _revision++;
    }

    return AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleSnapshot(
      previousState: previousState,
      currentState: _currentState,
      transitionResult: validation,
      revision: _revision,
    );
  }

  /// Validates a proposed transition without applying it.
  ///
  /// This method never changes the current state or revision.
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleResult
      validateNextState({
    required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleState
        nextState,
  }) {
    return AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycle
        .validateTransition(
      currentState: _currentState,
      requestedState: nextState,
    );
  }

  /// Returns whether the requested state can be reached from the current state.
  ///
  /// This method performs validation only and does not apply the transition.
  bool canTransitionTo({
    required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleState
        nextState,
  }) {
    return validateNextState(nextState: nextState).isAccepted;
  }
}
