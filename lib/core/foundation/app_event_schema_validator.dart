
import 'app_event_schema_registry.dart';

/// Defines the supported structural data types.
enum AppSchemaValueType {
  string,
  integer,
  number,
  boolean,
  object,
  array,
  nullValue,

  /// No explicit type was declared by the registry.
  /// The field is still checked for presence and declaration.
  any,
}

/// Describes the validation severity of a schema violation.
enum AppSchemaViolationSeverity {
  warning,
  error,
}

/// Describes the category of a structural validation violation.
enum AppSchemaViolationCode {
  missingRequiredField,
  unknownField,
  invalidType,
  nullNotAllowed,
  valueBelowMinimum,
  valueAboveMaximum,
  stringTooShort,
  stringTooLong,
  invalidStringPattern,
  invalidStringFormat,
  invalidEnumValue,
  arrayTooShort,
  arrayTooLong,
  duplicateArrayItem,
  nestedObjectInvalid,
  invalidArrayItem,
  numericPrecisionExceeded,
  invalidConstraint,
}

/// Immutable description of one schema validation violation.
final class AppSchemaViolation {
  const AppSchemaViolation({
    required this.code,
    required this.path,
    required this.message,
    this.severity = AppSchemaViolationSeverity.error,
    this.expected,
    this.actual,
  });

  final AppSchemaViolationCode code;
  final String path;
  final String message;
  final AppSchemaViolationSeverity severity;
  final String? expected;
  final String? actual;

  bool get isError => severity == AppSchemaViolationSeverity.error;

  bool get isWarning => severity == AppSchemaViolationSeverity.warning;
}

/// Defines optional validation constraints for a schema field.
final class AppSchemaFieldConstraints {
  AppSchemaFieldConstraints({
    this.minimum,
    this.maximum,
    this.minimumLength,
    this.maximumLength,
    this.pattern,
    this.format,
    Iterable<Object?>? allowedValues,
    this.uniqueItems = false,
    this.minimumItems,
    this.maximumItems,
    this.maximumDecimalPlaces,
    this.allowNull = false,
  }) : allowedValues = allowedValues == null
            ? null
            : List<Object?>.unmodifiable(
                allowedValues.map(_freezeValue),
              ) {
    _validate();
  }

  final num? minimum;
  final num? maximum;
  final int? minimumLength;
  final int? maximumLength;
  final String? pattern;
  final String? format;
  final List<Object?>? allowedValues;
  final bool uniqueItems;
  final int? minimumItems;
  final int? maximumItems;
  final int? maximumDecimalPlaces;
  final bool allowNull;

  static Object? _freezeValue(Object? value) {
    if (value == null || value is String || value is bool) {
      return value;
    }

    if (value is num) {
      if (!value.isFinite) {
        throw ArgumentError.value(
          value,
          'allowedValues',
          'Numeric allowed values must be finite.',
        );
      }

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
            'Allowed object value keys must be strings.',
          );
        }

        result[entry.key as String] = _freezeValue(entry.value);
      }

      return Map<String, Object?>.unmodifiable(result);
    }

    throw ArgumentError.value(
      value,
      'allowedValues',
      'Allowed values must contain JSON-compatible data.',
    );
  }

  void _validate() {
    if (minimum != null && !minimum!.isFinite) {
      throw ArgumentError('Minimum numeric value must be finite.');
    }

    if (maximum != null && !maximum!.isFinite) {
      throw ArgumentError('Maximum numeric value must be finite.');
    }

    if (minimum != null && maximum != null && minimum! > maximum!) {
      throw ArgumentError(
        'Minimum numeric value cannot exceed maximum.',
      );
    }

    if (minimumLength != null && minimumLength! < 0) {
      throw ArgumentError(
        'Minimum string length cannot be negative.',
      );
    }

    if (maximumLength != null && maximumLength! < 0) {
      throw ArgumentError(
        'Maximum string length cannot be negative.',
      );
    }

    if (minimumLength != null &&
        maximumLength != null &&
        minimumLength! > maximumLength!) {
      throw ArgumentError(
        'Minimum string length cannot exceed maximum.',
      );
    }

    if (minimumItems != null && minimumItems! < 0) {
      throw ArgumentError(
        'Minimum array size cannot be negative.',
      );
    }

    if (maximumItems != null && maximumItems! < 0) {
      throw ArgumentError(
        'Maximum array size cannot be negative.',
      );
    }

    if (minimumItems != null &&
        maximumItems != null &&
        minimumItems! > maximumItems!) {
      throw ArgumentError(
        'Minimum array size cannot exceed maximum.',
      );
    }

    if (maximumDecimalPlaces != null &&
        maximumDecimalPlaces! < 0) {
      throw ArgumentError(
        'Maximum decimal places cannot be negative.',
      );
    }

    if (pattern != null) {
      try {
        RegExp(pattern!);
      } on FormatException catch (error) {
        throw ArgumentError(
          'Invalid regular expression pattern: $error',
        );
      }
    }

    if (format != null && format!.trim().isEmpty) {
      throw ArgumentError.value(
        format,
        'format',
        'String format cannot be empty.',
      );
    }
  }
}

/// Defines the structural contract of one schema field.
final class AppSchemaFieldDefinition {
  AppSchemaFieldDefinition({
    required this.type,
    this.required = false,
    this.description,
    this.constraints,
    Map<String, AppSchemaFieldDefinition> properties = const {},
    this.items,
    this.allowUnknownProperties = false,
  }) : properties = _immutableProperties(properties) {
    if (type != AppSchemaValueType.object && this.properties.isNotEmpty) {
      throw ArgumentError(
        'Properties can only be declared for object fields.',
      );
    }

    // An array without an item definition is allowed.
    // Its items have no declared nested structural constraints.

    if (type != AppSchemaValueType.array && items != null) {
      throw ArgumentError(
        'Array item definitions can only be declared for array fields.',
      );
    }

    if (description != null && description!.trim().isEmpty) {
      throw ArgumentError(
        'Field description cannot be empty.',
      );
    }
  }

  final AppSchemaValueType type;
  final bool required;
  final String? description;
  final AppSchemaFieldConstraints? constraints;
  final Map<String, AppSchemaFieldDefinition> properties;
  final AppSchemaFieldDefinition? items;
  final bool allowUnknownProperties;

  static Map<String, AppSchemaFieldDefinition> _immutableProperties(
    Map<String, AppSchemaFieldDefinition> source,
  ) {
    final result = <String, AppSchemaFieldDefinition>{};

    for (final entry in source.entries) {
      final key = entry.key.trim();

      if (key.isEmpty) {
        throw ArgumentError(
          'Nested property names cannot be empty.',
        );
      }

      if (result.containsKey(key)) {
        throw ArgumentError.value(
          key,
          'properties',
          'Duplicate property names after normalization.',
        );
      }

      result[key] = entry.value;
    }

    return Map<String, AppSchemaFieldDefinition>.unmodifiable(result);
  }
}

/// Describes the complete structural validation result.
final class AppEventSchemaValidationReport {
  AppEventSchemaValidationReport({
    required this.eventType,
    required this.schemaVersion,
    required Iterable<AppSchemaViolation> violations,
  }) : violations = List<AppSchemaViolation>.unmodifiable(
          violations,
        );

  final String eventType;
  final int schemaVersion;
  final List<AppSchemaViolation> violations;

  bool get isValid => !violations.any(
        (violation) => violation.isError,
      );

  bool get hasWarnings => violations.any(
        (violation) => violation.isWarning,
      );

  int get errorCount =>
      violations.where((violation) => violation.isError).length;

  int get warningCount =>
      violations.where((violation) => violation.isWarning).length;

  List<AppSchemaViolation> get errors =>
      List<AppSchemaViolation>.unmodifiable(
        violations.where((violation) => violation.isError),
      );

  List<AppSchemaViolation> get warnings =>
      List<AppSchemaViolation>.unmodifiable(
        violations.where((violation) => violation.isWarning),
      );
}

/// Performs advanced structural validation of registered event schemas.
final class AppEventSchemaValidator {
  AppEventSchemaValidator({
    required AppEventSchemaRegistry registry,
    this.maximumNestingDepth = 32,
  }) : _registry = registry {
    if (maximumNestingDepth < 1) {
      throw ArgumentError.value(
        maximumNestingDepth,
        'maximumNestingDepth',
        'Maximum nesting depth must be at least one.',
      );
    }
  }

  final AppEventSchemaRegistry _registry;
  final int maximumNestingDepth;

  /// Validates a payload against its registered event schema.
  ///
  /// This validator performs the complete validation pass.
  /// It intentionally does not call Registry.validatePayload(),
  /// which would duplicate required/unknown/type checks.
  ///
  /// Validation never mutates the supplied payload and never applies
  /// migration defaults automatically.
  AppEventSchemaValidationReport validate({
    required String eventType,
    required int schemaVersion,
    required Map<String, Object?> payload,
  }) {
    final violations = <AppSchemaViolation>[];

    final definition = _registry.findDefinition(
      eventType,
      schemaVersion,
    );

    if (definition == null) {
      violations.add(
        AppSchemaViolation(
          code: AppSchemaViolationCode.invalidConstraint,
          path: r'$',
          message: 'No registered schema exists for '
              '$eventType version $schemaVersion.',
        ),
      );

      return AppEventSchemaValidationReport(
        eventType: eventType,
        schemaVersion: schemaVersion,
        violations: violations,
      );
    }

    _validateObject(
      value: payload,
      properties: _buildRootProperties(definition),
      allowUnknownProperties: false,
      path: r'$',
      depth: 1,
      violations: violations,
    );

    return AppEventSchemaValidationReport(
      eventType: eventType,
      schemaVersion: schemaVersion,
      violations: _removeDuplicateViolations(violations),
    );
  }

  /// Builds the root field definitions from the Registry.
  ///
  /// Missing fieldTypes means "any declared value", not "object".
  /// Registry object fields have no nested property declarations,
  /// so their internal keys are not rejected at this layer.
  Map<String, AppSchemaFieldDefinition> _buildRootProperties(
    AppEventSchemaDefinition definition,
  ) {
    final properties = <String, AppSchemaFieldDefinition>{};

    for (final field in definition.requiredFields) {
      final type = _convertRegistryType(
        definition.fieldTypes[field],
      );

      properties[field] = AppSchemaFieldDefinition(
        type: type,
        required: true,
        allowUnknownProperties: type == AppSchemaValueType.object,
      );
    }

    for (final field in definition.optionalFields) {
      final type = _convertRegistryType(
        definition.fieldTypes[field],
      );

      properties[field] = AppSchemaFieldDefinition(
        type: type,
        required: false,
        allowUnknownProperties: type == AppSchemaValueType.object,
      );
    }

    return Map<String, AppSchemaFieldDefinition>.unmodifiable(
      properties,
    );
  }

  /// Converts Registry type identifiers without guessing unknown types.
  AppSchemaValueType _convertRegistryType(String? type) {
    switch (type) {
      case null:
        return AppSchemaValueType.any;

      case 'string':
        return AppSchemaValueType.string;

      case 'integer':
        return AppSchemaValueType.integer;

      case 'number':
        return AppSchemaValueType.number;

      case 'boolean':
        return AppSchemaValueType.boolean;

      case 'object':
        return AppSchemaValueType.object;

      case 'array':
        return AppSchemaValueType.array;

      case 'null':
        return AppSchemaValueType.nullValue;

      default:
        // The Registry should reject unknown identifiers.
        // Keep this defensive branch strict instead of converting
        // unknown identifiers into object.
        throw StateError(
          'Unsupported Registry field type "$type".',
        );
    }
  }

  void _validateObject({
    required Map<String, Object?> value,
    required Map<String, AppSchemaFieldDefinition> properties,
    required bool allowUnknownProperties,
    required String path,
    required int depth,
    required List<AppSchemaViolation> violations,
  }) {
    if (depth > maximumNestingDepth) {
      violations.add(
        AppSchemaViolation(
          code: AppSchemaViolationCode.nestedObjectInvalid,
          path: path,
          message: 'Maximum nesting depth exceeded.',
          expected: maximumNestingDepth.toString(),
          actual: depth.toString(),
        ),
      );

      return;
    }

    for (final entry in properties.entries) {
      final fieldName = entry.key;
      final fieldDefinition = entry.value;
      final fieldPath = '$path.$fieldName';

      if (!value.containsKey(fieldName)) {
        if (fieldDefinition.required) {
          violations.add(
            AppSchemaViolation(
              code: AppSchemaViolationCode.missingRequiredField,
              path: fieldPath,
              message: 'Required field is missing.',
            ),
          );
        }

        continue;
      }

      _validateValue(
        value: value[fieldName],
        definition: fieldDefinition,
        path: fieldPath,
        depth: depth + 1,
        violations: violations,
      );
    }

    if (!allowUnknownProperties) {
      for (final fieldName in value.keys) {
        if (!properties.containsKey(fieldName)) {
          violations.add(
            AppSchemaViolation(
              code: AppSchemaViolationCode.unknownField,
              path: '$path.$fieldName',
              message: 'Field is not declared in the schema.',
            ),
          );
        }
      }
    }
  }

  void _validateValue({
    required Object? value,
    required AppSchemaFieldDefinition definition,
    required String path,
    required int depth,
    required List<AppSchemaViolation> violations,
  }) {
    final constraints = definition.constraints;

    if (value == null) {
      if (definition.type != AppSchemaValueType.nullValue &&
          definition.type != AppSchemaValueType.any &&
          constraints?.allowNull != true) {
        violations.add(
          AppSchemaViolation(
            code: AppSchemaViolationCode.nullNotAllowed,
            path: path,
            message: 'Null is not allowed for this field.',
          ),
        );
      }

      if (definition.type == AppSchemaValueType.nullValue ||
          constraints?.allowNull == true) {
        if (constraints != null) {
          _validateConstraints(
            value: value,
            constraints: constraints,
            path: path,
            violations: violations,
          );
        }
      }

      return;
    }

    if (!_matchesType(value, definition.type)) {
      violations.add(
        AppSchemaViolation(
          code: AppSchemaViolationCode.invalidType,
          path: path,
          message: 'Value does not match the declared field type.',
          expected: definition.type.name,
          actual: value.runtimeType.toString(),
        ),
      );

      return;
    }

    if (constraints != null) {
      _validateConstraints(
        value: value,
        constraints: constraints,
        path: path,
        violations: violations,
      );
    }

    if (definition.type == AppSchemaValueType.object) {
      final objectValue = value as Map;

      if (objectValue.keys.any((key) => key is! String)) {
        violations.add(
          AppSchemaViolation(
            code: AppSchemaViolationCode.invalidType,
            path: path,
            message: 'Object keys must all be strings.',
            expected: 'Map<String, Object?>',
            actual: value.runtimeType.toString(),
          ),
        );

        return;
      }

      if (definition.properties.isNotEmpty ||
          !definition.allowUnknownProperties) {
        _validateObject(
          value: Map<String, Object?>.from(objectValue),
          properties: definition.properties,
          allowUnknownProperties: definition.allowUnknownProperties,
          path: path,
          depth: depth,
          violations: violations,
        );
      }
    }

    if (definition.type == AppSchemaValueType.array) {
      _validateArray(
        value: value as List,
        definition: definition,
        path: path,
        depth: depth,
        violations: violations,
      );
    }
  }

  void _validateConstraints({
    required Object? value,
    required AppSchemaFieldConstraints constraints,
    required String path,
    required List<AppSchemaViolation> violations,
  }) {
    if (constraints.allowedValues != null &&
        !constraints.allowedValues!.any(
          (allowed) => _deepEquals(value, allowed),
        )) {
      violations.add(
        AppSchemaViolation(
          code: AppSchemaViolationCode.invalidEnumValue,
          path: path,
          message: 'Value is not included in the allowed values.',
        ),
      );
    }

    if (value is num) {
      if (!value.isFinite) {
        violations.add(
          AppSchemaViolation(
            code: AppSchemaViolationCode.invalidType,
            path: path,
            message: 'Numeric values must be finite.',
          ),
        );

        return;
      }

      if (constraints.minimum != null &&
          value < constraints.minimum!) {
        violations.add(
          AppSchemaViolation(
            code: AppSchemaViolationCode.valueBelowMinimum,
            path: path,
            message: 'Numeric value is below the permitted minimum.',
            expected: constraints.minimum.toString(),
            actual: value.toString(),
          ),
        );
      }

      if (constraints.maximum != null &&
          value > constraints.maximum!) {
        violations.add(
          AppSchemaViolation(
            code: AppSchemaViolationCode.valueAboveMaximum,
            path: path,
            message: 'Numeric value exceeds the permitted maximum.',
            expected: constraints.maximum.toString(),
            actual: value.toString(),
          ),
        );
      }

      if (value is double &&
          constraints.maximumDecimalPlaces != null) {
        final decimalPlaces = _decimalPlaces(value);

        if (decimalPlaces > constraints.maximumDecimalPlaces!) {
          violations.add(
            AppSchemaViolation(
              code: AppSchemaViolationCode.numericPrecisionExceeded,
              path: path,
              message: 'Numeric value exceeds the permitted decimal precision.',
              expected: constraints.maximumDecimalPlaces.toString(),
              actual: decimalPlaces.toString(),
            ),
          );
        }
      }
    }

    if (value is String) {
      final length = value.runes.length;

      if (constraints.minimumLength != null &&
          length < constraints.minimumLength!) {
        violations.add(
          AppSchemaViolation(
            code: AppSchemaViolationCode.stringTooShort,
            path: path,
            message: 'String is shorter than the permitted length.',
            expected: constraints.minimumLength.toString(),
            actual: length.toString(),
          ),
        );
      }

      if (constraints.maximumLength != null &&
          length > constraints.maximumLength!) {
        violations.add(
          AppSchemaViolation(
            code: AppSchemaViolationCode.stringTooLong,
            path: path,
            message: 'String exceeds the permitted length.',
            expected: constraints.maximumLength.toString(),
            actual: length.toString(),
          ),
        );
      }

      if (constraints.pattern != null) {
        try {
          if (!RegExp(constraints.pattern!).hasMatch(value)) {
            violations.add(
              AppSchemaViolation(
                code: AppSchemaViolationCode.invalidStringPattern,
                path: path,
                message: 'String does not match the required pattern.',
              ),
            );
          }
        } on FormatException {
          violations.add(
            AppSchemaViolation(
              code: AppSchemaViolationCode.invalidConstraint,
              path: path,
              message: 'The configured regular expression is invalid.',
            ),
          );
        }
      }

      if (constraints.format != null &&
          !_matchesStringFormat(value, constraints.format!)) {
        violations.add(
          AppSchemaViolation(
            code: AppSchemaViolationCode.invalidStringFormat,
            path: path,
            message: 'String does not match the required format.',
            expected: constraints.format,
          ),
        );
      }
    }

    if (value is List) {
      if (constraints.minimumItems != null &&
          value.length < constraints.minimumItems!) {
        violations.add(
          AppSchemaViolation(
            code: AppSchemaViolationCode.arrayTooShort,
            path: path,
            message: 'Array contains fewer items than permitted.',
            expected: constraints.minimumItems.toString(),
            actual: value.length.toString(),
          ),
        );
      }

      if (constraints.maximumItems != null &&
          value.length > constraints.maximumItems!) {
        violations.add(
          AppSchemaViolation(
            code: AppSchemaViolationCode.arrayTooLong,
            path: path,
            message: 'Array contains more items than permitted.',
            expected: constraints.maximumItems.toString(),
            actual: value.length.toString(),
          ),
        );
      }

      if (constraints.uniqueItems && _containsDuplicates(value)) {
        violations.add(
          AppSchemaViolation(
            code: AppSchemaViolationCode.duplicateArrayItem,
            path: path,
            message: 'Array must not contain duplicate items.',
          ),
        );
      }
    }
  }

  void _validateArray({
    required List value,
    required AppSchemaFieldDefinition definition,
    required String path,
    required int depth,
    required List<AppSchemaViolation> violations,
  }) {
    final itemDefinition = definition.items;

    // Registry array fields do not carry nested item schemas.
    // In that case, array-level constraints still apply, but no
    // unsupported item type is guessed.
    if (itemDefinition == null) {
      return;
    }

    for (var index = 0; index < value.length; index++) {
      final itemPath = '$path[$index]';

      final beforeCount = violations.length;

      _validateValue(
        value: value[index],
        definition: itemDefinition,
        path: itemPath,
        depth: depth + 1,
        violations: violations,
      );

      if (violations.length > beforeCount &&
          itemDefinition.type == AppSchemaValueType.object) {
        violations.add(
          AppSchemaViolation(
            code: AppSchemaViolationCode.invalidArrayItem,
            path: itemPath,
            message: 'Array item does not satisfy its object definition.',
          ),
        );
      }
    }
  }

  bool _matchesType(
    Object value,
    AppSchemaValueType expected,
  ) {
    switch (expected) {
      case AppSchemaValueType.string:
        return value is String;

      case AppSchemaValueType.integer:
        return value is int;

      case AppSchemaValueType.number:
        return value is num && value.isFinite;

      case AppSchemaValueType.boolean:
        return value is bool;

      case AppSchemaValueType.object:
        return value is Map &&
            value.keys.every((key) => key is String);

      case AppSchemaValueType.array:
        return value is List;

      case AppSchemaValueType.nullValue:
        return false;

      case AppSchemaValueType.any:
        return true;
    }
  }

  bool _matchesStringFormat(
    String value,
    String format,
  ) {
    switch (format) {
      case 'email':
        return RegExp(
          r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
        ).hasMatch(value);

      case 'uri':
        final uri = Uri.tryParse(value);

        return uri != null &&
            uri.hasScheme &&
            uri.scheme.isNotEmpty;

      case 'date':
        return _isValidDate(value);

      case 'date-time':
        return _isValidDateTime(value);

      case 'uuid':
        return RegExp(
          r'^[0-9a-fA-F]{8}-'
          r'[0-9a-fA-F]{4}-'
          r'[1-8][0-9a-fA-F]{3}-'
          r'[89abAB][0-9a-fA-F]{3}-'
          r'[0-9a-fA-F]{12}$',
        ).hasMatch(value);

      default:
        return false;
    }
  }

  bool _isValidDate(String value) {
    final match = RegExp(
      r'^(\d{4})-(\d{2})-(\d{2})$',
    ).firstMatch(value);

    if (match == null) {
      return false;
    }

    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);

    if (month < 1 || month > 12 || day < 1) {
      return false;
    }

    final leapYear =
        year % 400 == 0 || (year % 4 == 0 && year % 100 != 0);

    final daysInMonth = switch (month) {
      1 || 3 || 5 || 7 || 8 || 10 || 12 => 31,
      4 || 6 || 9 || 11 => 30,
      2 => leapYear ? 29 : 28,
      _ => 0,
    };

    return day <= daysInMonth;
  }

  bool _isValidDateTime(String value) {
    final match = RegExp(
      r'^(\d{4}-\d{2}-\d{2})T'
      r'(\d{2}):(\d{2}):(\d{2})'
      r'(?:\.(\d+))?'
      r'(Z|([+-])(\d{2}):(\d{2}))?$',
    ).firstMatch(value);

    if (match == null || !_isValidDate(match.group(1)!)) {
      return false;
    }

    final hour = int.parse(match.group(2)!);
    final minute = int.parse(match.group(3)!);
    final second = int.parse(match.group(4)!);

    if (hour > 23 || minute > 59 || second > 59) {
      return false;
    }

    final offsetHour = match.group(9);
    final offsetMinute = match.group(10);

    if (offsetHour != null && offsetMinute != null) {
      final parsedOffsetHour = int.parse(offsetHour);
      final parsedOffsetMinute = int.parse(offsetMinute);

      if (parsedOffsetHour > 23 || parsedOffsetMinute > 59) {
        return false;
      }
    }

    return DateTime.tryParse(value) != null;
  }

  bool _containsDuplicates(List values) {
    for (var first = 0; first < values.length; first++) {
      for (var second = first + 1;
          second < values.length;
          second++) {
        if (_deepEquals(values[first], values[second])) {
          return true;
        }
      }
    }

    return false;
  }

  bool _deepEquals(Object? first, Object? second) {
    if (identical(first, second)) {
      return true;
    }

    if (first is num && second is num) {
      return first == second;
    }

    if (first is List && second is List) {
      if (first.length != second.length) {
        return false;
      }

      for (var index = 0; index < first.length; index++) {
        if (!_deepEquals(first[index], second[index])) {
          return false;
        }
      }

      return true;
    }

    if (first is Map && second is Map) {
      if (first.length != second.length) {
        return false;
      }

      for (final key in first.keys) {
        if (!second.containsKey(key) ||
            !_deepEquals(first[key], second[key])) {
          return false;
        }
      }

      return true;
    }

    return first == second;
  }

  int _decimalPlaces(double value) {
    final text = value.toString().toLowerCase();
    final exponentIndex = text.indexOf('e');

    final mantissa = exponentIndex == -1
        ? text
        : text.substring(0, exponentIndex);

    final decimalIndex = mantissa.indexOf('.');

    if (decimalIndex == -1) {
      return 0;
    }

    final exponent = exponentIndex == -1
        ? 0
        : int.parse(text.substring(exponentIndex + 1));

    final decimalCount = mantissa.length - decimalIndex - 1;

    return (decimalCount - exponent).clamp(0, 1000).toInt();
  }

  List<AppSchemaViolation> _removeDuplicateViolations(
    List<AppSchemaViolation> source,
  ) {
    final result = <AppSchemaViolation>[];
    final fingerprints = <String>{};

    for (final violation in source) {
      final fingerprint = [
        violation.code.name,
        violation.path,
        violation.message,
      ].join('|');

      if (fingerprints.add(fingerprint)) {
        result.add(violation);
      }
    }

    return result;
  }
}
