
/// Describes the compatibility policy between two schema versions.
enum AppEventSchemaCompatibility {
  /// Both newer and older data can be read across the versions.
  full,

  /// Newer data can be read by the older schema.
  backward,

  /// Older data can be read by the newer schema.
  forward,

  /// Only data using the exact same schema version is compatible.
  none,
}

/// Describes the result of a schema compatibility check.
enum AppEventSchemaCompatibilityStatus {
  compatible,
  incompatible,
  unknownSchema,
  unsupportedVersion,
}

/// Describes the direction of a schema migration.
enum AppEventSchemaMigrationDirection {
  upgrade,
  downgrade,
}

/// Immutable definition of an event schema version.
final class AppEventSchemaDefinition {
  AppEventSchemaDefinition({
    required this.eventType,
    required this.version,
    required this.schemaName,
    required this.compatibility,
    Iterable<String> requiredFields = const [],
    Iterable<String> optionalFields = const [],
    Map<String, String> fieldTypes = const {},
    Map<String, Object?> defaultValues = const {},
  })  : requiredFields = _immutableFieldSet(
          requiredFields,
          'requiredFields',
        ),
        optionalFields = _immutableFieldSet(
          optionalFields,
          'optionalFields',
        ),
        fieldTypes = _immutableStringMap(fieldTypes),
        defaultValues = _immutableValueMap(defaultValues) {
    _validateEventType(eventType);
    _validateVersion(version);
    _validateSchemaName(schemaName);
    _validateFieldDefinitions(
      this.requiredFields,
      this.optionalFields,
      this.fieldTypes,
      this.defaultValues,
    );
  }

  final String eventType;
  final int version;
  final String schemaName;
  final AppEventSchemaCompatibility compatibility;

  final Set<String> requiredFields;
  final Set<String> optionalFields;

  /// Maps field names to logical type identifiers.
  ///
  /// Supported identifiers are:
  /// string, integer, number, boolean, object, array, and null.
  final Map<String, String> fieldTypes;

  /// Default values used by migration operations when explicitly requested.
  final Map<String, Object?> defaultValues;

  static const Set<String> supportedFieldTypes = {
    'string',
    'integer',
    'number',
    'boolean',
    'object',
    'array',
    'null',
  };

  static void _validateEventType(String value) {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(
        value,
        'eventType',
        'Event type cannot be empty.',
      );
    }
  }

  static void _validateVersion(int value) {
    if (value < 1) {
      throw ArgumentError.value(
        value,
        'version',
        'Schema version must be greater than zero.',
      );
    }
  }

  static void _validateSchemaName(String value) {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(
        value,
        'schemaName',
        'Schema name cannot be empty.',
      );
    }
  }

  static Set<String> _immutableFieldSet(
    Iterable<String> values,
    String parameterName,
  ) {
    final result = <String>{};

    for (final value in values) {
      final normalized = value.trim();

      if (normalized.isEmpty) {
        throw ArgumentError.value(
          value,
          parameterName,
          'Field names cannot be empty.',
        );
      }

      if (!result.add(normalized)) {
        throw ArgumentError.value(
          value,
          parameterName,
          'Duplicate field names are not allowed.',
        );
      }
    }

    return Set<String>.unmodifiable(result);
  }

  static Map<String, String> _immutableStringMap(
    Map<String, String> source,
  ) {
    final result = <String, String>{};

    for (final entry in source.entries) {
      final key = entry.key.trim();
      final value = entry.value.trim();

      if (key.isEmpty || value.isEmpty) {
        throw ArgumentError(
          'Field type keys and values cannot be empty.',
        );
      }

      if (!supportedFieldTypes.contains(value)) {
        throw ArgumentError.value(
          value,
          'fieldTypes',
          'Unsupported schema field type.',
        );
      }

      result[key] = value;
    }

    return Map<String, String>.unmodifiable(result);
  }

  static Map<String, Object?> _immutableValueMap(
    Map<String, Object?> source,
  ) {
    final result = <String, Object?>{};

    for (final entry in source.entries) {
      final key = entry.key.trim();

      if (key.isEmpty) {
        throw ArgumentError(
          'Default value field names cannot be empty.',
        );
      }

      result[key] = _freezeValue(entry.value);
    }

    return Map<String, Object?>.unmodifiable(result);
  }

  static Object? _freezeValue(Object? value) {
    if (value == null || value is String || value is bool || value is num) {
      return value;
    }

    if (value is List) {
      return List<Object?>.unmodifiable(
        value.map(_freezeValue),
      );
    }

    if (value is Map) {
      final result = <String, Object?>{};

      for (final entry in value.entries) {
        if (entry.key is! String) {
          throw ArgumentError(
            'Default value object keys must be strings.',
          );
        }

        result[entry.key as String] = _freezeValue(entry.value);
      }

      return Map<String, Object?>.unmodifiable(result);
    }

    throw ArgumentError.value(
      value,
      'defaultValues',
      'Default values must contain JSON-compatible data.',
    );
  }

  static void _validateFieldDefinitions(
    Set<String> requiredFields,
    Set<String> optionalFields,
    Map<String, String> fieldTypes,
    Map<String, Object?> defaultValues,
  ) {
    final overlappingFields = requiredFields.intersection(optionalFields);

    if (overlappingFields.isNotEmpty) {
      throw ArgumentError(
        'A field cannot be both required and optional: '
        '${overlappingFields.join(', ')}',
      );
    }

    final declaredFields = {
      ...requiredFields,
      ...optionalFields,
    };

    for (final field in fieldTypes.keys) {
      if (!declaredFields.contains(field)) {
        throw ArgumentError(
          'A field type was defined for an undeclared field: $field',
        );
      }
    }

    for (final field in defaultValues.keys) {
      if (!optionalFields.contains(field)) {
        throw ArgumentError(
          'Default values can only be assigned to optional fields: $field',
        );
      }
    }
  }
}

/// Result of validating data against a schema definition.
final class AppEventSchemaValidationResult {
  AppEventSchemaValidationResult({
    required this.isValid,
    required Iterable<String> errors,
  }) : errors = List<String>.unmodifiable(errors);

  final bool isValid;
  final List<String> errors;
}

/// Represents a compatibility assessment between schema versions.
final class AppEventSchemaCompatibilityResult {
  const AppEventSchemaCompatibilityResult({
    required this.status,
    required this.eventType,
    required this.sourceVersion,
    required this.targetVersion,
    this.reason,
  });

  final AppEventSchemaCompatibilityStatus status;
  final String eventType;
  final int sourceVersion;
  final int targetVersion;
  final String? reason;

  bool get isCompatible =>
      status == AppEventSchemaCompatibilityStatus.compatible;
}

/// Describes a migration from one schema version to another.
abstract interface class AppEventSchemaMigration {
  String get eventType;

  int get sourceVersion;

  int get targetVersion;

  /// Converts an event payload from the source version to the target version.
  Map<String, Object?> migrate(Map<String, Object?> payload);
}

/// Immutable result of a successful schema migration.
final class AppEventSchemaMigrationResult {
  AppEventSchemaMigrationResult({
    required this.eventType,
    required this.sourceVersion,
    required this.targetVersion,
    required Map<String, Object?> payload,
  }) : payload = Map<String, Object?>.unmodifiable(payload);

  final String eventType;
  final int sourceVersion;
  final int targetVersion;
  final Map<String, Object?> payload;
}

/// Registry responsible for event schema definitions and migrations.
///
/// This registry does not serialize events, deserialize event objects,
/// publish events, or access persistent storage.
final class AppEventSchemaRegistry {
  AppEventSchemaRegistry({
    Iterable<AppEventSchemaDefinition> definitions = const [],
    Iterable<AppEventSchemaMigration> migrations = const [],
  }) {
    for (final definition in definitions) {
      registerDefinition(definition);
    }

    for (final migration in migrations) {
      registerMigration(migration);
    }
  }

  final Map<String, Map<int, AppEventSchemaDefinition>> _definitions = {};

  final Map<String, Map<int, AppEventSchemaMigration>> _migrations = {};

  /// Returns all registered event types.
  Set<String> get registeredEventTypes =>
      Set<String>.unmodifiable(_definitions.keys);

  /// Returns the number of registered schema definitions.
  int get definitionCount {
    return _definitions.values.fold<int>(
      0,
      (total, versions) => total + versions.length,
    );
  }

  /// Returns the number of registered migration operations.
  int get migrationCount {
    return _migrations.values.fold<int>(
      0,
      (total, versions) => total + versions.length,
    );
  }

  /// Registers a schema definition.
  ///
  /// Duplicate event type and version combinations are rejected.
  void registerDefinition(AppEventSchemaDefinition definition) {
    final versions = _definitions.putIfAbsent(
      definition.eventType,
      () => <int, AppEventSchemaDefinition>{},
    );

    if (versions.containsKey(definition.version)) {
      throw StateError(
        'Schema ${definition.eventType} version '
        '${definition.version} is already registered.',
      );
    }

    versions[definition.version] = definition;
  }

  /// Registers a migration between two different schema versions.
  ///
  /// Each source version can have only one direct migration for a given
  /// event type. The migration target must already be registered.
  void registerMigration(AppEventSchemaMigration migration) {
    _validateMigrationDeclaration(migration);

    final sourceDefinition = findDefinition(
      migration.eventType,
      migration.sourceVersion,
    );

    final targetDefinition = findDefinition(
      migration.eventType,
      migration.targetVersion,
    );

    if (sourceDefinition == null || targetDefinition == null) {
      throw StateError(
        'Both source and target schema definitions must be registered '
        'before registering a migration.',
      );
    }

    final migrations = _migrations.putIfAbsent(
      migration.eventType,
      () => <int, AppEventSchemaMigration>{},
    );

    if (migrations.containsKey(migration.sourceVersion)) {
      throw StateError(
        'A migration from ${migration.eventType} version '
        '${migration.sourceVersion} is already registered.',
      );
    }

    migrations[migration.sourceVersion] = migration;
  }

  /// Finds a schema definition for an event type and version.
  AppEventSchemaDefinition? findDefinition(
    String eventType,
    int version,
  ) {
    return _definitions[eventType]?[version];
  }

  /// Returns all registered versions of an event schema.
  List<int> registeredVersions(String eventType) {
    final versions = _definitions[eventType]?.keys.toList() ?? <int>[];

    versions.sort();

    return List<int>.unmodifiable(versions);
  }

  /// Returns the latest registered schema definition.
  AppEventSchemaDefinition? latestDefinition(String eventType) {
    final versions = registeredVersions(eventType);

    if (versions.isEmpty) {
      return null;
    }

    return findDefinition(
      eventType,
      versions.last,
    );
  }

  /// Checks whether an event type and schema version are registered.
  bool supportsVersion(
    String eventType,
    int version,
  ) {
    return findDefinition(eventType, version) != null;
  }

  /// Validates a payload against its registered schema definition.
  AppEventSchemaValidationResult validatePayload({
    required String eventType,
    required int version,
    required Map<String, Object?> payload,
  }) {
    final definition = findDefinition(eventType, version);

    if (definition == null) {
      return AppEventSchemaValidationResult(
        isValid: false,
        errors: [
          'No schema is registered for $eventType version $version.',
        ],
      );
    }

    final errors = <String>[];

    for (final field in definition.requiredFields) {
      if (!payload.containsKey(field)) {
        errors.add('Required field "$field" is missing.');
      }
    }

    final declaredFields = {
      ...definition.requiredFields,
      ...definition.optionalFields,
    };

    for (final field in payload.keys) {
      if (!declaredFields.contains(field)) {
        errors.add('Undeclared field "$field" was supplied.');
      }
    }

    for (final entry in definition.fieldTypes.entries) {
      if (!payload.containsKey(entry.key)) {
        continue;
      }

      if (!_matchesType(payload[entry.key], entry.value)) {
        errors.add(
          'Field "${entry.key}" does not match type '
          '"${entry.value}".',
        );
      }
    }

    return AppEventSchemaValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }

  /// Assesses compatibility between two registered schema versions.
  ///
  /// This is a declared compatibility policy, not a substitute for
  /// payload validation or an executable migration.
  AppEventSchemaCompatibilityResult checkCompatibility({
    required String eventType,
    required int sourceVersion,
    required int targetVersion,
  }) {
    final source = findDefinition(eventType, sourceVersion);
    final target = findDefinition(eventType, targetVersion);

    if (source == null || target == null) {
      return AppEventSchemaCompatibilityResult(
        status: AppEventSchemaCompatibilityStatus.unknownSchema,
        eventType: eventType,
        sourceVersion: sourceVersion,
        targetVersion: targetVersion,
        reason: 'Source or target schema is not registered.',
      );
    }

    if (sourceVersion == targetVersion) {
      return AppEventSchemaCompatibilityResult(
        status: AppEventSchemaCompatibilityStatus.compatible,
        eventType: eventType,
        sourceVersion: sourceVersion,
        targetVersion: targetVersion,
        reason: 'Both versions identify the same registered schema.',
      );
    }

    final sourcePolicy = source.compatibility;
    final targetPolicy = target.compatibility;

    final sourceCanReadTarget = _canRead(
      sourcePolicy,
      sourceVersion,
      targetVersion,
    );

    final targetCanReadSource = _canRead(
      targetPolicy,
      targetVersion,
      sourceVersion,
    );

    if (sourceCanReadTarget && targetCanReadSource) {
      return AppEventSchemaCompatibilityResult(
        status: AppEventSchemaCompatibilityStatus.compatible,
        eventType: eventType,
        sourceVersion: sourceVersion,
        targetVersion: targetVersion,
      );
    }

    return AppEventSchemaCompatibilityResult(
      status: AppEventSchemaCompatibilityStatus.incompatible,
      eventType: eventType,
      sourceVersion: sourceVersion,
      targetVersion: targetVersion,
      reason: 'The declared compatibility policies do not permit '
          'bidirectional compatibility.',
    );
  }

  /// Migrates a payload through a complete chain of registered migrations.
  ///
  /// The source and target schemas must both be registered. Every
  /// intermediate migration must exist and its output is validated
  /// against the next schema before continuing.
  AppEventSchemaMigrationResult migratePayload({
    required String eventType,
    required int sourceVersion,
    required int targetVersion,
    required Map<String, Object?> payload,
  }) {
    final sourceDefinition = findDefinition(
      eventType,
      sourceVersion,
    );

    final targetDefinition = findDefinition(
      eventType,
      targetVersion,
    );

    if (sourceDefinition == null || targetDefinition == null) {
      throw StateError(
        'Source and target schemas must be registered before migration.',
      );
    }

    final initialValidation = validatePayload(
      eventType: eventType,
      version: sourceVersion,
      payload: payload,
    );

    if (!initialValidation.isValid) {
      throw StateError(
        'Source payload is invalid: ${initialValidation.errors.join('; ')}',
      );
    }

    if (sourceVersion == targetVersion) {
      return AppEventSchemaMigrationResult(
        eventType: eventType,
        sourceVersion: sourceVersion,
        targetVersion: targetVersion,
        payload: payload,
      );
    }

    final direction = sourceVersion < targetVersion
        ? AppEventSchemaMigrationDirection.upgrade
        : AppEventSchemaMigrationDirection.downgrade;

    var currentVersion = sourceVersion;
    var currentPayload = Map<String, Object?>.from(payload);

    while (currentVersion != targetVersion) {
      final migration = _migrations[eventType]?[currentVersion];

      if (migration == null) {
        throw StateError(
          'Missing migration for $eventType version $currentVersion.',
        );
      }

      final nextVersion = migration.targetVersion;

      if (direction == AppEventSchemaMigrationDirection.upgrade &&
          nextVersion <= currentVersion) {
        throw StateError(
          'Upgrade migration must move to a higher schema version.',
        );
      }

      if (direction == AppEventSchemaMigrationDirection.downgrade &&
          nextVersion >= currentVersion) {
        throw StateError(
          'Downgrade migration must move to a lower schema version.',
        );
      }

      final nextPayload = migration.migrate(
        Map<String, Object?>.unmodifiable(currentPayload),
      );

      final validation = validatePayload(
        eventType: eventType,
        version: nextVersion,
        payload: nextPayload,
      );

      if (!validation.isValid) {
        throw StateError(
          'Migrated payload is invalid for version $nextVersion: '
          '${validation.errors.join('; ')}',
        );
      }

      currentPayload = Map<String, Object?>.from(nextPayload);
      currentVersion = nextVersion;
    }

    return AppEventSchemaMigrationResult(
      eventType: eventType,
      sourceVersion: sourceVersion,
      targetVersion: targetVersion,
      payload: currentPayload,
    );
  }

  void _validateMigrationDeclaration(
    AppEventSchemaMigration migration,
  ) {
    if (migration.eventType.trim().isEmpty) {
      throw ArgumentError(
        'Migration event type cannot be empty.',
      );
    }

    if (migration.sourceVersion < 1 || migration.targetVersion < 1) {
      throw ArgumentError(
        'Migration schema versions must be positive.',
      );
    }

    if (migration.sourceVersion == migration.targetVersion) {
      throw ArgumentError(
        'Source and target versions must be different.',
      );
    }
  }

  bool _matchesType(Object? value, String expectedType) {
    switch (expectedType) {
      case 'string':
        return value is String;
      case 'integer':
        return value is int;
      case 'number':
        return value is num && value.isFinite;
      case 'boolean':
        return value is bool;
      case 'object':
        return value is Map;
      case 'array':
        return value is List;
      case 'null':
        return value == null;
      default:
        return false;
    }
  }

  bool _canRead(
    AppEventSchemaCompatibility policy,
    int readerVersion,
    int dataVersion,
  ) {
    if (readerVersion == dataVersion) {
      return true;
    }

    switch (policy) {
      case AppEventSchemaCompatibility.full:
        return true;

      case AppEventSchemaCompatibility.backward:
        return dataVersion < readerVersion;

      case AppEventSchemaCompatibility.forward:
        return dataVersion > readerVersion;

      case AppEventSchemaCompatibility.none:
        return false;
    }
  }
}
