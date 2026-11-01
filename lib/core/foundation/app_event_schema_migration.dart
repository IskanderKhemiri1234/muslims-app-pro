
import 'dart:collection';

import 'app_event_schema_registry.dart';
import 'app_event_schema_validator.dart';

typedef AppEventSchemaMigrationPathResolver = List<AppEventSchemaMigration>
    Function({
  required AppEventSchemaRegistry registry,
  required String eventType,
  required int sourceVersion,
  required int targetVersion,
});

typedef AppEventSchemaMigrationValidationCallback = bool Function({
  required AppEventSchemaValidator validator,
  required String eventType,
  required int version,
  required Map<String, Object?> payload,
});

enum AppEventSchemaMigrationStage {
  pathResolution,
  sourceValidation,
  migrationExecution,
  targetValidation,
}

final class AppEventSchemaMigrationException implements Exception {
  const AppEventSchemaMigrationException({
    required this.message,
    required this.eventType,
    required this.sourceVersion,
    required this.targetVersion,
    required this.stage,
    this.stepSourceVersion,
    this.stepTargetVersion,
    this.cause,
  });

  final String message;
  final String eventType;
  final int sourceVersion;
  final int targetVersion;
  final AppEventSchemaMigrationStage stage;
  final int? stepSourceVersion;
  final int? stepTargetVersion;
  final Object? cause;

  @override
  String toString() {
    final buffer = StringBuffer()
      ..write('AppEventSchemaMigrationException: ')
      ..write(message)
      ..write(' [eventType: $eventType')
      ..write(', sourceVersion: $sourceVersion')
      ..write(', targetVersion: $targetVersion')
      ..write(', stage: ${stage.name}');

    if (stepSourceVersion != null) {
      buffer.write(', stepSourceVersion: $stepSourceVersion');
    }

    if (stepTargetVersion != null) {
      buffer.write(', stepTargetVersion: $stepTargetVersion');
    }

    if (cause != null) {
      buffer.write(', cause: $cause');
    }

    buffer.write(']');
    return buffer.toString();
  }
}

final class AppEventSchemaMigrationExecutionResult {
  AppEventSchemaMigrationExecutionResult({
    required this.eventType,
    required this.sourceVersion,
    required this.targetVersion,
    required Map<String, Object?> payload,
    required List<int> appliedVersions,
  })  : payload = _deepFreezeMap(payload),
        appliedVersions = List<int>.unmodifiable(appliedVersions);

  final String eventType;
  final int sourceVersion;
  final int targetVersion;
  final Map<String, Object?> payload;
  final List<int> appliedVersions;

  bool get changed => sourceVersion != targetVersion;

  int get migrationCount => appliedVersions.length;
}

final class AppEventSchemaMigrationExecutor {
  AppEventSchemaMigrationExecutor({
    required AppEventSchemaRegistry registry,
    required AppEventSchemaValidator validator,
    required AppEventSchemaMigrationPathResolver pathResolver,
    required AppEventSchemaMigrationValidationCallback validationCallback,
  })  : _registry = registry,
        _validator = validator,
        _pathResolver = pathResolver,
        _validationCallback = validationCallback;

  final AppEventSchemaRegistry _registry;
  final AppEventSchemaValidator _validator;
  final AppEventSchemaMigrationPathResolver _pathResolver;
  final AppEventSchemaMigrationValidationCallback _validationCallback;

  AppEventSchemaMigrationExecutionResult execute({
    required String eventType,
    required int sourceVersion,
    required int targetVersion,
    required Map<String, Object?> payload,
  }) {
    _validateRequest(
      eventType: eventType,
      sourceVersion: sourceVersion,
      targetVersion: targetVersion,
    );

    final initialPayload = _deepCopyMap(payload);

    if (sourceVersion == targetVersion) {
      _validatePayload(
        eventType: eventType,
        version: sourceVersion,
        payload: initialPayload,
        stage: AppEventSchemaMigrationStage.sourceValidation,
        sourceVersion: sourceVersion,
        targetVersion: targetVersion,
      );

      return AppEventSchemaMigrationExecutionResult(
        eventType: eventType,
        sourceVersion: sourceVersion,
        targetVersion: targetVersion,
        payload: initialPayload,
        appliedVersions: const [],
      );
    }

    final migrationPath = _resolvePath(
      eventType: eventType,
      sourceVersion: sourceVersion,
      targetVersion: targetVersion,
    );

    _validatePath(
      migrationPath: migrationPath,
      eventType: eventType,
      sourceVersion: sourceVersion,
      targetVersion: targetVersion,
    );

    var currentPayload = initialPayload;
    var currentVersion = sourceVersion;

    _validatePayload(
      eventType: eventType,
      version: currentVersion,
      payload: currentPayload,
      stage: AppEventSchemaMigrationStage.sourceValidation,
      sourceVersion: sourceVersion,
      targetVersion: targetVersion,
    );

    final appliedVersions = <int>[];

    for (final migration in migrationPath) {
      final stepSourceVersion = migration.sourceVersion;
      final stepTargetVersion = migration.targetVersion;

      if (stepSourceVersion != currentVersion) {
        throw AppEventSchemaMigrationException(
          message: 'The migration path is not continuous.',
          eventType: eventType,
          sourceVersion: sourceVersion,
          targetVersion: targetVersion,
          stage: AppEventSchemaMigrationStage.pathResolution,
          stepSourceVersion: stepSourceVersion,
          stepTargetVersion: stepTargetVersion,
        );
      }

      final immutableInput = _deepFreezeMap(currentPayload);

      Map<String, Object?> migratedPayload;

      try {
        migratedPayload = migration.migrate(immutableInput);
      } catch (error) {
        throw AppEventSchemaMigrationException(
          message: 'A migration step failed during execution.',
          eventType: eventType,
          sourceVersion: sourceVersion,
          targetVersion: targetVersion,
          stage: AppEventSchemaMigrationStage.migrationExecution,
          stepSourceVersion: stepSourceVersion,
          stepTargetVersion: stepTargetVersion,
          cause: error,
        );
      }

      try {
        currentPayload = _deepCopyMap(migratedPayload);
      } catch (error) {
        throw AppEventSchemaMigrationException(
          message: 'A migration step returned an invalid payload.',
          eventType: eventType,
          sourceVersion: sourceVersion,
          targetVersion: targetVersion,
          stage: AppEventSchemaMigrationStage.migrationExecution,
          stepSourceVersion: stepSourceVersion,
          stepTargetVersion: stepTargetVersion,
          cause: error,
        );
      }

      currentVersion = stepTargetVersion;
      appliedVersions.add(currentVersion);

      _validatePayload(
        eventType: eventType,
        version: currentVersion,
        payload: currentPayload,
        stage: AppEventSchemaMigrationStage.targetValidation,
        sourceVersion: sourceVersion,
        targetVersion: targetVersion,
        stepSourceVersion: stepSourceVersion,
        stepTargetVersion: stepTargetVersion,
      );
    }

    if (currentVersion != targetVersion) {
      throw AppEventSchemaMigrationException(
        message: 'The migration path did not reach the requested version.',
        eventType: eventType,
        sourceVersion: sourceVersion,
        targetVersion: targetVersion,
        stage: AppEventSchemaMigrationStage.pathResolution,
      );
    }

    return AppEventSchemaMigrationExecutionResult(
      eventType: eventType,
      sourceVersion: sourceVersion,
      targetVersion: targetVersion,
      payload: currentPayload,
      appliedVersions: appliedVersions,
    );
  }

  List<AppEventSchemaMigration> _resolvePath({
    required String eventType,
    required int sourceVersion,
    required int targetVersion,
  }) {
    try {
      final path = _pathResolver(
        registry: _registry,
        eventType: eventType,
        sourceVersion: sourceVersion,
        targetVersion: targetVersion,
      );

      return List<AppEventSchemaMigration>.unmodifiable(path);
    } catch (error) {
      throw AppEventSchemaMigrationException(
        message: 'Unable to resolve the migration path.',
        eventType: eventType,
        sourceVersion: sourceVersion,
        targetVersion: targetVersion,
        stage: AppEventSchemaMigrationStage.pathResolution,
        cause: error,
      );
    }
  }

  void _validatePath({
    required List<AppEventSchemaMigration> migrationPath,
    required String eventType,
    required int sourceVersion,
    required int targetVersion,
  }) {
    if (migrationPath.isEmpty) {
      throw AppEventSchemaMigrationException(
        message: 'No migration steps were provided for different versions.',
        eventType: eventType,
        sourceVersion: sourceVersion,
        targetVersion: targetVersion,
        stage: AppEventSchemaMigrationStage.pathResolution,
      );
    }

    var expectedVersion = sourceVersion;

    for (final migration in migrationPath) {
      if (migration.eventType != eventType) {
        throw AppEventSchemaMigrationException(
          message: 'A migration step belongs to a different event type.',
          eventType: eventType,
          sourceVersion: sourceVersion,
          targetVersion: targetVersion,
          stage: AppEventSchemaMigrationStage.pathResolution,
          stepSourceVersion: migration.sourceVersion,
          stepTargetVersion: migration.targetVersion,
        );
      }

      if (migration.sourceVersion != expectedVersion) {
        throw AppEventSchemaMigrationException(
          message: 'Migration steps must form a continuous version path.',
          eventType: eventType,
          sourceVersion: sourceVersion,
          targetVersion: targetVersion,
          stage: AppEventSchemaMigrationStage.pathResolution,
          stepSourceVersion: migration.sourceVersion,
          stepTargetVersion: migration.targetVersion,
        );
      }

      if (migration.sourceVersion <= 0 ||
          migration.targetVersion <= 0 ||
          migration.sourceVersion == migration.targetVersion) {
        throw AppEventSchemaMigrationException(
          message: 'A migration step contains invalid version numbers.',
          eventType: eventType,
          sourceVersion: sourceVersion,
          targetVersion: targetVersion,
          stage: AppEventSchemaMigrationStage.pathResolution,
          stepSourceVersion: migration.sourceVersion,
          stepTargetVersion: migration.targetVersion,
        );
      }

      expectedVersion = migration.targetVersion;
    }

    if (expectedVersion != targetVersion) {
      throw AppEventSchemaMigrationException(
        message: 'The final migration step does not match the target version.',
        eventType: eventType,
        sourceVersion: sourceVersion,
        targetVersion: targetVersion,
        stage: AppEventSchemaMigrationStage.pathResolution,
      );
    }
  }

  void _validatePayload({
    required String eventType,
    required int version,
    required Map<String, Object?> payload,
    required AppEventSchemaMigrationStage stage,
    required int sourceVersion,
    required int targetVersion,
    int? stepSourceVersion,
    int? stepTargetVersion,
  }) {
    bool isValid;

    try {
      isValid = _validationCallback(
        validator: _validator,
        eventType: eventType,
        version: version,
        payload: _deepFreezeMap(payload),
      );
    } catch (error) {
      throw AppEventSchemaMigrationException(
        message: 'Schema validation could not be completed.',
        eventType: eventType,
        sourceVersion: sourceVersion,
        targetVersion: targetVersion,
        stage: stage,
        stepSourceVersion: stepSourceVersion,
        stepTargetVersion: stepTargetVersion,
        cause: error,
      );
    }

    if (!isValid) {
      throw AppEventSchemaMigrationException(
        message: 'The payload does not satisfy its schema definition.',
        eventType: eventType,
        sourceVersion: sourceVersion,
        targetVersion: targetVersion,
        stage: stage,
        stepSourceVersion: stepSourceVersion,
        stepTargetVersion: stepTargetVersion,
      );
    }
  }

  void _validateRequest({
    required String eventType,
    required int sourceVersion,
    required int targetVersion,
  }) {
    if (eventType.trim().isEmpty) {
      throw ArgumentError.value(
        eventType,
        'eventType',
        'Event type must not be empty.',
      );
    }

    if (sourceVersion <= 0) {
      throw ArgumentError.value(
        sourceVersion,
        'sourceVersion',
        'Source version must be greater than zero.',
      );
    }

    if (targetVersion <= 0) {
      throw ArgumentError.value(
        targetVersion,
        'targetVersion',
        'Target version must be greater than zero.',
      );
    }
  }
}

Map<String, Object?> _deepCopyMap(Map<String, Object?> source) {
  final copied = <String, Object?>{};

  for (final entry in source.entries) {
    copied[entry.key] = _deepCopyValue(entry.value);
  }

  return copied;
}

Object? _deepCopyValue(Object? value) {
  if (value == null ||
      value is String ||
      value is bool ||
      value is int ||
      value is double) {
    return value;
  }

  if (value is List) {
    return value.map<Object?>(_deepCopyValue).toList(growable: true);
  }

  if (value is Map) {
    final copied = <String, Object?>{};

    for (final entry in value.entries) {
      if (entry.key is! String) {
        throw const FormatException(
          'Schema migration payload maps must use string keys.',
        );
      }

      copied[entry.key as String] = _deepCopyValue(entry.value);
    }

    return copied;
  }

  throw FormatException(
    'Unsupported value type in schema migration payload: '
    '${value.runtimeType}.',
  );
}

Map<String, Object?> _deepFreezeMap(Map<String, Object?> source) {
  final frozen = <String, Object?>{};

  for (final entry in source.entries) {
    frozen[entry.key] = _deepFreezeValue(entry.value);
  }

  return UnmodifiableMapView<String, Object?>(frozen);
}

Object? _deepFreezeValue(Object? value) {
  if (value == null ||
      value is String ||
      value is bool ||
      value is int ||
      value is double) {
    return value;
  }

  if (value is List) {
    return List<Object?>.unmodifiable(
      value.map<Object?>(_deepFreezeValue),
    );
  }

  if (value is Map) {
    final frozen = <String, Object?>{};

    for (final entry in value.entries) {
      if (entry.key is! String) {
        throw const FormatException(
          'Schema migration payload maps must use string keys.',
        );
      }

      frozen[entry.key as String] = _deepFreezeValue(entry.value);
    }

    return UnmodifiableMapView<String, Object?>(frozen);
  }

  throw FormatException(
    'Unsupported value type in schema migration payload: '
    '${value.runtimeType}.',
  );
}
