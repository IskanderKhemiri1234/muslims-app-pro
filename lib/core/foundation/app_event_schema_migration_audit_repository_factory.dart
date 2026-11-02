
import 'app_event_schema_migration_audit_reader.dart';
import 'app_event_schema_migration_audit_repository.dart';

/// Creates audit repository implementations from injected dependencies.
///
/// The factory does not select a storage technology, create a database,
/// initialize a storage engine, or access global application state.
///
/// The composition root is responsible for constructing the reader and
/// selecting the appropriate repository implementation.
abstract interface class AppEventSchemaMigrationAuditRepositoryFactory {
  /// Creates a repository using the supplied audit reader.
  AppEventSchemaMigrationAuditRepository create({
    required AppEventSchemaMigrationAuditReader reader,
  });
}

/// Creates a repository backed by the existing audit reader.
///
/// This factory delegates filtering, sorting, counting, and offset
/// pagination to the supplied reader through the repository adapter.
///
/// It does not own or dispose the reader or its underlying data source.
final class ReaderBackedAppEventSchemaMigrationAuditRepositoryFactory
    implements AppEventSchemaMigrationAuditRepositoryFactory {
  const ReaderBackedAppEventSchemaMigrationAuditRepositoryFactory();

  @override
  AppEventSchemaMigrationAuditRepository create({
    required AppEventSchemaMigrationAuditReader reader,
  }) {
    return ReaderBackedAppEventSchemaMigrationAuditRepository(
      reader: reader,
    );
  }
}
