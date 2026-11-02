
import 'dart:collection';

import 'app_event_schema_migration_policy.dart';
import 'app_event_schema_registry.dart';

typedef AppEventSchemaMigrationGuardPathResolver = List<AppEventSchemaMigration>
    Function({
  required AppEventSchemaRegistry registry,
  required String eventType,
  required int sourceVersion,
  required int targetVersion,
});

enum AppEventSchemaMigrationGuardStatus {
  authorized,
  rejected,
}

enum AppEventSchemaMigrationGuardCode {
  authorized,
  invalidRequest,
  sourceSchemaNotFound,
  targetSchemaNotFound,
  policyRejected,
  migrationPathNotFound,
  migrationPathInvalid,
  migrationPathDoesNotReachTarget,
}

final class AppEventSchemaMigrationPermit {
  AppEventSchemaMigrationPermit._({
    required this.eventType,
    required this.sourceVersion,
    required this.targetVersion,
    required this.compatibility,
    required this.policyDecision,
    required List<AppEventSchemaMigration> migrationPath,
  }) : migrationPath =
            List<AppEventSchemaMigration>.unmodifiable(migrationPath);

  final String eventType;
  final int sourceVersion;
  final int targetVersion;
  final AppEventSchemaCompatibility compatibility;
  final AppEventSchemaMigrationPolicyDecision policyDecision;
  final List<AppEventSchemaMigration> migrationPath;

  bool get requiresMigration => sourceVersion != targetVersion;

  int get migrationStepCount => migrationPath.length;
}

final class AppEventSchemaMigrationGuardResult {
  AppEventSchemaMigrationGuardResult._({
    required this.status,
    required this.code,
    required this.eventType,
    required this.sourceVersion,
    required this.targetVersion,
    required List<String> reasons,
    this.permit,
    this.policyDecision,
  }) : reasons = List<String>.unmodifiable(reasons);

  final AppEventSchemaMigrationGuardStatus status;
  final AppEventSchemaMigrationGuardCode code;
  final String eventType;
  final int sourceVersion;
  final int targetVersion;
  final List<String> reasons;
  final AppEventSchemaMigrationPermit? permit;
  final AppEventSchemaMigrationPolicyDecision? policyDecision;

  bool get isAuthorized =>
      status == AppEventSchemaMigrationGuardStatus.authorized;

  bool get isRejected =>
      status == AppEventSchemaMigrationGuardStatus.rejected;
}

final class AppEventSchemaMigrationGuard {
  AppEventSchemaMigrationGuard({
    required AppEventSchemaRegistry registry,
    required AppEventSchemaMigrationPolicy policy,
    required AppEventSchemaMigrationGuardPathResolver pathResolver,
  })  : _registry = registry,
        _policy = policy,
        _pathResolver = pathResolver;

  final AppEventSchemaRegistry _registry;
  final AppEventSchemaMigrationPolicy _policy;
  final AppEventSchemaMigrationGuardPathResolver _pathResolver;

  AppEventSchemaMigrationGuardResult authorize({
    required String eventType,
    required int sourceVersion,
    required int targetVersion,
  }) {
    final normalizedEventType = eventType.trim();

    AppEventSchemaMigrationGuardResult reject(
      AppEventSchemaMigrationGuardCode code,
      String reason, {
      AppEventSchemaMigrationPolicyDecision? policyDecision,
    }) {
      return AppEventSchemaMigrationGuardResult._(
        status: AppEventSchemaMigrationGuardStatus.rejected,
        code: code,
        eventType: normalizedEventType,
        sourceVersion: sourceVersion,
        targetVersion: targetVersion,
        reasons: [reason],
        policyDecision: policyDecision,
      );
    }

    if (normalizedEventType.isEmpty ||
        sourceVersion <= 0 ||
        targetVersion <= 0) {
      return reject(
        AppEventSchemaMigrationGuardCode.invalidRequest,
        'The event type and schema versions must be valid.',
      );
    }

    final sourceDefinition = _registry.findDefinition(
      normalizedEventType,
      sourceVersion,
    );

    if (sourceDefinition == null) {
      return reject(
        AppEventSchemaMigrationGuardCode.sourceSchemaNotFound,
        'The requested source schema is not registered.',
      );
    }

    final targetDefinition = _registry.findDefinition(
      normalizedEventType,
      targetVersion,
    );

    if (targetDefinition == null) {
      return reject(
        AppEventSchemaMigrationGuardCode.targetSchemaNotFound,
        'The requested target schema is not registered.',
      );
    }

    final compatibility = targetDefinition.compatibility;

    final policyDecision = _policy.evaluate(
      eventType: normalizedEventType,
      sourceVersion: sourceVersion,
      targetVersion: targetVersion,
      compatibility: compatibility,
    );

    if (!policyDecision.isAllowed) {
      return reject(
        AppEventSchemaMigrationGuardCode.policyRejected,
        'The migration request was rejected by the migration policy.',
        policyDecision: policyDecision,
      );
    }

    final migrationPathResult = _resolvePath(
      eventType: normalizedEventType,
      sourceVersion: sourceVersion,
      targetVersion: targetVersion,
    );

    if (migrationPathResult == null) {
      return reject(
        AppEventSchemaMigrationGuardCode.migrationPathNotFound,
        'No valid migration path is available for the requested versions.',
        policyDecision: policyDecision,
      );
    }

    final pathValidation = _validatePath(
      migrationPath: migrationPathResult,
      eventType: normalizedEventType,
      sourceVersion: sourceVersion,
      targetVersion: targetVersion,
    );

    if (pathValidation != null) {
      return reject(
        pathValidation.code,
        pathValidation.reason,
        policyDecision: policyDecision,
      );
    }

    final permit = AppEventSchemaMigrationPermit._(
      eventType: normalizedEventType,
      sourceVersion: sourceVersion,
      targetVersion: targetVersion,
      compatibility: compatibility,
      policyDecision: policyDecision,
      migrationPath: migrationPathResult,
    );

    return AppEventSchemaMigrationGuardResult._(
      status: AppEventSchemaMigrationGuardStatus.authorized,
      code: AppEventSchemaMigrationGuardCode.authorized,
      eventType: normalizedEventType,
      sourceVersion: sourceVersion,
      targetVersion: targetVersion,
      reasons: const [
        'The request passed schema registration, policy, and path checks.',
      ],
      permit: permit,
      policyDecision: policyDecision,
    );
  }

  List<AppEventSchemaMigration>? _resolvePath({
    required String eventType,
    required int sourceVersion,
    required int targetVersion,
  }) {
    if (sourceVersion == targetVersion) {
      return const [];
    }

    try {
      final path = _pathResolver(
        registry: _registry,
        eventType: eventType,
        sourceVersion: sourceVersion,
        targetVersion: targetVersion,
      );

      return List<AppEventSchemaMigration>.unmodifiable(path);
    } catch (_) {
      return null;
    }
  }

  _PathValidationFailure? _validatePath({
    required List<AppEventSchemaMigration> migrationPath,
    required String eventType,
    required int sourceVersion,
    required int targetVersion,
  }) {
    if (sourceVersion == targetVersion) {
      if (migrationPath.isNotEmpty) {
        return const _PathValidationFailure(
          code: AppEventSchemaMigrationGuardCode.migrationPathInvalid,
          reason: 'A same-version request must not contain migration steps.',
        );
      }

      return null;
    }

    if (migrationPath.isEmpty) {
      return const _PathValidationFailure(
        code: AppEventSchemaMigrationGuardCode.migrationPathNotFound,
        reason: 'The migration path contains no steps.',
      );
    }

    var expectedVersion = sourceVersion;

    for (final migration in migrationPath) {
      if (migration.eventType != eventType) {
        return const _PathValidationFailure(
          code: AppEventSchemaMigrationGuardCode.migrationPathInvalid,
          reason: 'A migration step belongs to another event type.',
        );
      }

      if (migration.sourceVersion != expectedVersion) {
        return const _PathValidationFailure(
          code: AppEventSchemaMigrationGuardCode.migrationPathInvalid,
          reason: 'The migration path contains a version discontinuity.',
        );
      }

      if (migration.sourceVersion <= 0 ||
          migration.targetVersion <= 0 ||
          migration.sourceVersion == migration.targetVersion) {
        return const _PathValidationFailure(
          code: AppEventSchemaMigrationGuardCode.migrationPathInvalid,
          reason: 'A migration step contains invalid version numbers.',
        );
      }

      final isUpgrade = targetVersion > sourceVersion;
      final stepMovesForward =
          migration.targetVersion > migration.sourceVersion;

      if (isUpgrade != stepMovesForward) {
        return const _PathValidationFailure(
          code: AppEventSchemaMigrationGuardCode.migrationPathInvalid,
          reason: 'A migration step moves in the wrong direction.',
        );
      }

      expectedVersion = migration.targetVersion;
    }

    if (expectedVersion != targetVersion) {
      return const _PathValidationFailure(
        code: AppEventSchemaMigrationGuardCode
            .migrationPathDoesNotReachTarget,
        reason: 'The migration path does not reach the requested target.',
      );
    }

    return null;
  }
}

final class _PathValidationFailure {
  const _PathValidationFailure({
    required this.code,
    required this.reason,
  });

  final AppEventSchemaMigrationGuardCode code;
  final String reason;
}
