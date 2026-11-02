
import 'app_event_schema_migration_audit_repository_scope_context_registry_lifecycle.dart';
import 'app_event_schema_migration_audit_repository_scope_context_registry_module.dart';

/// Immutable snapshot of a registry module lifecycle transition.
final class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleSnapshot {
  const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleSnapshot({
    required this.previousState,
    required this.currentState,
    required this.transitionResult,
    required this.revision,
  });

  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleState
      previousState;

  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleState
      currentState;

  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleResult
      transitionResult;

  final int revision;

  bool get changed => previousState != currentState;

  bool get isAccepted => transitionResult.isAccepted;

  bool get isRejected => transitionResult.isRejected;
}

/// Controls lifecycle state transitions for the registry module.
///
/// The controller owns only its local lifecycle state. It does not own,
/// create, initialize, or dispose any external resource or module.
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
  int get revision => _revision;

  /// Indicates whether the lifecycle has reached its terminal state.
  bool get isDisposed =>
      _currentState ==
      AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleState
          .disposed;

  /// Requests a state transition and applies it only when valid.
  ///
  /// Rejected transitions leave the current state and revision unchanged.
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
  bool canTransitionTo({
    required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleState
        nextState,
  }) {
    return validateNextState(nextState: nextState).isAccepted;
  }
}
