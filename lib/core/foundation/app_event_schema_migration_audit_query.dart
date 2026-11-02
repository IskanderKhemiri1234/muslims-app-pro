
import 'app_event_schema_migration_audit.dart';
import 'app_event_schema_migration_audit_reader.dart';

enum AppEventSchemaMigrationAuditPaginationMode {
  offset,
  cursor,
}

final class AppEventSchemaMigrationAuditCursor {
  AppEventSchemaMigrationAuditCursor({
    required this.timestamp,
    required this.auditId,
  }) {
    if (auditId.trim().isEmpty || auditId.length > 160) {
      throw ArgumentError.value(auditId, 'auditId');
    }

    if (!_identifierPattern.hasMatch(auditId)) {
      throw ArgumentError.value(auditId, 'auditId');
    }

    this.timestamp = timestamp.toUtc();
  }

  late final DateTime timestamp;
  final String auditId;

  static final RegExp _identifierPattern = RegExp(
    r'^[A-Za-z0-9][A-Za-z0-9._:-]*$',
  );

  Map<String, Object?> toMap() {
    return Map<String, Object?>.unmodifiable({
      'timestamp': timestamp.toIso8601String(),
      'auditId': auditId,
    });
  }

  factory AppEventSchemaMigrationAuditCursor.fromRecord(
    AppEventSchemaMigrationAuditRecord record,
  ) {
    return AppEventSchemaMigrationAuditCursor(
      timestamp: record.timestamp,
      auditId: record.auditId,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AppEventSchemaMigrationAuditCursor &&
            timestamp.isAtSameMomentAs(other.timestamp) &&
            auditId == other.auditId;
  }

  @override
  int get hashCode => Object.hash(timestamp, auditId);
}

final class AppEventSchemaMigrationAuditQuery {
  AppEventSchemaMigrationAuditQuery({
    AppEventSchemaMigrationAuditFilter? filter,
    this.page = 1,
    this.pageSize = 50,
    this.sortOrder = AppEventSchemaMigrationAuditSortOrder.descending,
    this.paginationMode =
        AppEventSchemaMigrationAuditPaginationMode.offset,
    this.cursor,
    this.maximumPageSize = 200,
  }) {
    if (page < 1) {
      throw ArgumentError.value(page, 'page');
    }

    if (pageSize < 1 || pageSize > maximumPageSize) {
      throw ArgumentError.value(pageSize, 'pageSize');
    }

    if (maximumPageSize < 1) {
      throw ArgumentError.value(maximumPageSize, 'maximumPageSize');
    }

    if (page > 1 && page - 1 > 0x7fffffff ~/ pageSize) {
      throw ArgumentError.value(page, 'page');
    }

    if (paginationMode ==
            AppEventSchemaMigrationAuditPaginationMode.cursor &&
        cursor == null) {
      throw ArgumentError(
        'Cursor pagination requires a cursor.',
      );
    }

    if (paginationMode ==
            AppEventSchemaMigrationAuditPaginationMode.cursor &&
        page != 1) {
      throw ArgumentError(
        'Cursor pagination cannot be combined with an offset page number.',
      );
    }

    this.filter = filter;
  }

  final AppEventSchemaMigrationAuditFilter? filter;
  final int page;
  final int pageSize;
  final AppEventSchemaMigrationAuditSortOrder sortOrder;
  final AppEventSchemaMigrationAuditPaginationMode paginationMode;
  final AppEventSchemaMigrationAuditCursor? cursor;
  final int maximumPageSize;

  bool get usesOffsetPagination =>
      paginationMode ==
      AppEventSchemaMigrationAuditPaginationMode.offset;

  bool get usesCursorPagination =>
      paginationMode ==
      AppEventSchemaMigrationAuditPaginationMode.cursor;

  AppEventSchemaMigrationAuditQuery copyWith({
    AppEventSchemaMigrationAuditFilter? filter,
    int? page,
    int? pageSize,
    AppEventSchemaMigrationAuditSortOrder? sortOrder,
    AppEventSchemaMigrationAuditPaginationMode? paginationMode,
    AppEventSchemaMigrationAuditCursor? cursor,
    int? maximumPageSize,
    bool clearCursor = false,
  }) {
    return AppEventSchemaMigrationAuditQuery(
      filter: filter ?? this.filter,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      sortOrder: sortOrder ?? this.sortOrder,
      paginationMode: paginationMode ?? this.paginationMode,
      cursor: clearCursor ? null : cursor ?? this.cursor,
      maximumPageSize: maximumPageSize ?? this.maximumPageSize,
    );
  }

  AppEventSchemaMigrationAuditQuery nextOffsetPage() {
    if (!usesOffsetPagination) {
      throw StateError(
        'Offset navigation is unavailable in cursor mode.',
      );
    }

    return copyWith(page: page + 1);
  }

  AppEventSchemaMigrationAuditQuery previousOffsetPage() {
    if (!usesOffsetPagination) {
      throw StateError(
        'Offset navigation is unavailable in cursor mode.',
      );
    }

    return copyWith(page: page > 1 ? page - 1 : 1);
  }

  AppEventSchemaMigrationAuditQuery withCursor(
    AppEventSchemaMigrationAuditCursor nextCursor,
  ) {
    return AppEventSchemaMigrationAuditQuery(
      filter: filter,
      page: 1,
      pageSize: pageSize,
      sortOrder: sortOrder,
      paginationMode:
          AppEventSchemaMigrationAuditPaginationMode.cursor,
      cursor: nextCursor,
      maximumPageSize: maximumPageSize,
    );
  }

  AppEventSchemaMigrationAuditQuery withoutCursor() {
    return AppEventSchemaMigrationAuditQuery(
      filter: filter,
      page: 1,
      pageSize: pageSize,
      sortOrder: sortOrder,
      paginationMode:
          AppEventSchemaMigrationAuditPaginationMode.offset,
      maximumPageSize: maximumPageSize,
    );
  }
}
