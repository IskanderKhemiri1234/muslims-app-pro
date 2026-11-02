
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

  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModule({
    required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryConfiguration
        configuration,
  }) : _configuration = configuration;

  /// Current lifecycle state.
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleState
      get state => _state;

  /// Whether initialization completed successfully.
  bool get isInitialized =>
      _state ==
      AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleState
          .initialized;

  /// Whether the module has been permanently disposed.
  bool get isDisposed =>
      _state ==
      AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleState
          .disposed;

  /// Whether disposal has been requested.
  ///
  /// Once disposal is requested, new initialization and provider access
  /// operations are rejected, even while pending initialization is finishing.
  bool get isDisposalRequested => _disposeRequested;

  /// Initializes the module.
  ///
  /// Concurrent initialization requests share the same future.
  /// A failed initialization may be retried while the module is active.
  ///
  /// Initialization cannot be restarted after disposal has been requested.
  Future<void> initialize() {
    _ensureNotDisposed();

    if (isInitialized) {
      _validateInitializedResources();
      return Future<void>.value();
    }

    final pendingInitialization = _initializationFuture;

    if (pendingInitialization != null) {
      return pendingInitialization;
    }

    final completer = Completer<void>();

    _initializationFuture = completer.future;

    _state =
        AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleState
            .initializing;

    unawaited(_initializeInternal(completer));

    return completer.future;
  }

  /// Returns the initialized access provider.
  ///
  /// The provider and its registry are validated on every access.
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryProvider
      get provider {
    _ensureNotDisposed();

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
  /// Errors from the provider and registry are intentionally preserved,
  /// so callers can distinguish missing providers, invalid scope identities,
  /// and other registry-level failures.
  AppEventSchemaMigrationAuditRepositoryScopeContext provideContext({
    required String scopeId,
  }) {
    return provider.provideContext(scopeId: scopeId);
  }

  /// Disables this module and its owned access provider.
  ///
  /// Concurrent disposal requests share the same future.
  ///
  /// Pending initialization is allowed to finish or fail before the owned
  /// provider is disposed.
  ///
  /// The externally managed registry and all resources reachable through it
  /// remain untouched.
  ///
  /// Once this method is called, new initialization and provider access
  /// operations are rejected immediately.
  Future<void> dispose() {
    if (isDisposed) {
      return Future<void>.value();
    }

    final pendingDisposal = _disposalFuture;

    if (pendingDisposal != null) {
      return pendingDisposal;
    }

    _disposeRequested = true;

    final completer = Completer<void>();

    _disposalFuture = completer.future;

    unawaited(_disposeInternal(completer));

    return completer.future;
  }

  Future<void> _initializeInternal(Completer<void> completer) async {
    try {
      if (_disposeRequested) {
        throw const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleException(
          code:
              AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleError
                  .moduleDisposed,
        );
      }

      _configuration.validate();

      if (_disposeRequested) {
        throw const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleException(
          code:
              AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleError
                  .moduleDisposed,
        );
      }

      final createdProvider = _configuration.createProvider();

      if (_disposeRequested || isDisposed) {
        createdProvider.dispose();

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

      if (!completer.isCompleted) {
        completer.complete();
      }
    } catch (error, stackTrace) {
      final currentProvider = _provider;

      _provider = null;

      try {
        currentProvider?.dispose();
      } catch (_) {
        // Provider cleanup is best-effort.
        // The external registry is never disposed here.
      }

      if (!_disposeRequested && !isDisposed) {
        _state =
            AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleState
                .failed;
      }

      final failure = _createInitializationFailure(error);

      if (!completer.isCompleted) {
        completer.completeError(failure, stackTrace);
      }
    } finally {
      if (identical(_initializationFuture, completer.future)) {
        _initializationFuture = null;
      }
    }
  }

  Future<void> _disposeInternal(Completer<void> completer) async {
    try {
      final pendingInitialization = _initializationFuture;

      if (pendingInitialization != null) {
        try {
          await pendingInitialization;
        } catch (_) {
          // Initialization failure does not prevent disposal.
        }
      }

      final currentProvider = _provider;

      _provider = null;

      _state =
          AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleState
              .disposed;

      try {
        currentProvider?.dispose();
      } catch (error, stackTrace) {
        if (!completer.isCompleted) {
          completer.completeError(error, stackTrace);
        }

        return;
      }

      if (!completer.isCompleted) {
        completer.complete();
      }
    } catch (error, stackTrace) {
      _provider = null;

      _state =
          AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleState
              .disposed;

      if (!completer.isCompleted) {
        completer.completeError(error, stackTrace);
      }
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
    _ensureNotDisposed();

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

  void _ensureNotDisposed() {
    if (_disposeRequested || isDisposed) {
      throw const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleException(
        code:
            AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleError
                .moduleDisposed,
      );
    }
  }
}
