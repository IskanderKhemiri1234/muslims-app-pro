
import 'app_event_schema_migration_audit_repository_scope_context_registry_module_initialization_guard.dart';

/// Describes errors raised by the initialization guard provider.
enum AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderError {
  providerDisposed,
  guardDisabled,
}

/// Provides controlled access to an externally owned initialization guard.
///
/// This provider never creates, replaces, or disposes the guard.
/// The composition root remains responsible for its lifecycle.
class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProvider {
  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuard
      _guard;

  bool _isDisposed = false;

  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProvider({
    required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuard
        guard,
  }) : _guard = guard;

  /// Returns the exact guard instance supplied by the composition root.
  ///
  /// Throws when this provider has been disabled or the external guard
  /// has already been disabled.
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuard
      get guard {
    _ensureAvailable();
    return _guard;
  }

  /// Indicates whether this provider can currently expose its guard.
  bool get isAvailable => !_isDisposed && !_guard.isDisposed;

  /// Indicates whether this provider itself has been disabled.
  bool get isDisposed => _isDisposed;

  /// Executes an operation using the externally supplied guard.
  ///
  /// The operation receives the original guard instance. No copy or
  /// replacement is created, and ownership is not transferred.
  T withGuard<T>(
    T Function(
      AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuard
          guard,
    ) operation,
  ) {
    ArgumentError.checkNotNull(operation, 'operation');
    _ensureAvailable();
    return operation(_guard);
  }

  /// Disables access through this provider only.
  ///
  /// The underlying guard remains owned by the composition root and
  /// is not disabled or disposed by this operation.
  void disable() {
    _isDisposed = true;
  }

  void _ensureAvailable() {
    if (_isDisposed) {
      throw StateError(
        AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderError
            .providerDisposed
            .name,
      );
    }

    if (_guard.isDisposed) {
      throw StateError(
        AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderError
            .guardDisabled
            .name,
      );
    }
  }
}
