
import 'dart:async';

import 'app_event_schema_migration_audit_repository_scope_context_registry_configuration.dart';
import 'app_event_schema_migration_audit_repository_scope_context_registry_provider.dart';

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

  /// Initializes the module.
  ///
  /// Concurrent initialization requests share the same future.
  /// A failed initialization may be retried while the module is active.
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

    _initializeInternal(completer);

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
  /// The externally managed registry and all resources reachable through it
  /// remain untouched.
  Future<void> dispose() async {
    if (isDisposed) {
      return;
    }

    final pendingInitialization = _initializationFuture;

    if (pendingInitialization != null) {
      try {
        await pendingInitialization;
      } catch (_) {
        // Initialization failure is handled by initialize().
      }
    }

    if (isDisposed) {
      return;
    }

    final currentProvider = _provider;

    _provider = null;
    _initializationFuture = null;

    currentProvider?.dispose();

    _state =
        AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleState
            .disposed;
  }

  Future<void> _initializeInternal(Completer<void> completer) async {
    try {
      _configuration.validate();

      final createdProvider = _configuration.createProvider();

      if (isDisposed) {
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

      completer.complete();
    } catch (error, stackTrace) {
      final currentProvider = _provider;

      _provider = null;
      currentProvider?.dispose();

      if (!isDisposed) {
        _state =
            AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleState
                .failed;
      }

      completer.completeError(
        AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleException(
          code:
              AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleError
                  .initializationFailed,
          cause: error,
        ),
        stackTrace,
      );
    } finally {
      if (identical(_initializationFuture, completer.future)) {
        _initializationFuture = null;
      }
    }
  }

  void _validateInitializedResources() {
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
    if (isDisposed) {
      throw const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleException(
        code:
            AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleError
                .moduleDisposed,
      );
    }
  }
}
