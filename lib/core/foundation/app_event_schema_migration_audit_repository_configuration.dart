
import 'app_event_schema_migration_audit_reader.dart';
import 'app_event_schema_migration_audit_repository.dart';
import 'app_event_schema_migration_audit_repository_factory.dart';
import 'app_event_schema_migration_audit_repository_provider.dart';

/// Controls how the audit repository is installed in the application.
enum AppEventSchemaMigrationAuditRepositoryInstallationMode {
  /// Creates a provider without installing it globally.
  scoped,

  /// Installs the provider as the application's global access point.
  global,
}

/// Describes the validation errors that can occur while configuring
/// the audit repository.
enum AppEventSchemaMigrationAuditRepositoryConfigurationErrorCode {
  missingFactory,
  missingReader,
  missingRepository,
  invalidInstallationMode,
  alreadyInitialized,
}

/// Represents an invalid audit repository configuration.
final class AppEventSchemaMigrationAuditRepositoryConfigurationException
    implements Exception {
  const AppEventSchemaMigrationAuditRepositoryConfigurationException({
    required this.code,
    required this.message,
  });

  final AppEventSchemaMigrationAuditRepositoryConfigurationErrorCode code;
  final String message;

  @override
  String toString() {
    return 'AppEventSchemaMigrationAuditRepositoryConfigurationException'
        '(code: ${code.name}, message: $message)';
  }
}

/// Holds the dependencies and installation policy required to configure
/// an audit repository.
///
/// This object does not create storage resources. The reader and factory
/// must be constructed by the application composition root and injected
/// through this configuration.
final class AppEventSchemaMigrationAuditRepositoryConfiguration {
  const AppEventSchemaMigrationAuditRepositoryConfiguration({
    required this.factory,
    required this.reader,
    this.installationMode =
        AppEventSchemaMigrationAuditRepositoryInstallationMode.scoped,
  });

  final AppEventSchemaMigrationAuditRepositoryFactory factory;
  final AppEventSchemaMigrationAuditReader reader;

  final AppEventSchemaMigrationAuditRepositoryInstallationMode
      installationMode;

  /// Validates the configuration before creating the repository.
  ///
  /// A valid configuration contains all required dependencies and a
  /// supported installation mode.
  void validate() {
    if (installationMode ==
        AppEventSchemaMigrationAuditRepositoryInstallationMode.global) {
      if (AppEventSchemaMigrationAuditRepositoryProvider.isInitialized) {
        throw const AppEventSchemaMigrationAuditRepositoryConfigurationException(
          code: AppEventSchemaMigrationAuditRepositoryConfigurationErrorCode
              .alreadyInitialized,
          message: 'A global audit repository provider is already installed.',
        );
      }
    }
  }

  /// Creates the repository using the injected factory and reader.
  ///
  /// The returned repository is not installed globally and is not wrapped
  /// in a provider. The caller retains ownership of its lifecycle.
  AppEventSchemaMigrationAuditRepository createRepository() {
    validate();

    return factory.create(reader: reader);
  }

  /// Creates a provider for the configured repository.
  ///
  /// In scoped mode, the returned provider remains local to the caller.
  /// In global mode, it is installed as the application's global provider.
  AppEventSchemaMigrationAuditRepositoryProvider createProvider() {
    validate();

    final repository = factory.create(reader: reader);

    final provider =
        AppEventSchemaMigrationAuditRepositoryProvider(
      repository: repository,
    );

    if (installationMode ==
        AppEventSchemaMigrationAuditRepositoryInstallationMode.global) {
      AppEventSchemaMigrationAuditRepositoryProvider.install(provider);
    }

    return provider;
  }
}
