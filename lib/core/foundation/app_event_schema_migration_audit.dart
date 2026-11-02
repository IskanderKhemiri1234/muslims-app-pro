
import 'dart:collection';

import 'app_clock.dart';
import 'app_event_schema_migration_guard.dart';
import 'app_event_schema_migration_policy.dart';
import 'app_event_schema_registry.dart';
import 'app_event_schema_migration.dart';

enum AppEventSchemaMigrationAuditDecision {
  allowed,
  denied,
}

enum AppEventSchemaMigrationAuditDirection {
  upgrade,
  downgrade,
  sameVersion,
  invalid,
}

enum AppEventSchemaMigrationAuditExecutionStatus {
  notStarted,
  succeeded,
  failed,
}

enum AppEventSchemaMigrationAuditRecordType {
  authorization,
  execution,
}

abstract interface class AppEventSchemaMigrationAuditIdGenerator {
  String nextId();
}

final class SequentialAppEventSchemaMigrationAuditIdGenerator
    implements AppEventSchemaMigrationAuditIdGenerator {
  SequentialAppEventSchemaMigrationAuditIdGenerator({
    String prefix = 'schema-migration-audit',
    int initialValue = 0,
  })  : _prefix = _validatePrefix(prefix),
        _counter = initialValue {
    if (initialValue < 0) {
      throw ArgumentError.value(
        initialValue,
        'initialValue',
        'Must not be negative.',
      );
    }
  }

  final String _prefix;
  int _counter;

  static String _validatePrefix(String value) {
    final normalized = value.trim();

    if (normalized.isEmpty) {
      throw ArgumentError.value(
        value,
        'prefix',
        'Must not be empty.',
      );
    }

    return normalized;
  }

  @override
  String nextId() {
    _counter++;

    return '$_prefix-$_counter';
  }
}

final class AppEventSchemaMigrationAuditRecord {
  AppEventSchemaMigrationAuditRecord({
    required this.auditId,
    required this.operationId,
    required this.recordType,
    required this.timestamp,
    required this.eventType,
    required this.sourceVersion,
    required this.targetVersion,
    required this.direction,
    required this.decision,
    required this.guardCode,
    required this.policyCode,
    required this.executionStatus,
    required this.migrationCount,
    required this.appliedVersions,
    required this.durationMilliseconds,
    required this.executionStage,
  }) {
    if (auditId.trim().isEmpty) {
      throw ArgumentError.value(auditId, 'auditId');
    }

    if (operationId.trim().isEmpty) {
      throw ArgumentError.value(operationId, 'operationId');
    }

    if (eventType.trim().isEmpty) {
      throw ArgumentError.value(eventType, 'eventType');
    }

    if (sourceVersion < 1) {
      throw ArgumentError.value(sourceVersion, 'sourceVersion');
    }

    if (targetVersion < 1) {
      throw ArgumentError.value(targetVersion, 'targetVersion');
    }

    if (migrationCount < 0) {
      throw ArgumentError.value(migrationCount, 'migrationCount');
    }

    if (durationMilliseconds != null && durationMilliseconds! < 0) {
      throw ArgumentError.value(
        durationMilliseconds,
        'durationMilliseconds',
      );
    }

    if (executionStage != null && executionStage!.trim().isEmpty) {
      throw ArgumentError.value(executionStage, 'executionStage');
    }

    this.timestamp = timestamp.toUtc();
    this.appliedVersions = List<int>.unmodifiable(appliedVersions);
  }

  final String auditId;
  final String operationId;
  final AppEventSchemaMigrationAuditRecordType recordType;
  final DateTime timestamp;
  final String eventType;
  final int sourceVersion;
  final int targetVersion;
  final AppEventSchemaMigrationAuditDirection direction;
  final AppEventSchemaMigrationAuditDecision decision;
  final String guardCode;
  final String? policyCode;
  final AppEventSchemaMigrationAuditExecutionStatus executionStatus;
  final int migrationCount;
  final List<int> appliedVersions;
  final int? durationMilliseconds;
  final String? executionStage;

  bool get isAuthorizationRecord =>
      recordType == AppEventSchemaMigrationAuditRecordType.authorization;

  bool get isExecutionRecord =>
      recordType == AppEventSchemaMigrationAuditRecordType.execution;

  bool get wasAllowed =>
      decision == AppEventSchemaMigrationAuditDecision.allowed;

  bool get executionSucceeded =>
      executionStatus ==
      AppEventSchemaMigrationAuditExecutionStatus.succeeded;

  Map<String, Object?> toSafeMap() {
    return Map<String, Object?>.unmodifiable({
      'auditId': auditId,
      'operationId': operationId,
      'recordType': recordType.name,
      'timestamp': timestamp.toIso8601String(),
      'eventType': eventType,
      'sourceVersion': sourceVersion,
      'targetVersion': targetVersion,
      'direction': direction.name,
      'decision': decision.name,
      'guardCode': guardCode,
      'policyCode': policyCode,
      'executionStatus': executionStatus.name,
      'migrationCount': migrationCount,
      'appliedVersions': List<int>.unmodifiable(appliedVersions),
      'durationMilliseconds': durationMilliseconds,
      'executionStage': executionStage,
    });
  }
}

abstract interface class AppEventSchemaMigrationAuditSink {
  Future<void> append(AppEventSchemaMigrationAuditRecord record);
}

final class InMemoryAppEventSchemaMigrationAuditSink
    implements AppEventSchemaMigrationAuditSink {
  InMemoryAppEventSchemaMigrationAuditSink({
    int maximumRecords = 1000,
  }) : _maximumRecords = _validateMaximumRecords(maximumRecords);

  final int _maximumRecords;
  final Queue<AppEventSchemaMigrationAuditRecord> _records =
      Queue<AppEventSchemaMigrationAuditRecord>();

  static int _validateMaximumRecords(int value) {
    if (value < 1) {
      throw ArgumentError.value(
        value,
        'maximumRecords',
        'Must be greater than zero.',
      );
    }

    return value;
  }

  List<AppEventSchemaMigrationAuditRecord> get records =>
      List<AppEventSchemaMigrationAuditRecord>.unmodifiable(_records);

  int get length => _records.length;

  bool get isEmpty => _records.isEmpty;

  bool get isNotEmpty => _records.isNotEmpty;

  @override
  Future<void> append(AppEventSchemaMigrationAuditRecord record) async {
    _records.addLast(record);

    while (_records.length > _maximumRecords) {
      _records.removeFirst();
    }
  }

  void clear() {
    _records.clear();
  }
}

final class AppEventSchemaMigrationAuditLogger {
  AppEventSchemaMigrationAuditLogger({
    required AppEventSchemaMigrationAuditSink sink,
    AppClock? clock,
    AppEventSchemaMigrationAuditIdGenerator? idGenerator,
  })  : _sink = sink,
        _clock = clock ?? SystemAppClock(),
        _idGenerator = idGenerator ??
            SequentialAppEventSchemaMigrationAuditIdGenerator();

  final AppEventSchemaMigrationAuditSink _sink;
  final AppClock _clock;
  final AppEventSchemaMigrationAuditIdGenerator _idGenerator;

  Future<AppEventSchemaMigrationAuditRecord> recordAuthorization({
    required AppEventSchemaMigrationGuardResult result,
    required bool allowed,
  }) async {
    final operationId = _idGenerator.nextId();

    final policyCode = result.policyDecision?.code.name;

    final record = AppEventSchemaMigrationAuditRecord(
      auditId: _idGenerator.nextId(),
      operationId: operationId,
      recordType: AppEventSchemaMigrationAuditRecordType.authorization,
      timestamp: _clock.utcNow,
      eventType: result.eventType,
      sourceVersion: result.sourceVersion,
      targetVersion: result.targetVersion,
      direction: _resolveDirection(
        result.sourceVersion,
        result.targetVersion,
      ),
      decision: allowed
          ? AppEventSchemaMigrationAuditDecision.allowed
          : AppEventSchemaMigrationAuditDecision.denied,
      guardCode: result.code.name,
      policyCode: policyCode,
      executionStatus:
          AppEventSchemaMigrationAuditExecutionStatus.notStarted,
      migrationCount: 0,
      appliedVersions: const <int>[],
      durationMilliseconds: null,
      executionStage: null,
    );

    await _sink.append(record);
    return record;
  }

  Future<AppEventSchemaMigrationAuditRecord> recordExecutionSuccess({
    required String operationId,
    required AppEventSchemaMigrationPermit permit,
    required AppEventSchemaMigrationExecutionResult result,
    required DateTime startedAt,
    DateTime? completedAt,
  }) async {
    _validateOperationId(operationId);

    final endTime = (completedAt ?? _clock.utcNow).toUtc();
    final startTime = startedAt.toUtc();

    final duration = endTime.difference(startTime).inMilliseconds;

    if (duration < 0) {
      throw ArgumentError(
        'Execution completion cannot precede its start time.',
      );
    }

    final record = AppEventSchemaMigrationAuditRecord(
      auditId: _idGenerator.nextId(),
      operationId: operationId,
      recordType: AppEventSchemaMigrationAuditRecordType.execution,
      timestamp: endTime,
      eventType: permit.eventType,
      sourceVersion: permit.sourceVersion,
      targetVersion: permit.targetVersion,
      direction: _resolveDirection(
        permit.sourceVersion,
        permit.targetVersion,
      ),
      decision: AppEventSchemaMigrationAuditDecision.allowed,
      guardCode: 'authorized',
      policyCode: permit.compatibility.name,
      executionStatus:
          AppEventSchemaMigrationAuditExecutionStatus.succeeded,
      migrationCount: result.migrationCount,
      appliedVersions: result.appliedVersions,
      durationMilliseconds: duration,
      executionStage: null,
    );

    await _sink.append(record);
    return record;
  }

  Future<AppEventSchemaMigrationAuditRecord> recordExecutionFailure({
    required String operationId,
    required AppEventSchemaMigrationPermit permit,
    required String stage,
    required DateTime startedAt,
    DateTime? failedAt,
  }) async {
    _validateOperationId(operationId);

    final normalizedStage = stage.trim();

    if (normalizedStage.isEmpty) {
      throw ArgumentError.value(stage, 'stage');
    }

    final endTime = (failedAt ?? _clock.utcNow).toUtc();
    final startTime = startedAt.toUtc();

    final duration = endTime.difference(startTime).inMilliseconds;

    if (duration < 0) {
      throw ArgumentError(
        'Failure time cannot precede the execution start time.',
      );
    }

    final record = AppEventSchemaMigrationAuditRecord(
      auditId: _idGenerator.nextId(),
      operationId: operationId,
      recordType: AppEventSchemaMigrationAuditRecordType.execution,
      timestamp: endTime,
      eventType: permit.eventType,
      sourceVersion: permit.sourceVersion,
      targetVersion: permit.targetVersion,
      direction: _resolveDirection(
        permit.sourceVersion,
        permit.targetVersion,
      ),
      decision: AppEventSchemaMigrationAuditDecision.allowed,
      guardCode: 'authorized',
      policyCode: permit.compatibility.name,
      executionStatus:
          AppEventSchemaMigrationAuditExecutionStatus.failed,
      migrationCount: 0,
      appliedVersions: const <int>[],
      durationMilliseconds: duration,
      executionStage: normalizedStage,
    );

    await _sink.append(record);
    return record;
  }

  AppEventSchemaMigrationAuditDirection _resolveDirection(
    int sourceVersion,
    int targetVersion,
  ) {
    if (sourceVersion < 1 || targetVersion < 1) {
      return AppEventSchemaMigrationAuditDirection.invalid;
    }

    if (sourceVersion == targetVersion) {
      return AppEventSchemaMigrationAuditDirection.sameVersion;
    }

    if (sourceVersion < targetVersion) {
      return AppEventSchemaMigrationAuditDirection.upgrade;
    }

    return AppEventSchemaMigrationAuditDirection.downgrade;
  }

  void _validateOperationId(String operationId) {
    if (operationId.trim().isEmpty) {
      throw ArgumentError.value(
        operationId,
        'operationId',
        'Must not be empty.',
      );
    }
  }
}
