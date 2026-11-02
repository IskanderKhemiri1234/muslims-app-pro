
import 'dart:convert';

import 'app_clock.dart';
import 'app_event_schema_migration_audit.dart';

enum AppEventSchemaMigrationAuditExportFormat {
  json,
}

enum AppEventSchemaMigrationAuditExportErrorCode {
  invalidRecord,
  unsupportedField,
  invalidIdentifier,
  tooManyRecords,
  encodingFailure,
}

final class AppEventSchemaMigrationAuditExportException
    implements Exception {
  const AppEventSchemaMigrationAuditExportException({
    required this.code,
  });

  final AppEventSchemaMigrationAuditExportErrorCode code;

  @override
  String toString() {
    return 'AppEventSchemaMigrationAuditExportException(${code.name})';
  }
}

final class AppEventSchemaMigrationAuditExportPolicy {
  const AppEventSchemaMigrationAuditExportPolicy({
    this.maximumRecords = 5000,
    this.includeOperationId = true,
    this.includeAppliedVersions = true,
    this.includeDuration = true,
  }) {
    if (maximumRecords < 1) {
      throw ArgumentError.value(
        maximumRecords,
        'maximumRecords',
        'Must be greater than zero.',
      );
    }
  }

  final int maximumRecords;
  final bool includeOperationId;
  final bool includeAppliedVersions;
  final bool includeDuration;

  static const Set<String> allowedFields = <String>{
    'auditId',
    'operationId',
    'recordType',
    'timestamp',
    'eventType',
    'sourceVersion',
    'targetVersion',
    'direction',
    'decision',
    'guardCode',
    'policyCode',
    'executionStatus',
    'migrationCount',
    'appliedVersions',
    'durationMilliseconds',
  };

  static const Set<String> forbiddenFieldNames = <String>{
    'payload',
    'data',
    'body',
    'content',
    'raw',
    'rawPayload',
    'request',
    'response',
    'exception',
    'stackTrace',
    'cause',
    'user',
    'email',
    'phone',
    'address',
    'accessToken',
    'refreshToken',
    'authorization',
    'password',
    'secret',
    'credentials',
    'metadata',
    'attributes',
    'tags',
    'executionStage',
    'reason',
    'message',
  };
}

final class AppEventSchemaMigrationAuditExportDocument {
  AppEventSchemaMigrationAuditExportDocument({
    required this.format,
    required this.formatVersion,
    required DateTime exportedAt,
    required List<Map<String, Object?>> records,
  })  : exportedAt = exportedAt.toUtc(),
        records = List<Map<String, Object?>>.unmodifiable(
          records.map(
            (record) => Map<String, Object?>.unmodifiable(record),
          ),
        ) {
    if (formatVersion < 1) {
      throw ArgumentError.value(formatVersion, 'formatVersion');
    }
  }

  final AppEventSchemaMigrationAuditExportFormat format;
  final int formatVersion;
  final DateTime exportedAt;
  final List<Map<String, Object?>> records;

  Map<String, Object?> toMap() {
    return Map<String, Object?>.unmodifiable({
      'format': format.name,
      'formatVersion': formatVersion,
      'exportedAt': exportedAt.toIso8601String(),
      'recordCount': records.length,
      'records': records,
    });
  }

  String toJson() {
    try {
      return jsonEncode(toMap());
    } on Object {
      throw const AppEventSchemaMigrationAuditExportException(
        code: AppEventSchemaMigrationAuditExportErrorCode.encodingFailure,
      );
    }
  }
}

final class AppEventSchemaMigrationAuditExporter {
  AppEventSchemaMigrationAuditExporter({
    AppEventSchemaMigrationAuditExportPolicy policy =
        const AppEventSchemaMigrationAuditExportPolicy(),
    AppClock? clock,
  })  : _policy = policy,
        _clock = clock ?? SystemAppClock();

  static const int formatVersion = 1;

  final AppEventSchemaMigrationAuditExportPolicy _policy;
  final AppClock _clock;

  AppEventSchemaMigrationAuditExportDocument exportRecords(
    Iterable<AppEventSchemaMigrationAuditRecord> sourceRecords,
  ) {
    final exportedRecords = <Map<String, Object?>>[];

    for (final record in sourceRecords) {
      if (exportedRecords.length >= _policy.maximumRecords) {
        throw const AppEventSchemaMigrationAuditExportException(
          code: AppEventSchemaMigrationAuditExportErrorCode.tooManyRecords,
        );
      }

      exportedRecords.add(_exportRecord(record));
    }

    return AppEventSchemaMigrationAuditExportDocument(
      format: AppEventSchemaMigrationAuditExportFormat.json,
      formatVersion: formatVersion,
      exportedAt: _clock.utcNow,
      records: exportedRecords,
    );
  }

  String exportJson(
    Iterable<AppEventSchemaMigrationAuditRecord> sourceRecords,
  ) {
    return exportRecords(sourceRecords).toJson();
  }

  Map<String, Object?> exportMap(
    Iterable<AppEventSchemaMigrationAuditRecord> sourceRecords,
  ) {
    return exportRecords(sourceRecords).toMap();
  }

  Map<String, Object?> _exportRecord(
    AppEventSchemaMigrationAuditRecord record,
  ) {
    _validateRecord(record);

    final output = <String, Object?>{
      'auditId': record.auditId,
      'recordType': record.recordType.name,
      'timestamp': record.timestamp.toUtc().toIso8601String(),
      'eventType': record.eventType,
      'sourceVersion': record.sourceVersion,
      'targetVersion': record.targetVersion,
      'direction': record.direction.name,
      'decision': record.decision.name,
      'guardCode': record.guardCode,
      'executionStatus': record.executionStatus.name,
      'migrationCount': record.migrationCount,
    };

    if (_policy.includeOperationId) {
      output['operationId'] = record.operationId;
    }

    if (record.policyCode != null) {
      output['policyCode'] = record.policyCode;
    }

    if (_policy.includeAppliedVersions) {
      output['appliedVersions'] = List<int>.unmodifiable(
        record.appliedVersions,
      );
    }

    if (_policy.includeDuration &&
        record.durationMilliseconds != null) {
      output['durationMilliseconds'] = record.durationMilliseconds;
    }

    _validateExportedFields(output);

    return Map<String, Object?>.unmodifiable(output);
  }

  void _validateRecord(AppEventSchemaMigrationAuditRecord record) {
    if (record.auditId.trim().isEmpty ||
        record.operationId.trim().isEmpty ||
        record.eventType.trim().isEmpty ||
        record.sourceVersion < 1 ||
        record.targetVersion < 1 ||
        record.migrationCount < 0) {
      throw const AppEventSchemaMigrationAuditExportException(
        code: AppEventSchemaMigrationAuditExportErrorCode.invalidRecord,
      );
    }

    _validateIdentifier(record.auditId);
    _validateIdentifier(record.operationId);
    _validateIdentifier(record.eventType);
    _validateIdentifier(record.guardCode);

    if (record.policyCode != null) {
      _validateIdentifier(record.policyCode!);
    }

    if (record.durationMilliseconds != null &&
        record.durationMilliseconds! < 0) {
      throw const AppEventSchemaMigrationAuditExportException(
        code: AppEventSchemaMigrationAuditExportErrorCode.invalidRecord,
      );
    }

    for (final version in record.appliedVersions) {
      if (version < 1) {
        throw const AppEventSchemaMigrationAuditExportException(
          code: AppEventSchemaMigrationAuditExportErrorCode.invalidRecord,
        );
      }
    }
  }

  void _validateIdentifier(String value) {
    final normalized = value.trim();

    if (normalized.isEmpty ||
        normalized.length > 160 ||
        !_identifierPattern.hasMatch(normalized)) {
      throw const AppEventSchemaMigrationAuditExportException(
        code: AppEventSchemaMigrationAuditExportErrorCode.invalidIdentifier,
      );
    }
  }

  void _validateExportedFields(Map<String, Object?> fields) {
    for (final fieldName in fields.keys) {
      if (AppEventSchemaMigrationAuditExportPolicy
          .forbiddenFieldNames
          .contains(fieldName)) {
        throw const AppEventSchemaMigrationAuditExportException(
          code: AppEventSchemaMigrationAuditExportErrorCode.unsupportedField,
        );
      }

      if (!AppEventSchemaMigrationAuditExportPolicy.allowedFields
          .contains(fieldName)) {
        throw const AppEventSchemaMigrationAuditExportException(
          code: AppEventSchemaMigrationAuditExportErrorCode.unsupportedField,
        );
      }
    }
  }

  static final RegExp _identifierPattern = RegExp(
    r'^[A-Za-z0-9][A-Za-z0-9._:-]*$',
  );
}
