
import 'app_event_schema_migration_audit_repository.dart';

/// Provides a controlled access point for the audit repository.
///
/// The provider owns no storage implementation and performs no persistence
/// operations. Its only responsibility is exposing an injected repository
/// through a stable dependency-injection boundary.
///
/// Application services should depend on
/// [AppEventSchemaMigrationAuditRepository], not on this provider's
/// concrete storage dependencies.
final class AppEventSchemaMigrationAuditRepositoryProvider {
  AppEventSchemaMigrationAuditRepositoryProvider({
    required AppEventSchemaMigrationAuditRepository repository,
  }) : _repository = repository;

  static AppEventSchemaMigrationAuditRepositoryProvider? _globalInstance;

  final AppEventSchemaMigrationAuditRepository _repository;

  bool _disposed = false;

  /// Returns the repository managed by this provider.
  ///
  /// Access after disposal is rejected to prevent accidental use of a
  /// provider that is no longer part of the active dependency graph.
  AppEventSchemaMigrationAuditRepository get repository {
    _ensureActive();
    return _repository;
  }

  /// Indicates whether this provider has been disposed.
  bool get isDisposed => _disposed;

  /// Indicates whether a global provider has been installed.
  static bool get isInitialized => _globalInstance != null;

  /// Returns the globally installed provider.
  ///
  /// Throws when the application has not installed a provider yet.
  static AppEventSchemaMigrationAuditRepositoryProvider get instance {
    final provider = _globalInstance;

    if (provider == null) {
      throw StateError(
        'AppEventSchemaMigrationAuditRepositoryProvider '
        'has not been initialized.',
      );
    }

    provider._ensureActive();
    return provider;
  }

  /// Returns the globally installed repository.
  static AppEventSchemaMigrationAuditRepository get globalRepository {
    return instance.repository;
  }

  /// Installs a provider as the application's global access point.
  ///
  /// A second installation is rejected. This prevents accidental replacement
  /// of a dependency while application services may still be using it.
  ///
  /// The repository itself must be constructed and configured by the
  /// composition root before installation.
  static void initialize({
    required AppEventSchemaMigrationAuditRepository repository,
  }) {
    if (_globalInstance != null) {
      throw StateError(
        'AppEventSchemaMigrationAuditRepositoryProvider '
        'has already been initialized.',
      );
    }

    _globalInstance =
        AppEventSchemaMigrationAuditRepositoryProvider(
      repository: repository,
    );
  }

  /// Installs an already constructed provider as the global instance.
  ///
  /// This method is useful when the application composition root creates
  /// providers explicitly and manages their dependency graph.
  static void install(
    AppEventSchemaMigrationAuditRepositoryProvider provider,
  ) {
    provider._ensureActive();

    if (_globalInstance != null) {
      throw StateError(
        'AppEventSchemaMigrationAuditRepositoryProvider '
        'has already been initialized.',
      );
    }

    _globalInstance = provider;
  }

  /// Removes the global reference without disposing the provider.
  ///
  /// Ownership remains with the caller. This is useful when the application
  /// composition root is responsible for disposing dependencies in order.
  static AppEventSchemaMigrationAuditRepositoryProvider?
      uninstall() {
    final provider = _globalInstance;
    _globalInstance = null;
    return provider;
  }

  /// Disposes this provider's access boundary.
  ///
  /// The repository is not disposed because repository lifecycle and
  /// underlying storage lifecycle belong to the composition root.
  void dispose() {
    if (_disposed) {
      return;
    }

    _disposed = true;

    if (identical(_globalInstance, this)) {
      _globalInstance = null;
    }
  }

  /// Clears the global provider reference for isolated test environments.
  ///
  /// This does not dispose the previous provider or its repository.
  /// Tests that own the previous provider should dispose it explicitly.
  static AppEventSchemaMigrationAuditRepositoryProvider?
      resetForTesting() {
    final previous = _globalInstance;
    _globalInstance = null;
    return previous;
  }

  void _ensureActive() {
    if (_disposed) {
      throw StateError(
        'AppEventSchemaMigrationAuditRepositoryProvider '
        'has been disposed.',
      );
    }
  }
}
