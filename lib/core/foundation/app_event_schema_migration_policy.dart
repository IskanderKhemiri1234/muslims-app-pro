
import 'dart:collection';

import 'app_event_schema_registry.dart';

enum AppEventSchemaMigrationDirection {
  upgrade,
  downgrade,
  sameVersion,
}

enum AppEventSchemaMigrationPolicyCode {
  allowed,
  invalidEventType,
  invalidSourceVersion,
  invalidTargetVersion,
  sameVersionNotAllowed,
  upgradeNotAllowed,
  downgradeNotAllowed,
  eventTypeNotAllowed,
  eventTypeBlocked,
  sourceVersionNotRegistered,
  targetVersionNotRegistered,
  sourceVersionBlocked,
  targetVersionBlocked,
  compatibilityNotSufficient,
  directionNotAllowed,
}

final class AppEventSchemaMigrationPolicyDecision {
  AppEventSchemaMigrationPolicyDecision({
    required this.isAllowed,
    required this.code,
    required this.direction,
    required this.eventType,
    required this.sourceVersion,
    required this.targetVersion,
    required this.compatibility,
    required List<String> reasons,
  }) : reasons = List<String>.unmodifiable(reasons);

  final bool isAllowed;
  final AppEventSchemaMigrationPolicyCode code;
  final AppEventSchemaMigrationDirection direction;
  final String eventType;
  final int sourceVersion;
  final int targetVersion;
  final AppEventSchemaCompatibility compatibility;
  final List<String> reasons;

  bool get isRejected => !isAllowed;
}

final class AppEventSchemaMigrationPolicy {
  AppEventSchemaMigrationPolicy({
    required AppEventSchemaRegistry registry,
    Set<AppEventSchemaMigrationDirection> allowedDirections =
        const {
          AppEventSchemaMigrationDirection.upgrade,
          AppEventSchemaMigrationDirection.downgrade,
          AppEventSchemaMigrationDirection.sameVersion,
        },
    Set<String> allowedEventTypes = const {},
    Set<String> blockedEventTypes = const {},
    Map<String, Set<int>> blockedVersions = const {},
    bool allowSameVersion = true,
    bool allowUpgrades = true,
    bool allowDowngrades = false,
    bool requireRegisteredSourceVersion = true,
    bool requireRegisteredTargetVersion = true,
  })  : _registry = registry,
        allowedDirections =
            Set<AppEventSchemaMigrationDirection>.unmodifiable(
          allowedDirections,
        ),
        allowedEventTypes = Set<String>.unmodifiable(
          allowedEventTypes.map((value) => value.trim()).where(
                (value) => value.isNotEmpty,
              ),
        ),
        blockedEventTypes = Set<String>.unmodifiable(
          blockedEventTypes.map((value) => value.trim()).where(
                (value) => value.isNotEmpty,
              ),
        ),
        blockedVersions = UnmodifiableMapView<String, Set<int>>(
          blockedVersions.map(
            (eventType, versions) => MapEntry(
              eventType.trim(),
              Set<int>.unmodifiable(versions),
            ),
          ),
        ),
        allowSameVersion = allowSameVersion,
        allowUpgrades = allowUpgrades,
        allowDowngrades = allowDowngrades,
        requireRegisteredSourceVersion = requireRegisteredSourceVersion,
        requireRegisteredTargetVersion = requireRegisteredTargetVersion;

  final AppEventSchemaRegistry _registry;

  final Set<AppEventSchemaMigrationDirection> allowedDirections;
  final Set<String> allowedEventTypes;
  final Set<String> blockedEventTypes;
  final Map<String, Set<int>> blockedVersions;

  final bool allowSameVersion;
  final bool allowUpgrades;
  final bool allowDowngrades;
  final bool requireRegisteredSourceVersion;
  final bool requireRegisteredTargetVersion;

  AppEventSchemaMigrationPolicyDecision evaluate({
    required String eventType,
    required int sourceVersion,
    required int targetVersion,
    required AppEventSchemaCompatibility compatibility,
  }) {
    final normalizedEventType = eventType.trim();
    final direction = _resolveDirection(
      sourceVersion: sourceVersion,
      targetVersion: targetVersion,
    );

    AppEventSchemaMigrationPolicyDecision reject(
      AppEventSchemaMigrationPolicyCode code,
      String reason,
    ) {
      return AppEventSchemaMigrationPolicyDecision(
        isAllowed: false,
        code: code,
        direction: direction,
        eventType: normalizedEventType,
        sourceVersion: sourceVersion,
        targetVersion: targetVersion,
        compatibility: compatibility,
        reasons: [reason],
      );
    }

    if (normalizedEventType.isEmpty) {
      return reject(
        AppEventSchemaMigrationPolicyCode.invalidEventType,
        'The event type must not be empty.',
      );
    }

    if (sourceVersion <= 0) {
      return reject(
        AppEventSchemaMigrationPolicyCode.invalidSourceVersion,
        'The source schema version must be greater than zero.',
      );
    }

    if (targetVersion <= 0) {
      return reject(
        AppEventSchemaMigrationPolicyCode.invalidTargetVersion,
        'The target schema version must be greater than zero.',
      );
    }

    if (blockedEventTypes.contains(normalizedEventType)) {
      return reject(
        AppEventSchemaMigrationPolicyCode.eventTypeBlocked,
        'Migration is blocked for this event type.',
      );
    }

    if (allowedEventTypes.isNotEmpty &&
        !allowedEventTypes.contains(normalizedEventType)) {
      return reject(
        AppEventSchemaMigrationPolicyCode.eventTypeNotAllowed,
        'The event type is not included in the migration allowlist.',
      );
    }

    if (!_isVersionAllowed(
      eventType: normalizedEventType,
      version: sourceVersion,
    )) {
      return reject(
        AppEventSchemaMigrationPolicyCode.sourceVersionBlocked,
        'The source schema version is explicitly blocked.',
      );
    }

    if (!_isVersionAllowed(
      eventType: normalizedEventType,
      version: targetVersion,
    )) {
      return reject(
        AppEventSchemaMigrationPolicyCode.targetVersionBlocked,
        'The target schema version is explicitly blocked.',
      );
    }

    if (direction == AppEventSchemaMigrationDirection.sameVersion) {
      if (!allowSameVersion) {
        return reject(
          AppEventSchemaMigrationPolicyCode.sameVersionNotAllowed,
          'Same-version operations are disabled by policy.',
        );
      }

      if (!allowedDirections.contains(direction)) {
        return reject(
          AppEventSchemaMigrationPolicyCode.directionNotAllowed,
          'Same-version operations are not included in allowed directions.',
        );
      }
    }

    if (direction == AppEventSchemaMigrationDirection.upgrade) {
      if (!allowUpgrades) {
        return reject(
          AppEventSchemaMigrationPolicyCode.upgradeNotAllowed,
          'Schema upgrades are disabled by policy.',
        );
      }

      if (!allowedDirections.contains(direction)) {
        return reject(
          AppEventSchemaMigrationPolicyCode.directionNotAllowed,
          'Upgrade direction is not included in allowed directions.',
        );
      }

      if (!_supportsUpgrade(compatibility)) {
        return reject(
          AppEventSchemaMigrationPolicyCode.compatibilityNotSufficient,
          'The declared compatibility does not permit this upgrade direction.',
        );
      }
    }

    if (direction == AppEventSchemaMigrationDirection.downgrade) {
      if (!allowDowngrades) {
        return reject(
          AppEventSchemaMigrationPolicyCode.downgradeNotAllowed,
          'Schema downgrades are disabled by policy.',
        );
      }

      if (!allowedDirections.contains(direction)) {
        return reject(
          AppEventSchemaMigrationPolicyCode.directionNotAllowed,
          'Downgrade direction is not included in allowed directions.',
        );
      }

      if (!_supportsDowngrade(compatibility)) {
        return reject(
          AppEventSchemaMigrationPolicyCode.compatibilityNotSufficient,
          'The declared compatibility does not permit this downgrade direction.',
        );
      }
    }

    if (requireRegisteredSourceVersion &&
        !_registry.supportsVersion(normalizedEventType, sourceVersion)) {
      return reject(
        AppEventSchemaMigrationPolicyCode.sourceVersionNotRegistered,
        'The source schema version is not registered.',
      );
    }

    if (requireRegisteredTargetVersion &&
        !_registry.supportsVersion(normalizedEventType, targetVersion)) {
      return reject(
        AppEventSchemaMigrationPolicyCode.targetVersionNotRegistered,
        'The target schema version is not registered.',
      );
    }

    return AppEventSchemaMigrationPolicyDecision(
      isAllowed: true,
      code: AppEventSchemaMigrationPolicyCode.allowed,
      direction: direction,
      eventType: normalizedEventType,
      sourceVersion: sourceVersion,
      targetVersion: targetVersion,
      compatibility: compatibility,
      reasons: const [
        'The requested schema migration is permitted by policy.',
      ],
    );
  }

  bool _isVersionAllowed({
    required String eventType,
    required int version,
  }) {
    return !(blockedVersions[eventType]?.contains(version) ?? false);
  }

  AppEventSchemaMigrationDirection _resolveDirection({
    required int sourceVersion,
    required int targetVersion,
  }) {
    if (sourceVersion == targetVersion) {
      return AppEventSchemaMigrationDirection.sameVersion;
    }

    if (targetVersion > sourceVersion) {
      return AppEventSchemaMigrationDirection.upgrade;
    }

    return AppEventSchemaMigrationDirection.downgrade;
  }

  bool _supportsUpgrade(AppEventSchemaCompatibility compatibility) {
    return compatibility == AppEventSchemaCompatibility.backward ||
        compatibility == AppEventSchemaCompatibility.full;
  }

  bool _supportsDowngrade(AppEventSchemaCompatibility compatibility) {
    return compatibility == AppEventSchemaCompatibility.forward ||
        compatibility == AppEventSchemaCompatibility.full;
  }
}
