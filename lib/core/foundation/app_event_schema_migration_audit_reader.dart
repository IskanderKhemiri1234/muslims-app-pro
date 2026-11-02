
import 'app_event_schema_migration_audit.dart';

/// Defines the read operations exposed by an audit data source.
abstract interface class AppEventSchemaMigrationAuditReadSource {
  Future<List<AppEventSchemaMigrationAuditRecord>> readRecords();
}

/// In-memory read source backed by an existing audit sink.
///
/// This adapter does not own or dispose the sink.
final class InMemoryAppEventSchemaMigrationAuditReadSource
    implements AppEventSchemaMigrationAuditReadSource {
  InMemoryAppEventSchemaMigrationAuditReadSource({
    required InMemoryAppEventSchemaMigrationAuditSink sink,
  }) : _sink = sink;

  final InMemoryAppEventSchemaMigrationAuditSink _sink;

  @override
  Future<List<AppEventSchemaMigrationAuditRecord>> readRecords() async {
    return List<AppEventSchemaMigrationAuditRecord>.unmodifiable(
      _sink.records,
    );
  }
}

/// Defines the ordering applied to audit records.
enum AppEventSchemaMigrationAuditSortOrder {
  ascending,
  descending,
}

/// Identifies audit reader errors.
enum AppEventSchemaMigrationAuditReaderErrorCode {
  invalidPage,
  invalidPageSize,
  invalidDateRange,
  invalidFilter,
  invalidRecord,
}

/// Describes an error raised by the audit reader.
final class AppEventSchemaMigrationAuditReaderException
    implements Exception {
  const AppEventSchemaMigrationAuditReaderException({
    required this.code,
  });

  final AppEventSchemaMigrationAuditReaderErrorCode code;

  @override
  String toString() {
    return 'AppEventSchemaMigrationAuditReaderException(${code.name})';
  }
}

/// Defines optional filtering criteria for audit records.
final class AppEventSchemaMigrationAuditFilter {
  AppEventSchemaMigrationAuditFilter({
    this.operationId,
    this.eventType,
    this.sourceVersion,
    this.targetVersion,
    this.direction,
    this.decision,
    this.recordType,
    this.executionStatus,
    this.guardCode,
    this.policyCode,
    DateTime? from,
    DateTime? until,
  })  : from = from?.toUtc(),
        until = until?.toUtc() {
    _validateOptionalIdentifier(operationId, 'operationId');
    _validateOptionalIdentifier(eventType, 'eventType');
    _validateOptionalIdentifier(guardCode, 'guardCode');
    _validateOptionalIdentifier(policyCode, 'policyCode');

    if (sourceVersion != null && sourceVersion < 1) {
      throw ArgumentError.value(sourceVersion, 'sourceVersion');
    }

    if (targetVersion != null && targetVersion < 1) {
      throw ArgumentError.value(targetVersion, 'targetVersion');
    }

    if (this.from != null &&
        this.until != null &&
        this.from!.isAfter(this.until!)) {
      throw ArgumentError(
        'The from date must not be after the until date.',
      );
    }
  }

  final String? operationId;
  final String? eventType;
  final int? sourceVersion;
  final int? targetVersion;
  final AppEventSchemaMigrationAuditDirection? direction;
  final AppEventSchemaMigrationAuditDecision? decision;
  final AppEventSchemaMigrationAuditRecordType? recordType;
  final AppEventSchemaMigrationAuditExecutionStatus? executionStatus;
  final String? guardCode;
  final String? policyCode;
  final DateTime? from;
  final DateTime? until;

  static void _validateOptionalIdentifier(
    String? value,
    String fieldName,
  ) {
    if (value == null) {
      return;
    }

    final normalized = value.trim();

    if (normalized.isEmpty || normalized.length > 160) {
      throw ArgumentError.value(value, fieldName);
    }
  }

  /// Returns whether [record] satisfies every configured filter.
  bool matches(AppEventSchemaMigrationAuditRecord record) {
    if (operationId != null && record.operationId != operationId) {
      return false;
    }

    if (eventType != null && record.eventType != eventType) {
      return false;
    }

    if (sourceVersion != null &&
        record.sourceVersion != sourceVersion) {
      return false;
    }

    if (targetVersion != null &&
        record.targetVersion != targetVersion) {
      return false;
    }

    if (direction != null && record.direction != direction) {
      return false;
    }

    if (decision != null && record.decision != decision) {
      return false;
    }

    if (recordType != null && record.recordType != recordType) {
      return false;
    }

    if (executionStatus != null &&
        record.executionStatus != executionStatus) {
      return false;
    }

    if (guardCode != null && record.guardCode != guardCode) {
      return false;
    }

    if (policyCode != null && record.policyCode != policyCode) {
      return false;
    }

    if (from != null && record.timestamp.isBefore(from!)) {
      return false;
    }

    if (until != null && record.timestamp.isAfter(until!)) {
      return false;
    }

    return true;
  }
}

/// Represents one immutable page of audit records.
final class AppEventSchemaMigrationAuditPage {
  AppEventSchemaMigrationAuditPage({
    required List<AppEventSchemaMigrationAuditRecord> records,
    required this.page,
    required this.pageSize,
    required this.totalRecords,
    required this.totalPages,
    required this.hasPreviousPage,
    required this.hasNextPage,
    required this.sortOrder,
  }) : records = List<AppEventSchemaMigrationAuditRecord>.unmodifiable(
          records,
        ) {
    if (page < 1 ||
        pageSize < 1 ||
        totalRecords < 0 ||
        totalPages < 0 ||
        records.length > pageSize ||
        records.length > totalRecords) {
      throw ArgumentError('Invalid pagination metadata.');
    }
  }

  final List<AppEventSchemaMigrationAuditRecord> records;
  final int page;
  final int pageSize;
  final int totalRecords;
  final int totalPages;
  final bool hasPreviousPage;
  final bool hasNextPage;
  final AppEventSchemaMigrationAuditSortOrder sortOrder;

  bool get isEmpty => records.isEmpty;

  bool get isNotEmpty => records.isNotEmpty;

  int get returnedRecords => records.length;
}

/// Reads, filters, sorts, and paginates audit records.
///
/// This reader does not own the read source and does not manage its
/// lifecycle. Its maximum page size defaults to 200 records.
final class AppEventSchemaMigrationAuditReader {
  AppEventSchemaMigrationAuditReader({
    required AppEventSchemaMigrationAuditReadSource source,
    this.maximumPageSize = 200,
  }) : _source = source {
    if (maximumPageSize < 1) {
      throw ArgumentError.value(
        maximumPageSize,
        'maximumPageSize',
        'Must be greater than zero.',
      );
    }
  }

  final AppEventSchemaMigrationAuditReadSource _source;

  /// Maximum number of records allowed in a single page.
  final int maximumPageSize;

  /// Reads a filtered and sorted page of audit records.
  Future<AppEventSchemaMigrationAuditPage> readPage({
    AppEventSchemaMigrationAuditFilter? filter,
    int page = 1,
    int pageSize = 50,
    AppEventSchemaMigrationAuditSortOrder sortOrder =
        AppEventSchemaMigrationAuditSortOrder.descending,
  }) async {
    _validatePagination(
      page: page,
      pageSize: pageSize,
    );

    final sourceRecords = await _source.readRecords();

    final filteredRecords = <AppEventSchemaMigrationAuditRecord>[];

    for (final record in sourceRecords) {
      _validateRecord(record);

      if (filter == null || filter.matches(record)) {
        filteredRecords.add(record);
      }
    }

    filteredRecords.sort(
      (first, second) => _compareRecords(
        first,
        second,
        sortOrder,
      ),
    );

    final totalRecords = filteredRecords.length;

    final totalPages = totalRecords == 0
        ? 0
        : 1 + ((totalRecords - 1) ~/ pageSize);

    final startIndex = (page - 1) * pageSize;

    final pageRecords = startIndex >= totalRecords
        ? const <AppEventSchemaMigrationAuditRecord>[]
        : filteredRecords
            .skip(startIndex)
            .take(pageSize)
            .toList(growable: false);

    return AppEventSchemaMigrationAuditPage(
      records: pageRecords,
      page: page,
      pageSize: pageSize,
      totalRecords: totalRecords,
      totalPages: totalPages,
      hasPreviousPage: page > 1 && totalRecords > 0,
      hasNextPage: page < totalPages,
      sortOrder: sortOrder,
    );
  }

  /// Counts matching records independently of pagination.
  Future<int> count({
    AppEventSchemaMigrationAuditFilter? filter,
  }) async {
    final sourceRecords = await _source.readRecords();

    var total = 0;

    for (final record in sourceRecords) {
      _validateRecord(record);

      if (filter == null || filter.matches(record)) {
        total++;
      }
    }

    return total;
  }

  /// Reads the first page.
  Future<AppEventSchemaMigrationAuditPage> firstPage({
    AppEventSchemaMigrationAuditFilter? filter,
    int pageSize = 50,
    AppEventSchemaMigrationAuditSortOrder sortOrder =
        AppEventSchemaMigrationAuditSortOrder.descending,
  }) {
    return readPage(
      filter: filter,
      page: 1,
      pageSize: pageSize,
      sortOrder: sortOrder,
    );
  }

  /// Reads the next page when one exists.
  ///
  /// If no next page exists, the current page number is read again.
  Future<AppEventSchemaMigrationAuditPage> nextPage({
    required AppEventSchemaMigrationAuditPage currentPage,
    AppEventSchemaMigrationAuditFilter? filter,
  }) {
    if (!currentPage.hasNextPage) {
      return readPage(
        filter: filter,
        page: currentPage.page,
        pageSize: currentPage.pageSize,
        sortOrder: currentPage.sortOrder,
      );
    }

    return readPage(
      filter: filter,
      page: currentPage.page + 1,
      pageSize: currentPage.pageSize,
      sortOrder: currentPage.sortOrder,
    );
  }

  /// Reads the previous page, or the first page when already at page one.
  Future<AppEventSchemaMigrationAuditPage> previousPage({
    required AppEventSchemaMigrationAuditPage currentPage,
    AppEventSchemaMigrationAuditFilter? filter,
  }) {
    final previousPageNumber =
        currentPage.page > 1 ? currentPage.page - 1 : 1;

    return readPage(
      filter: filter,
      page: previousPageNumber,
      pageSize: currentPage.pageSize,
      sortOrder: currentPage.sortOrder,
    );
  }

  void _validatePagination({
    required int page,
    required int pageSize,
  }) {
    if (page < 1) {
      throw const AppEventSchemaMigrationAuditReaderException(
        code: AppEventSchemaMigrationAuditReaderErrorCode.invalidPage,
      );
    }

    if (pageSize < 1 || pageSize > maximumPageSize) {
      throw const AppEventSchemaMigrationAuditReaderException(
        code: AppEventSchemaMigrationAuditReaderErrorCode.invalidPageSize,
      );
    }

    if (page > 1 && page - 1 > 0x7fffffff ~/ pageSize) {
      throw const AppEventSchemaMigrationAuditReaderException(
        code: AppEventSchemaMigrationAuditReaderErrorCode.invalidPage,
      );
    }
  }

  /// Compares records using timestamp and audit ID as a stable tie-breaker.
  ///
  /// Reverses operand order for descending order instead of negating the
  /// comparison result.
  int _compareRecords(
    AppEventSchemaMigrationAuditRecord first,
    AppEventSchemaMigrationAuditRecord second,
    AppEventSchemaMigrationAuditSortOrder sortOrder,
  ) {
    if (sortOrder == AppEventSchemaMigrationAuditSortOrder.ascending) {
      final timestampComparison =
          first.timestamp.compareTo(second.timestamp);

      if (timestampComparison != 0) {
        return timestampComparison;
      }

      return first.auditId.compareTo(second.auditId);
    }

    final timestampComparison =
        second.timestamp.compareTo(first.timestamp);

    if (timestampComparison != 0) {
      return timestampComparison;
    }

    return second.auditId.compareTo(first.auditId);
  }

  /// Validates the minimum integrity requirements of an audit record.
  void _validateRecord(AppEventSchemaMigrationAuditRecord record) {
    if (record.auditId.trim().isEmpty ||
        record.operationId.trim().isEmpty ||
        record.eventType.trim().isEmpty ||
        record.sourceVersion < 1 ||
        record.targetVersion < 1 ||
        record.migrationCount < 0 ||
        (record.durationMilliseconds != null &&
            record.durationMilliseconds! < 0)) {
      throw const AppEventSchemaMigrationAuditReaderException(
        code: AppEventSchemaMigrationAuditReaderErrorCode.invalidRecord,
      );
    }

    for (final version in record.appliedVersions) {
      if (version < 1) {
        throw const AppEventSchemaMigrationAuditReaderException(
          code: AppEventSchemaMigrationAuditReaderErrorCode.invalidRecord,
        );
      }
    }
  }
}
