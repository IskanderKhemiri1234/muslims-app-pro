
import 'app_event_schema_migration_audit_reader.dart';
import 'app_event_schema_migration_audit_query.dart';

/// Defines the read operations exposed by the audit repository.
///
/// Application services depend on this abstraction rather than depending
/// directly on an in-memory source, a database, or an audit reader.
///
/// Implementations may use in-memory collections, local databases, or
/// persistent remote storage without changing their consumers.
abstract interface class AppEventSchemaMigrationAuditRepository {
  /// Returns a page of audit records matching [query].
  ///
  /// The query defines filtering, sorting, and pagination requirements.
  Future<AppEventSchemaMigrationAuditPage> findPage(
    AppEventSchemaMigrationAuditQuery query,
  );

  /// Returns the number of records matching [filter].
  ///
  /// The count is independent of pagination settings.
  Future<int> count({
    AppEventSchemaMigrationAuditFilter filter =
        const AppEventSchemaMigrationAuditFilter(),
  });
}

/// Identifies repository-level errors.
enum AppEventSchemaMigrationAuditRepositoryErrorCode {
  invalidQuery,
  unsupportedPaginationMode,
  pageSizeExceedsRepositoryLimit,
  invalidCount,
}

/// Describes an error raised by an audit repository.
final class AppEventSchemaMigrationAuditRepositoryException
    implements Exception {
  const AppEventSchemaMigrationAuditRepositoryException({
    required this.code,
    required this.message,
  });

  final AppEventSchemaMigrationAuditRepositoryErrorCode code;
  final String message;

  @override
  String toString() {
    return 'AppEventSchemaMigrationAuditRepositoryException'
        '(code: ${code.name}, message: $message)';
  }
}

/// Repository implementation backed by the existing audit reader.
///
/// This adapter preserves the repository boundary while reusing the
/// filtering, sorting, and offset-pagination behavior already implemented
/// by [AppEventSchemaMigrationAuditReader].
///
/// Cursor pagination remains represented by the query model, but is not
/// executed by this adapter until cursor support is added to the reader.
final class ReaderBackedAppEventSchemaMigrationAuditRepository
    implements AppEventSchemaMigrationAuditRepository {
  ReaderBackedAppEventSchemaMigrationAuditRepository({
    required AppEventSchemaMigrationAuditReader reader,
  }) : _reader = reader;

  final AppEventSchemaMigrationAuditReader _reader;

  /// Returns a page using the reader's existing offset-pagination API.
  ///
  /// Cursor queries are rejected explicitly rather than silently being
  /// interpreted as offset queries.
  @override
  Future<AppEventSchemaMigrationAuditPage> findPage(
    AppEventSchemaMigrationAuditQuery query,
  ) async {
    _validateQuery(query);

    if (query.paginationMode ==
        AppEventSchemaMigrationAuditPaginationMode.cursor) {
      throw const AppEventSchemaMigrationAuditRepositoryException(
        code: AppEventSchemaMigrationAuditRepositoryErrorCode
            .unsupportedPaginationMode,
        message: 'Cursor pagination is not supported by the current reader.',
      );
    }

    if (query.pageSize > _reader.maximumPageSize) {
      throw AppEventSchemaMigrationAuditRepositoryException(
        code: AppEventSchemaMigrationAuditRepositoryErrorCode
            .pageSizeExceedsRepositoryLimit,
        message: 'The requested page size exceeds the reader limit of '
            '${_reader.maximumPageSize}.',
      );
    }

    return _reader.readPage(
      filter: query.filter,
      page: query.page,
      pageSize: query.pageSize,
      sortOrder: query.sortOrder,
    );
  }

  /// Counts all records matching [filter], without applying pagination.
  @override
  Future<int> count({
    AppEventSchemaMigrationAuditFilter filter =
        const AppEventSchemaMigrationAuditFilter(),
  }) async {
    final result = await _reader.count(filter: filter);

    if (result < 0) {
      throw const AppEventSchemaMigrationAuditRepositoryException(
        code: AppEventSchemaMigrationAuditRepositoryErrorCode.invalidCount,
        message: 'The audit reader returned a negative record count.',
      );
    }

    return result;
  }

  void _validateQuery(AppEventSchemaMigrationAuditQuery query) {
    if (query.page < 1 ||
        query.pageSize < 1 ||
        query.maximumPageSize < 1 ||
        query.pageSize > query.maximumPageSize) {
      throw const AppEventSchemaMigrationAuditRepositoryException(
        code: AppEventSchemaMigrationAuditRepositoryErrorCode.invalidQuery,
        message: 'The audit query contains invalid pagination values.',
      );
    }

    if (query.paginationMode ==
            AppEventSchemaMigrationAuditPaginationMode.offset &&
        query.cursor != null) {
      throw const AppEventSchemaMigrationAuditRepositoryException(
        code: AppEventSchemaMigrationAuditRepositoryErrorCode.invalidQuery,
        message: 'An offset query must not contain a cursor.',
      );
    }

    if (query.paginationMode ==
            AppEventSchemaMigrationAuditPaginationMode.cursor &&
        query.cursor == null) {
      throw const AppEventSchemaMigrationAuditRepositoryException(
        code: AppEventSchemaMigrationAuditRepositoryErrorCode.invalidQuery,
        message: 'A cursor query requires a cursor value.',
      );
    }

    if (query.paginationMode ==
            AppEventSchemaMigrationAuditPaginationMode.cursor &&
        query.page != 1) {
      throw const AppEventSchemaMigrationAuditRepositoryException(
        code: AppEventSchemaMigrationAuditRepositoryErrorCode.invalidQuery,
        message: 'Cursor queries must start at page one.',
      );
    }
  }
}
