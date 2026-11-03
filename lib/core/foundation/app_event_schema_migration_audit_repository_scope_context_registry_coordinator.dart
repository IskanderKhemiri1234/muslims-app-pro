
import 'dart:async';

import 'app_event_schema_migration_audit_repository_scope_context_registry_lifecycle_configuration.dart';
import 'app_event_schema_migration_audit_repository_scope_context_registry_lifecycle_controller.dart';
import 'app_event_schema_migration_audit_repository_scope_context_registry_lifecycle_observer.dart';
import 'app_event_schema_migration_audit_repository_scope_context_registry_lifecycle_assembly.dart';
import 'app_event_schema_migration_audit_repository_scope_context_registry_module.dart';

/// Coordinates the lifecycle of the registry module.
///
/// Responsibilities:
/// - Coalesces concurrent initialization requests.
/// - Coalesces concurrent disposal requests.
/// - Handles disposal requested during initialization.
/// - Applies lifecycle transitions through the lifecycle controller.
/// - Dispatches accepted and rejected lifecycle notifications.
/// - Disposes the owned registry module and its owned provider.
/// - Disposes the observer dispatcher after the disposed notification.
///
/// Ownership contract:
/// - This coordinator manages the registry module lifecycle.
/// - The registry module owns its provider.
/// - The coordinator owns the observer dispatcher supplied to it.
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

  bool _disposeRequested = false;
  bool _dispatcherDisposed = false;

  /// Returns the registry module managed by this coordinator.
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModule
      get registryModule => _registryModule;

  /// Returns the lifecycle assembly managed by this coordinator.
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleAssembly
      get lifecycleAssembly => _lifecycleAssembly;

  /// Returns the lifecycle controller.
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleController
      get lifecycleController => _lifecycleAssembly.controller;

  /// Returns the lifecycle configuration.
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleConfiguration
      get lifecycleConfiguration => _lifecycleAssembly.configuration;

  /// Returns the observer dispatcher.
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleObserverDispatcher
      get observerDispatcher => _observerDispatcher;

  /// Indicates whether initialization has been requested.
  bool get isInitializationRequested =>
      _initializationCompleter != null;

  /// Indicates whether initialization is currently pending.
  bool get isInitializing =>
      lifecycleController.currentState ==
      AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleState
          .initializing;

  /// Indicates whether disposal has been requested.
  bool get isDisposalRequested => _disposeRequested;

  /// Indicates whether disposal has completed successfully.
  bool get isDisposed =>
      lifecycleController.isDisposed &&
      _disposalCompleter?.isCompleted == true;

  /// Indicates whether the observer dispatcher has been disposed.
  bool get isDispatcherDisposed =>
      _dispatcherDisposed || _observerDispatcher.isDisposed;

  /// Initializes the registry module.
  ///
  /// Concurrent calls share the same Future.
  ///
  /// If disposal is requested before module initialization starts,
  /// initialization completes with a cancellation error.
  ///
  /// If disposal is requested while module initialization is running:
  /// - The module initialization operation is allowed to finish.
  /// - No initialized transition is emitted after the disposal request.
  /// - The initialization Future is always completed.
  /// - The disposal operation waits for initialization to finish.
  /// - The lifecycle then transitions to disposed.
  ///
  /// If initialization fails without a pending disposal request:
  /// - The lifecycle attempts to transition to failed.
  /// - The original initialization error is rethrown.
  Future<void> initialize() {
    if (_disposeRequested) {
      return Future<void>.error(
        StateError(
          'Cannot initialize the registry coordinator after disposal '
          'has been requested.',
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

    final completer = Completer<void>();

    // Store the completer before starting asynchronous work.
    _initializationCompleter = completer;

    _runInitialization(completer);

    return completer.future;
  }

  /// Disposes the registry module and the owned observer dispatcher.
  ///
  /// Concurrent calls share the same Future.
  ///
  /// The disposal request is recorded synchronously before asynchronous
  /// cleanup starts. This prevents new initialization requests from entering.
  ///
  /// The disposed notification is dispatched before the observer dispatcher
  /// is disposed.
  ///
  /// The external registry is never disposed by this coordinator.
  Future<void> dispose() {
    final existingCompleter = _disposalCompleter;

    if (existingCompleter != null) {
      return existingCompleter.future;
    }

    // Record the request synchronously.
    _disposeRequested = true;

    final completer = Completer<void>();

    // Store the completer before starting asynchronous cleanup.
    _disposalCompleter = completer;

    _runDisposal(completer);

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

      // An observer may synchronously request disposal while receiving
      // the initializing notification.
      if (_disposeRequested) {
        throw StateError(
          'Initialization was cancelled before module initialization began.',
        );
      }

      await _registryModule.initialize();

      // The module initialization completed successfully.
      //
      // If disposal was requested during that operation, do not emit
      // initialized. The disposal operation will perform the terminal
      // lifecycle transition.
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

      _completeSuccessfully(completer);
    } catch (error, stackTrace) {
      // Do not transition to failed when disposal has already been requested.
      // The disposal operation owns the final transition to disposed.
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

      _completeWithError(
        completer,
        error,
        stackTrace,
      );
    } finally {
      // Defensive completion guarantee.
      //
      // No execution path may leave the initialization Future pending.
      if (!completer.isCompleted) {
        if (_disposeRequested) {
          _completeWithError(
            completer,
            StateError(
              'Initialization ended without completing because disposal '
              'was requested.',
            ),
            StackTrace.current,
          );
        } else {
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
  }

  Future<void> _runDisposal(
    Completer<void> completer,
  ) async {
    Object? firstError;
    StackTrace? firstStackTrace;

    // Wait for initialization if it has already been requested.
    //
    // Initialization always completes its Future, including cancellation
    // and failure paths.
    final initializationCompleter = _initializationCompleter;

    if (initializationCompleter != null) {
      try {
        await initializationCompleter.future;
      } catch (_) {
        // Initialization failure or cancellation must not prevent cleanup.
      }
    }

    // Emit the terminal lifecycle transition before closing the dispatcher.
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
    //
    // Disposing the module disposes its owned provider without disposing
    // the external registry.
    try {
      await _registryModule.dispose();
    } catch (error, stackTrace) {
      firstError ??= error;
      firstStackTrace ??= stackTrace;
    }

    // The dispatcher must be closed even if module disposal fails.
    //
    // Its disposal failure is captured without leaving the disposal
    // Future incomplete.
    try {
      _disposeObserverDispatcher();
    } catch (error, stackTrace) {
      firstError ??= error;
      firstStackTrace ??= stackTrace;
    }

    if (firstError != null) {
      _completeWithError(
        completer,
        firstError,
        firstStackTrace ?? StackTrace.current,
      );
      return;
    }

    _completeSuccessfully(completer);
  }

  /// Dispatches a lifecycle snapshot according to the configured policy.
  ///
  /// Both accepted and rejected transitions are eligible for notification.
  /// The configuration determines which notifications are enabled.
  ///
  /// Notification failures must not interrupt lifecycle transitions
  /// or prevent resource cleanup.
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
      // The lifecycle controller remains authoritative.
      // Notification delivery is best-effort and cannot block cleanup.
    }
  }

  /// Disposes the owned dispatcher at most once.
  ///
  /// This method intentionally does not dispose observers or their
  /// external resources.
  void _disposeObserverDispatcher() {
    if (_dispatcherDisposed) {
      return;
    }

    // Mark before invoking dispose to prevent reentrant disposal.
    _dispatcherDisposed = true;

    if (_observerDispatcher.isDisposed) {
      return;
    }

    _observerDispatcher.dispose();
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
