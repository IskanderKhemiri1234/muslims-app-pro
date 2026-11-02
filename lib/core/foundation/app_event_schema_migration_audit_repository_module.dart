
import 'app_event_schema_migration_audit_reader.dart';
import 'app_event_schema_migration_audit_repository.dart';
import 'app_event_schema_migration_audit_repository_configuration.dart';
import 'app_event_schema_migration_audit_repository_factory.dart';
import 'app_event_schema_migration_audit_repository_provider.dart';

/// Represents the lifecycle state of the audit repository module.
enum AppEventSchemaMigrationAuditRepositoryModuleState {
  uninitialized,
  initialized,
  disposed,
}

/// Identifies module initialization failures.
enum AppEventSchemaMigrationAuditRepositoryModuleErrorCode {
  alreadyInitialized,
  notInitialized,
  alreadyDisposed,
  invalidConfiguration,
}

/// Represents an audit repository module lifecycle error.
final class AppEventSchemaMigrationAuditRepositoryModuleException
    implements Exception {
  const AppEventSchemaMigrationAuditRepositoryModuleException({
    required this.code,
    required this.message,
  });

  final AppEventSchemaMigrationAuditRepositoryModuleErrorCode code;
  final String message;

  @override
  String toString() {
    return 'AppEventSchemaMigrationAuditRepositoryModuleException'
        '(code: ${code.name}, message: $message)';
  }
}

/// Defines the public initialization contract for the audit repository
/// module.
///
/// Consumers interact with this module through its repository interface.
/// Factory, configuration, and provider details remain internal to the
/// module's initialization boundary.
abstract interface class AppEventSchemaMigrationAuditRepositoryModule {
  AppEventSchemaMigrationAuditRepository get repository;

  AppEventSchemaMigrationAuditRepositoryModuleState get state;

  bool get isInitialized;

  Future<void> initialize();

  Future<void> dispose();
}

/// Default implementation of the audit repository module.
///
/// The module coordinates configuration, factory creation, and provider
/// installation. It does not create or own the underlying audit data source
/// or reader.
final class DefaultAppEventSchemaMigrationAuditRepositoryModule
    implements AppEventSchemaMigrationAuditRepositoryModule {
  DefaultAppEventSchemaMigrationAuditRepositoryModule({
    required AppEventSchemaMigrationAuditRepositoryConfiguration
        configuration,
  }) : _configuration = configuration;

  final AppEventSchemaMigrationAuditRepositoryConfiguration
      _configuration;

  AppEventSchemaMigrationAuditRepositoryProvider? _provider;

  AppEventSchemaMigrationAuditRepositoryModuleState _state =
      AppEventSchemaMigrationAuditRepositoryModuleState.uninitialized;

  Future<void>? _initialization;

  @override
  AppEventSchemaMigrationAuditRepositoryModuleState get state => _state;

  @override
  bool get isInitialized =>
      _state ==
      AppEventSchemaMigrationAuditRepositoryModuleState.initialized;

  @override
  AppEventSchemaMigrationAuditRepository get repository {
    _ensureInitialized();
    return _provider!.repository;
  }

  /// Initializes the module exactly once.
  ///
  /// Concurrent initialization requests share the same future.
  @override
  Future<void> initialize() {
    if (_state ==
        AppEventSchemaMigrationAuditRepositoryModuleState.disposed) {
      return Future<void>.error(
        const AppEventSchemaMigrationAuditRepositoryModuleException(
          code: AppEventSchemaMigrationAuditRepositoryModuleErrorCode
              .alreadyDisposed,
          message: 'The audit repository module has been disposed.',
        ),
      );
    }

    if (isInitialized) {
      return Future<void>.value();
    }

    final pendingInitialization = _initialization;

    if (pendingInitialization != null) {
      return pendingInitialization;
    }

    final completer = _initializeInternal();
    _initialization = completer;

    return completer;
  }

  Future<void> _initializeInternal() async {
    try {
      _configuration.validate();

      final provider = _configuration.createProvider();

      _provider = provider;
      _state =
          AppEventSchemaMigrationAuditRepositoryModuleState.initialized;
    } on AppEventSchemaMigrationAuditRepositoryConfigurationException {
      rethrow;
    } catch (error) {
      throw AppEventSchemaMigrationAuditRepositoryModuleException(
        code: AppEventSchemaMigrationAuditRepositoryModuleErrorCode
            .invalidConfiguration,
        message: 'The audit repository module could not be initialized: '
            '${error.runtimeType}.',
      );
    } finally {
      _initialization = null;
    }
  }

  /// Disposes the module's provider access boundary.
  ///
  /// The underlying repository, reader, and data source are not disposed
  /// because their lifecycle is owned by the composition root.
  @override
  Future<void> dispose() async {
    if (_state ==
        AppEventSchemaMigrationAuditRepositoryModuleState.disposed) {
      return;
    }

    final pendingInitialization = _initialization;

    if (pendingInitialization != null) {
      try {
        await pendingInitialization;
      } catch (_) {
        // Initialization failure does not prevent lifecycle cleanup.
      }
    }

    _provider?.dispose();
    _provider = null;

    _state =
        AppEventSchemaMigrationAuditRepositoryModuleState.disposed;
  }

  void _ensureInitialized() {
    if (!isInitialized || _provider == null) {
      throw const AppEventSchemaMigrationAuditRepositoryModuleException(
        code: AppEventSchemaMigrationAuditRepositoryModuleErrorCode
            .notInitialized,
        message: 'The audit repository module is not initialized.',
      );
    }
  }
}

/// Provides a single construction entry point for the audit repository
/// module.
///
/// The composition root supplies the reader and selects the factory and
/// installation policy. Higher-level application modules only need the
/// resulting [AppEventSchemaMigrationAuditRepositoryModule].
final class AppEventSchemaMigrationAuditRepositoryModuleBuilder {
  const AppEventSchemaMigrationAuditRepositoryModuleBuilder();

  /// Builds a module from explicitly injected dependencies.
  AppEventSchemaMigrationAuditRepositoryModule build({
    required AppEventSchemaMigrationAuditReader reader,
    AppEventSchemaMigrationAuditRepositoryFactory factory =
        const ReaderBackedAppEventSchemaMigrationAuditRepositoryFactory(),
    AppEventSchemaMigrationAuditRepositoryInstallationMode
        installationMode =
        AppEventSchemaMigrationAuditRepositoryInstallationMode.scoped,
  }) {
    final configuration =
        AppEventSchemaMigrationAuditRepositoryConfiguration(
      factory: factory,
      reader: reader,
      installationMode: installationMode,
    );

    configuration.validate();

    return DefaultAppEventSchemaMigrationAuditRepositoryModule(
      configuration: configuration,
    );
  }
}
