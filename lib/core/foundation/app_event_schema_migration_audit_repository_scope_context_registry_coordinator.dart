
import 'dart:async';

import 'app_event_schema_migration_audit_repository_scope_context_registry_lifecycle_configuration.dart';
import 'app_event_schema_migration_audit_repository_scope_context_registry_lifecycle_controller.dart';
import 'app_event_schema_migration_audit_repository_scope_context_registry_lifecycle_observer.dart';
import 'app_event_schema_migration_audit_repository_scope_context_registry_lifecycle_assembly.dart';
import 'app_event_schema_migration_audit_repository_scope_context_registry_module.dart';

/// Coordinates the lifecycle of the Scope Context Registry module.
///
/// Responsibilities:
/// - Coalesces concurrent initialization requests.
/// - Allows a new initialization attempt after a failed attempt.
/// - Coalesces concurrent disposal requests.
/// - Allows a new disposal attempt after a failed attempt.
/// - Handles disposal requested during initialization.
/// - Applies lifecycle transitions through the lifecycle controller.
/// - Dispatches accepted and rejected lifecycle notifications.
/// - Disposes the registry module and its owned provider.
/// - Disposes the owned observer dispatcher after the terminal notification.
///
/// Ownership contract:
/// - The coordinator manages the registry module lifecycle.
/// - The registry module owns its provider.
/// - The coordinator owns the supplied observer dispatcher.
/// - The coordinator does not own or dispose the external registry.
/// - The coordinator does not own or dispose the AppClock.
/// - The coordinator does not own observers or observer error handlers.
/// - The coordinator does not own scopes or repositories.
final class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryCoordinator {
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryCoordinator({
    required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModule
        registryModule,
    required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleAssembly
        lifecycleAssembly,
    required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleObserverDispatcher
        observerDispatcher,
  })  : _registryModule = registryModule,
        _lifecycleAssembly = lifecycleAssembly,
        _observerDispatcher = observerDispatcher;

  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModule
      _registryModule;

  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleAssembly
      _lifecycleAssembly;

  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleObserverDispatcher
      _observerDispatcher;

  Completer<void>? _initializationCompleter;
  Completer<void>? _disposalCompleter;

  bool _initializationWasRequested = false;
  bool _initializationSucceeded = false;
  bool _disposeRequested = false;
  bool _dispatcherDisposed = false;
  bool _disposalSucceeded = false;

  /// The registry module managed by this coordinator.
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModule
      get registryModule => _registryModule;

  /// The lifecycle assembly managed by this coordinator.
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleAssembly
      get lifecycleAssembly => _lifecycleAssembly;

  /// The lifecycle controller responsible for state transitions.
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleController
      get lifecycleController => _lifecycleAssembly.controller;

  /// The lifecycle configuration used for notifications.
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleConfiguration
      get lifecycleConfiguration => _lifecycleAssembly.configuration;

  /// The observer dispatcher managed by this coordinator.
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleObserverDispatcher
      get observerDispatcher => _observerDispatcher;

  /// Whether initialization has ever been requested.
  bool get isInitializationRequested => _initializationWasRequested;

  /// Whether initialization is currently pending.
  bool get isInitializing =>
      lifecycleController.currentState ==
      AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleState
          .initializing;

  /// Whether disposal has been requested.
  bool get isDisposalRequested => _disposeRequested;

  /// Whether disposal completed successfully.
  ///
  /// A terminal controller state alone is not sufficient:
  /// module and dispatcher cleanup must also have completed successfully.
  bool get isDisposed =>
      lifecycleController.isDisposed && _disposalSucceeded;

  /// Whether the observer dispatcher has been disposed.
  bool get isDispatcherDisposed =>
      _dispatcherDisposed || _observerDispatcher.isDisposed;

  /// Initializes the registry module.
  ///
  /// Concurrent calls during the same attempt share one Future.
  ///
  /// A failed initialization can be retried while disposal has not
  /// been requested and the lifecycle controller permits the transition.
  ///
  /// If disposal is requested during initialization:
  /// - The active module initialization is allowed to finish.
  /// - No initialized transition is emitted after the disposal request.
  /// - The initialization Future is completed.
  /// - Disposal waits for initialization to finish.
  Future<void> initialize() {
    if (_disposeRequested) {
      return Future<void>.error(
        StateError(
          'Cannot initialize after disposal has been requested.',
        ),
      );
    }

    final existingCompleter = _initializationCompleter;

    if (existingCompleter != null) {
      return existingCompleter.future;
    }

    if (lifecycleController.isDisposed) {
      return Future<void>.error(
        StateError(
          'Cannot initialize a coordinator whose lifecycle is disposed.',
        ),
      );
    }

    if (_initializationSucceeded) {
      return Future<void>.value();
    }

    final completer = Completer<void>();

    _initializationWasRequested = true;
    _initializationCompleter = completer;

    // The method catches and completes all operational errors internally.
    unawaited(_runInitialization(completer));

    return completer.future;
  }

  /// Disposes the registry module and the owned observer dispatcher.
  ///
  /// Concurrent calls during one attempt share the same Future.
  ///
  /// If an attempt fails, a later call can start a new attempt.
  ///
  /// The disposal request is recorded synchronously before cleanup starts.
  /// The external registry is never disposed by this coordinator.
  Future<void> dispose() {
    if (_disposalSucceeded) {
      return Future<void>.value();
    }

    final existingCompleter = _disposalCompleter;

    if (existingCompleter != null) {
      return existingCompleter.future;
    }

    _disposeRequested = true;

    final completer = Completer<void>();
    _disposalCompleter = completer;

    unawaited(_runDisposal(completer));

    return completer.future;
  }

  Future<void> _runInitialization(
    Completer<void> completer,
  ) async {
    try {
      if (_disposeRequested) {
        throw StateError(
          'Initialization was cancelled because disposal was requested.',
        );
      }

      final initializingSnapshot = lifecycleController.transitionTo(
        nextState:
            AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleState
                .initializing,
      );

      _dispatchLifecycleSnapshot(initializingSnapshot);

      if (!initializingSnapshot.isAccepted) {
        throw StateError(
          'The lifecycle controller rejected the initializing transition.',
        );
      }

      // An observer can synchronously request disposal while handling
      // the initializing notification.
      if (_disposeRequested) {
        throw StateError(
          'Initialization was cancelled before module initialization began.',
        );
      }

      await _registryModule.initialize();

      // The module has finished initializing, but disposal may have
      // been requested while its asynchronous initialization was running.
      if (_disposeRequested) {
        _completeSuccessfully(completer);
        return;
      }

      final initializedSnapshot = lifecycleController.transitionTo(
        nextState:
            AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleState
                .initialized,
      );

      _dispatchLifecycleSnapshot(initializedSnapshot);

      if (!initializedSnapshot.isAccepted) {
        throw StateError(
          'The lifecycle controller rejected the initialized transition.',
        );
      }

      _initializationSucceeded = true;
      _completeSuccessfully(completer);
    } catch (error, stackTrace) {
      // Do not emit a failed transition after disposal was requested.
      if (!_disposeRequested &&
          lifecycleController.currentState ==
              AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleState
                  .initializing) {
        try {
          final failedSnapshot = lifecycleController.transitionTo(
            nextState:
                AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleState
                    .failed,
          );

          _dispatchLifecycleSnapshot(failedSnapshot);
        } catch (_) {
          // Preserve the original initialization error.
        }
      }

      // Permit a later retry only if disposal has not been requested.
      //
      // Existing callers retain the Future they already received.
      // A later caller can create a new initialization attempt.
      if (!_disposeRequested &&
          identical(_initializationCompleter, completer)) {
        _initializationCompleter = null;
      }

      _completeWithError(
        completer,
        error,
        stackTrace,
      );
    } finally {
      // Defensive completion guarantee.
      if (!completer.isCompleted) {
        _completeWithError(
          completer,
          StateError(
            'Initialization ended without a completion result.',
          ),
          StackTrace.current,
        );
      }
    }
  }

  Future<void> _runDisposal(
    Completer<void> completer,
  ) async {
    Object? firstError;
    StackTrace? firstStackTrace;

    // Wait for an active initialization attempt before disposing
    // the module that owns the provider.
    final initializationCompleter = _initializationCompleter;

    if (initializationCompleter != null) {
      try {
        await initializationCompleter.future;
      } catch (_) {
        // Initialization failure must not prevent resource cleanup.
      }
    }

    // Emit the terminal transition before disposing the dispatcher.
    //
    // If the transition was already accepted during an earlier
    // disposal attempt, do not emit it again.
    try {
      if (!lifecycleController.isDisposed) {
        final disposedSnapshot = lifecycleController.transitionTo(
          nextState:
              AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleState
                  .disposed,
        );

        _dispatchLifecycleSnapshot(disposedSnapshot);

        if (!disposedSnapshot.isAccepted) {
          throw StateError(
            'The lifecycle controller rejected the disposed transition.',
          );
        }
      }
    } catch (error, stackTrace) {
      firstError ??= error;
      firstStackTrace ??= stackTrace;
    }

    // The registry module owns its provider.
    // Its disposal must not dispose the external registry.
    //
    // The module is responsible for retaining its cleanup state
    // when disposal fails, allowing this call to be retried safely.
    try {
      await _registryModule.dispose();
    } catch (error, stackTrace) {
      firstError ??= error;
      firstStackTrace ??= stackTrace;
    }

    // Always attempt dispatcher disposal, even if module cleanup failed.
    //
    // A successful dispatcher disposal is remembered. A failed disposal
    // remains eligible for another attempt.
    try {
      _disposeObserverDispatcher();
    } catch (error, stackTrace) {
      firstError ??= error;
      firstStackTrace ??= stackTrace;
    }

    if (firstError != null) {
      _completeDisposalAttemptWithError(
        completer,
        firstError,
        firstStackTrace ?? StackTrace.current,
      );
      return;
    }

    _disposalSucceeded = true;
    _completeSuccessfully(completer);
  }

  /// Dispatches a lifecycle snapshot according to the configured policy.
  ///
  /// Notification delivery is best-effort and must never interrupt
  /// lifecycle transitions or resource cleanup.
  void _dispatchLifecycleSnapshot(
    AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleSnapshot
        snapshot,
  ) {
    if (_dispatcherDisposed || _observerDispatcher.isDisposed) {
      return;
    }

    try {
      final configuration = lifecycleConfiguration;

      if (!configuration.shouldNotify(
        transitionAccepted: snapshot.isAccepted,
      )) {
        return;
      }

      final notification =
          AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleNotification(
        type: snapshot.isAccepted
            ? AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleNotificationType
                .transitionAccepted
            : AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleNotificationType
                .transitionRejected,
        snapshot: snapshot,
        occurredAt: configuration.clock.now,
      );

      _observerDispatcher.dispatch(notification);
    } catch (_) {
      // Observer and notification failures must not control lifecycle state.
    }
  }

  /// Disposes the owned dispatcher.
  ///
  /// The flag is updated only after disposal has succeeded or the
  /// dispatcher reports that it is already disposed.
  ///
  /// This does not dispose observers or their external resources.
  void _disposeObserverDispatcher() {
    if (_dispatcherDisposed) {
      return;
    }

    if (_observerDispatcher.isDisposed) {
      _dispatcherDisposed = true;
      return;
    }

    _observerDispatcher.dispose();

    _dispatcherDisposed = _observerDispatcher.isDisposed;
  }

  /// Releases the current failed disposal attempt so a later call
  /// to dispose() can create a fresh attempt.
  ///
  /// The identity check prevents an older attempt from clearing
  /// a newer attempt's completer.
  void _completeDisposalAttemptWithError(
    Completer<void> completer,
    Object error,
    StackTrace stackTrace,
  ) {
    if (identical(_disposalCompleter, completer)) {
      _disposalCompleter = null;
    }

    _completeWithError(
      completer,
      error,
      stackTrace,
    );
  }

  void _completeSuccessfully(
    Completer<void> completer,
  ) {
    if (!completer.isCompleted) {
      completer.complete();
    }
  }

  void _completeWithError(
    Completer<void> completer,
    Object error,
    StackTrace stackTrace,
  ) {
    if (!completer.isCompleted) {
      completer.completeError(
        error,
        stackTrace,
      );
    }
  }
}
