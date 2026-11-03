
import 'dart:async';

import 'app_clock.dart';
import 'app_event_schema_migration_audit_repository_scope_context_registry_lifecycle_configuration.dart';
import 'app_event_schema_migration_audit_repository_scope_context_registry_lifecycle_controller.dart';
import 'app_event_schema_migration_audit_repository_scope_context_registry_lifecycle_observer.dart';
import 'app_event_schema_migration_audit_repository_scope_context_registry_lifecycle_assembly.dart';
import 'app_event_schema_migration_audit_repository_scope_context_registry_module.dart';

/// Coordinates the lifecycle of the registry module.
///
/// Responsibilities:
/// - Serialize initialization and disposal.
/// - Coalesce concurrent initialization requests.
/// - Coalesce concurrent disposal requests.
/// - Handle disposal requested while initialization is running.
/// - Apply lifecycle transitions through the lifecycle controller.
/// - Dispatch accepted and rejected lifecycle notifications.
/// - Dispose the owned registry module and its owned provider.
/// - Dispose the observer dispatcher after the disposed notification.
///
/// Ownership contract:
/// - This coordinator owns the registry module lifecycle.
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

  /// Indicates whether disposal has completed.
  bool get isDisposed =>
      lifecycleController.isDisposed &&
      _disposalCompleter?.isCompleted == true;

  /// Indicates whether the observer dispatcher has been disposed.
  bool get isDispatcherDisposed => _dispatcherDisposed;

  /// Initializes the registry module.
  ///
  /// Concurrent calls share the same Future.
  ///
  /// If disposal is requested while initialization is running:
  /// - The current initialization operation is allowed to finish.
  /// - No initialized transition is emitted after the disposal request.
  /// - The disposal operation waits for initialization to finish.
  /// - The lifecycle then transitions to disposed.
  ///
  /// If initialization fails without a pending disposal request:
  /// - The lifecycle transitions to failed.
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

    // Assign before starting the operation to protect against reentrant calls.
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

    // Assign before starting the operation to protect against reentrant calls.
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

      if (_disposeRequested) {
        return;
      }

      await _registryModule.initialize();

      // A disposal request may have arrived while the module was initializing.
      // In that case, disposal will perform the terminal transition.
      if (_disposeRequested) {
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

      completer.complete();
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

      if (!completer.isCompleted) {
        completer.completeError(error, stackTrace);
      }
    }
  }

  Future<void> _runDisposal(
    Completer<void> completer,
  ) async {
    Object? firstError;
    StackTrace? firstStackTrace;

    // Wait for any initialization operation already in progress.
    final initializationCompleter = _initializationCompleter;

    if (initializationCompleter != null) {
      try {
        await initializationCompleter.future;
      } catch (_) {
        // Initialization failure must not prevent resource cleanup.
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

    // The registry module owns its provider. Disposing the module disposes
    // that provider without disposing the external registry.
    try {
      await _registryModule.dispose();
    } catch (error, stackTrace) {
      firstError ??= error;
      firstStackTrace ??= stackTrace;
    } finally {
      // The dispatcher must remain available until after the disposed
      // notification has had an opportunity to be dispatched.
      _disposeObserverDispatcher();
    }

    if (firstError != null) {
      completer.completeError(
        firstError,
        firstStackTrace ?? StackTrace.current,
      );
      return;
    }

    completer.complete();
  }

  /// Dispatches a lifecycle snapshot according to the configured policy.
  ///
  /// Both accepted and rejected transitions are eligible for notification.
  /// The configuration determines which notifications are enabled.
  void _dispatchLifecycleSnapshot(
    AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleSnapshot
        snapshot,
  ) {
    if (_dispatcherDisposed || _observerDispatcher.isDisposed) {
      return;
    }

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
  }

  /// Disposes the owned dispatcher at most once.
  ///
  /// This method intentionally does not dispose observers or their external
  /// resources.
  void _disposeObserverDispatcher() {
    if (_dispatcherDisposed) {
      return;
    }

    _dispatcherDisposed = true;

    if (_observerDispatcher.isDisposed) {
      return;
    }

    _observerDispatcher.dispose();
  }
}
