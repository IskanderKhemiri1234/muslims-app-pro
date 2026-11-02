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
    this.allowedValues,
    this.uniqueItems = false,
    this.minimumItems,
    this.maximumItems,
    this.maximumDecimalPlaces,
    this.allowNull = false,
  }) : allowedValues = allowedValues == null
            ? null
            : List<Object?>.unmodifiable(allowedValues) {
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

  void _validate() {
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
  }) : properties = Map<String, AppSchemaFieldDefinition>.unmodifiable(
          properties,
        ) {
    if (type != AppSchemaValueType.object && properties.isNotEmpty) {
      throw ArgumentError(
        'Properties can only be declared for object fields.',
      );
    }

    if (type != AppSchemaValueType.array && items != null) {
      throw ArgumentError(
        'Array item definitions can only be declared for array fields.',
      );
    }

    if (type == AppSchemaValueType.array && items == null) {
      throw ArgumentError(
        'Array fields must declare an item definition.',
      );
    }

    if (description != null && description!.trim().isEmpty) {
      throw ArgumentError(
        'Field description cannot be empty.',
      );
    }

    for (final key in this.properties.keys) {
      if (key.trim().isEmpty) {
        throw ArgumentError(
          'Nested property names cannot be empty.',
        );
      }
    }
  }

  final AppSchemaValueType type;
  final bool required;
  final String? description;
  final AppSchemaFieldConstraints? constraints;
  final Map<String, AppSchemaFieldDefinition> properties;
  final AppSchemaFieldDefinition? items;
  final bool allowUnknownProperties;
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

    final registryResult = _registry.validatePayload(
      eventType: eventType,
      version: schemaVersion,
      payload: payload,
    );

    for (final error in registryResult.errors) {
      violations.add(
        AppSchemaViolation(
          code: _classifyRegistryError(error),
          path: r'$',
          message: error,
        ),
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

  Map<String, AppSchemaFieldDefinition> _buildRootProperties(
    AppEventSchemaDefinition definition,
  ) {
    final properties = <String, AppSchemaFieldDefinition>{};

    for (final field in definition.requiredFields) {
      properties[field] = AppSchemaFieldDefinition(
        type: _convertRegistryType(
          definition.fieldTypes[field],
        ),
        required: true,
      );
    }

    for (final field in definition.optionalFields) {
      properties[field] = AppSchemaFieldDefinition(
        type: _convertRegistryType(
          definition.fieldTypes[field],
        ),
        required: false,
      );
    }

    return properties;
  }

  AppSchemaValueType _convertRegistryType(String? type) {
    switch (type) {
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
        return AppSchemaValueType.object;
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
          constraints?.allowNull != true) {
        violations.add(
          AppSchemaViolation(
            code: AppSchemaViolationCode.nullNotAllowed,
            path: path,
            message: 'Null is not allowed for this field.',
          ),
        );
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
      _validateObject(
        value: Map<String, Object?>.from(value as Map),
        properties: definition.properties,
        allowUnknownProperties: definition.allowUnknownProperties,
        path: path,
        depth: depth,
        violations: violations,
      );
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
    required Object value,
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

      if (constraints.pattern != null &&
          !RegExp(constraints.pattern!).hasMatch(value)) {
        violations.add(
          AppSchemaViolation(
            code: AppSchemaViolationCode.invalidStringPattern,
            path: path,
            message: 'String does not match the required pattern.',
          ),
        );
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
        return value is num;

      case AppSchemaValueType.boolean:
        return value is bool;

      case AppSchemaValueType.object:
        return value is Map &&
            value.keys.every((key) => key is String);

      case AppSchemaValueType.array:
        return value is List;

      case AppSchemaValueType.nullValue:
        return false;
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

  /// Validates an ISO calendar date without accepting normalized dates.
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

    final parsed = DateTime.tryParse(value);

    if (parsed == null) {
      return false;
    }

    return parsed.year == year &&
        parsed.month == month &&
        parsed.day == day;
  }

  /// Validates an ISO date-time value.
  bool _isValidDateTime(String value) {
    if (!RegExp(
      r'^\d{4}-\d{2}-\d{2}T'
      r'\d{2}:\d{2}:\d{2}'
      r'(?:\.\d+)?'
      r'(?:Z|[+-]\d{2}:\d{2})?$',
    ).hasMatch(value)) {
      return false;
    }

    final datePart = value.substring(0, 10);

    if (!_isValidDate(datePart)) {
      return false;
    }

    final parsed = DateTime.tryParse(value);

    if (parsed == null) {
      return false;
    }

    final timePart = value.substring(11, 19);
    final components = timePart.split(':');

    if (components.length != 3) {
      return false;
    }

    final hour = int.tryParse(components[0]);
    final minute = int.tryParse(components[1]);
    final second = int.tryParse(components[2]);

    if (hour == null ||
        minute == null ||
        second == null ||
        hour > 23 ||
        minute > 59 ||
        second > 59) {
      return false;
    }

    return true;
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

  /// Calculates decimal precision, including scientific notation.
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

    // clamp returns num; toInt preserves the declared return type.
    return (decimalCount - exponent).clamp(0, 1000).toInt();
  }

  AppSchemaViolationCode _classifyRegistryError(String error) {
    if (error.startsWith('Required field')) {
      return AppSchemaViolationCode.missingRequiredField;
    }

    if (error.startsWith('Undeclared field')) {
      return AppSchemaViolationCode.unknownField;
    }

    if (error.contains('does not match type')) {
      return AppSchemaViolationCode.invalidType;
    }

    return AppSchemaViolationCode.invalidConstraint;
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
