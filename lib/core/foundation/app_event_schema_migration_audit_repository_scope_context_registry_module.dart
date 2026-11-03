
import 'dart:async';

import 'app_event_schema_migration_audit_repository_scope_context_registry_configuration.dart';
import 'app_event_schema_migration_audit_repository_scope_context_registry_provider.dart';
import 'app_event_schema_migration_audit_repository_scope_context.dart';

/// Lifecycle states of the scope context registry module.
enum AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleState {
  uninitialized,
  initializing,
  initialized,
  failed,
  disposed,
}

/// Error codes emitted by the registry module.
enum AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleError {
  invalidState,
  initializationFailed,
  registryUnavailable,
  moduleDisposed,
  providerUnavailable,
}

/// Exception raised by registry module operations.
final class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleException
    implements Exception {
  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleError
      code;

  final Object? cause;

  const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleException({
    required this.code,
    this.cause,
  });

  @override
  String toString() {
    final originalCause = cause;

    if (originalCause == null) {
      return 'AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleException'
          '(code: ${code.name})';
    }

    return 'AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleException'
        '(code: ${code.name}, cause: $originalCause)';
  }
}

/// Initializes and exposes a registry access provider.
///
/// Ownership:
/// - This module owns the provider instance it creates.
/// - The configuration and registry remain externally owned.
/// - Registered providers, scopes, and repositories remain externally owned.
/// - Disposing this module never disposes the external registry.
final class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModule {
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModule({
    required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryConfiguration
        configuration,
  }) : _configuration = configuration;

  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryConfiguration
      _configuration;

  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleState
      _state =
      AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleState
          .uninitialized;

  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryProvider?
      _provider;

  Future<void>? _initializationFuture;

  Future<void>? _disposalFuture;

  bool _disposeRequested = false;

  bool _disposalSucceeded = false;

  /// Current lifecycle state.
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleState
      get state => _state;

  /// Whether initialization completed successfully.
  bool get isInitialized =>
      _state ==
      AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleState
          .initialized;

  /// Whether disposal completed successfully.
  ///
  /// A disposal request or an unsuccessful cleanup attempt does not
  /// count as successful disposal.
  bool get isDisposed =>
      _state ==
          AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleState
              .disposed &&
      _disposalSucceeded;

  /// Whether disposal has been requested.
  ///
  /// Once requested, new initialization and provider access operations
  /// are rejected immediately.
  bool get isDisposalRequested => _disposeRequested;

  /// Initializes the module.
  ///
  /// Concurrent initialization requests share the same Future.
  ///
  /// A failed initialization can be retried while disposal has not
  /// been requested.
  ///
  /// Initialization cannot restart after disposal has been requested.
  Future<void> initialize() {
    _ensureActive();

    if (isInitialized) {
      _validateInitializedResources();
      return Future<void>.value();
    }

    final pendingInitialization = _initializationFuture;

    if (pendingInitialization != null) {
      return pendingInitialization;
    }

    final completer = Completer<void>();
    final initializationFuture = completer.future;

    // Publish the Future before starting asynchronous initialization.
    _initializationFuture = initializationFuture;

    _state =
        AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleState
            .initializing;

    unawaited(_initializeInternal(completer));

    return initializationFuture;
  }

  /// Returns the initialized access provider.
  ///
  /// The provider and its registry are validated on every access.
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryProvider
      get provider {
    _ensureActive();

    if (!isInitialized) {
      throw const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleException(
        code:
            AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleError
                .providerUnavailable,
      );
    }

    final currentProvider = _provider;

    if (currentProvider == null || currentProvider.isDisposed) {
      throw const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleException(
        code:
            AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleError
                .providerUnavailable,
      );
    }

    try {
      currentProvider.registry;
    } catch (error) {
      throw AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleException(
        code:
            AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleError
                .registryUnavailable,
        cause: error,
      );
    }

    return currentProvider;
  }

  /// Provides a context through the initialized access provider.
  ///
  /// Registry-level errors are preserved by the provider.
  AppEventSchemaMigrationAuditRepositoryScopeContext provideContext({
    required String scopeId,
  }) {
    return provider.provideContext(scopeId: scopeId);
  }

  /// Disables this module and disposes its owned access provider.
  ///
  /// Concurrent disposal requests share the same Future.
  ///
  /// Pending initialization is awaited before provider cleanup.
  ///
  /// The external registry and resources reachable through it
  /// are never disposed by this module.
  ///
  /// If provider cleanup fails, the failure is propagated and a later
  /// dispose() call may retry the cleanup.
  Future<void> dispose() {
    if (_disposalSucceeded) {
      return Future<void>.value();
    }

    final pendingDisposal = _disposalFuture;

    if (pendingDisposal != null) {
      return pendingDisposal;
    }

    // Reject new initialization and provider access immediately.
    _disposeRequested = true;

    final completer = Completer<void>();
    final disposalFuture = completer.future;

    _disposalFuture = disposalFuture;

    unawaited(_disposeInternal(completer));

    return disposalFuture;
  }

  Future<void> _initializeInternal(
    Completer<void> completer,
  ) async {
    AppEventSchemaMigrationAuditRepositoryScopeContextRegistryProvider?
        createdProvider;

    try {
      _ensureActive();

      _configuration.validate();

      _ensureActive();

      createdProvider = _configuration.createProvider();

      // A disposal request may have been made while the provider
      // was being created.
      if (_disposeRequested || isDisposed) {
        throw const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleException(
          code:
              AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleError
                  .moduleDisposed,
        );
      }

      _provider = createdProvider;

      _state =
          AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleState
              .initialized;

      _completeSuccessfully(completer);
    } catch (error, stackTrace) {
      // Remove any provider that was partially or fully created.
      final providerToClean = _provider ?? createdProvider;

      _provider = null;

      try {
        providerToClean?.dispose();
      } catch (_) {
        // Preserve the original initialization failure.
        // The external registry remains externally owned.
      }

      if (!_disposeRequested && !isDisposed) {
        _state =
            AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleState
                .failed;
      }

      final failure = _createInitializationFailure(error);

      _completeWithError(
        completer,
        failure,
        stackTrace,
      );
    } finally {
      if (identical(_initializationFuture, completer.future)) {
        _initializationFuture = null;
      }
    }
  }

  Future<void> _disposeInternal(
    Completer<void> completer,
  ) async {
    try {
      // Wait for the initialization operation that was active when
      // disposal began.
      final pendingInitialization = _initializationFuture;

      if (pendingInitialization != null) {
        try {
          await pendingInitialization;
        } catch (_) {
          // Initialization failure must not prevent provider cleanup.
        }
      }

      // Initialization is now finished. No new initialization can begin
      // because _disposeRequested remains true.
      final currentProvider = _provider;

      if (currentProvider != null) {
        // Do not clear the reference before disposal succeeds.
        // If disposal throws, a subsequent dispose() can retry it.
        currentProvider.dispose();

        _provider = null;
      }

      _state =
          AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleState
              .disposed;

      _disposalSucceeded = true;

      _completeSuccessfully(completer);
    } catch (error, stackTrace) {
      // Disposal was requested, but cleanup did not complete.
      // Keep the provider reference so another dispose() call can retry.
      _state =
          AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleState
              .failed;

      if (identical(_disposalFuture, completer.future)) {
        _disposalFuture = null;
      }

      _completeWithError(
        completer,
        error,
        stackTrace,
      );
    }
  }

  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleException
      _createInitializationFailure(Object error) {
    if (error
        is AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleException) {
      if (error.code ==
          AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleError
              .moduleDisposed) {
        return error;
      }
    }

    if (_disposeRequested || isDisposed) {
      return AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleException(
        code:
            AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleError
                .moduleDisposed,
        cause: error,
      );
    }

    return AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleException(
      code:
          AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleError
              .initializationFailed,
      cause: error,
    );
  }

  void _validateInitializedResources() {
    _ensureActive();

    final currentProvider = _provider;

    if (currentProvider == null || currentProvider.isDisposed) {
      throw const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleException(
        code:
            AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleError
                .providerUnavailable,
      );
    }

    try {
      currentProvider.registry;
    } catch (error) {
      throw AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleException(
        code:
            AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleError
                .registryUnavailable,
        cause: error,
      );
    }
  }

  void _ensureActive() {
    if (_disposeRequested || isDisposed) {
      throw const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleException(
        code:
            AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleError
                .moduleDisposed,
      );
    }
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
