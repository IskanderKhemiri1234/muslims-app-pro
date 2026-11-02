
/// Describes the environment in which an event was produced.
enum AppEventEnvironment {
  development,
  staging,
  production,
  testing,
  unknown,
}

/// Describes the origin classification of an event.
///
/// This is metadata about the production context, not a replacement
/// for the original event source.
enum AppEventOrigin {
  application,
  operatingSystem,
  remoteService,
  localStorage,
  userInteraction,
  scheduledTask,
  backgroundProcess,
  externalIntegration,
  unknown,
}

/// Immutable metadata associated with an application event.
///
/// Metadata is intentionally independent from:
/// - The event payload and identity.
/// - Envelope identifiers and transport sequence.
/// - Correlation and causation relationships.
///
/// It can be attached to an event envelope or carried alongside an event
/// by the publishing infrastructure.
final class AppEventMetadata {
  AppEventMetadata({
    required this.environment,
    required this.origin,
    required this.schemaVersion,
    Map<String, String> attributes = const {},
    Map<String, String> tags = const {},
    String? producer,
    String? producerVersion,
    String? schemaName,
  })  : attributes = _immutableStringMap(
          attributes,
          'attributes',
        ),
        tags = _immutableStringMap(
          tags,
          'tags',
        ),
        producer = _normalizeOptionalValue(
          producer,
          'producer',
        ),
        producerVersion = _normalizeOptionalValue(
          producerVersion,
          'producerVersion',
        ),
        schemaName = _normalizeOptionalValue(
          schemaName,
          'schemaName',
        ) {
    _validateSchemaVersion(schemaVersion);
  }

  /// Environment where the event was produced.
  final AppEventEnvironment environment;

  /// Classification of the event's production origin.
  final AppEventOrigin origin;

  /// Positive version number of the event data schema.
  ///
  /// This version describes the structure of the event data contract.
  /// It is independent from the application version.
  final int schemaVersion;

  /// Optional name identifying the producer component or service.
  final String? producer;

  /// Optional version of the producer component or service.
  final String? producerVersion;

  /// Optional logical name of the schema.
  final String? schemaName;

  /// Additional descriptive key-value properties.
  ///
  /// These values must not contain secrets, credentials, or sensitive
  /// personal information.
  final Map<String, String> attributes;

  /// Lightweight classification labels for filtering and diagnostics.
  final Map<String, String> tags;

  /// Whether a producer identifier is available.
  bool get hasProducer => producer != null;

  /// Whether a producer version is available.
  bool get hasProducerVersion => producerVersion != null;

  /// Whether a schema name is available.
  bool get hasSchemaName => schemaName != null;

  /// Whether additional attributes are available.
  bool get hasAttributes => attributes.isNotEmpty;

  /// Whether classification tags are available.
  bool get hasTags => tags.isNotEmpty;

  /// Creates a new metadata instance with selected values replaced.
  ///
  /// Passing null for an optional nullable field preserves its current value.
  /// Use [clearProducer], [clearProducerVersion], and [clearSchemaName]
  /// to explicitly remove optional values.
  AppEventMetadata copyWith({
    AppEventEnvironment? environment,
    AppEventOrigin? origin,
    int? schemaVersion,
    String? producer,
    String? producerVersion,
    String? schemaName,
    Map<String, String>? attributes,
    Map<String, String>? tags,
    bool clearProducer = false,
    bool clearProducerVersion = false,
    bool clearSchemaName = false,
  }) {
    return AppEventMetadata(
      environment: environment ?? this.environment,
      origin: origin ?? this.origin,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      producer: clearProducer ? null : producer ?? this.producer,
      producerVersion: clearProducerVersion
          ? null
          : producerVersion ?? this.producerVersion,
      schemaName: clearSchemaName ? null : schemaName ?? this.schemaName,
      attributes: attributes ?? this.attributes,
      tags: tags ?? this.tags,
    );
  }

  /// Returns a new metadata instance with one attribute added or replaced.
  AppEventMetadata withAttribute({
    required String key,
    required String value,
  }) {
    final normalizedKey = _validateMapEntry(key, 'attribute key');
    final normalizedValue = _validateMapEntry(
      value,
      'attribute value',
    );

    return copyWith(
      attributes: {
        ...attributes,
        normalizedKey: normalizedValue,
      },
    );
  }

  /// Returns a new metadata instance with one tag added or replaced.
  AppEventMetadata withTag({
    required String key,
    required String value,
  }) {
    final normalizedKey = _validateMapEntry(key, 'tag key');
    final normalizedValue = _validateMapEntry(
      value,
      'tag value',
    );

    return copyWith(
      tags: {
        ...tags,
        normalizedKey: normalizedValue,
      },
    );
  }

  /// Returns a new metadata instance without the specified attribute.
  AppEventMetadata withoutAttribute(String key) {
    final normalizedKey = key.trim();

    if (normalizedKey.isEmpty) {
      throw ArgumentError.value(
        key,
        'key',
        'Attribute key cannot be empty.',
      );
    }

    if (!attributes.containsKey(normalizedKey)) {
      return this;
    }

    final updatedAttributes = Map<String, String>.from(attributes)
      ..remove(normalizedKey);

    return copyWith(attributes: updatedAttributes);
  }

  /// Returns a new metadata instance without the specified tag.
  AppEventMetadata withoutTag(String key) {
    final normalizedKey = key.trim();

    if (normalizedKey.isEmpty) {
      throw ArgumentError.value(
        key,
        'key',
        'Tag key cannot be empty.',
      );
    }

    if (!tags.containsKey(normalizedKey)) {
      return this;
    }

    final updatedTags = Map<String, String>.from(tags)
      ..remove(normalizedKey);

    return copyWith(tags: updatedTags);
  }

  static Map<String, String> _immutableStringMap(
    Map<String, String> source,
    String parameterName,
  ) {
    final normalized = <String, String>{};

    for (final entry in source.entries) {
      final key = _validateMapEntry(
        entry.key,
        '$parameterName key',
      );

      final value = _validateMapEntry(
        entry.value,
        '$parameterName value',
      );

      if (normalized.containsKey(key)) {
        throw ArgumentError.value(
          entry.key,
          parameterName,
          'Duplicate keys are not allowed after normalization.',
        );
      }

      normalized[key] = value;
    }

    return Map<String, String>.unmodifiable(normalized);
  }

  static String _validateMapEntry(
    String value,
    String parameterName,
  ) {
    final normalized = value.trim();

    if (normalized.isEmpty) {
      throw ArgumentError.value(
        value,
        parameterName,
        'Metadata keys and values cannot be empty.',
      );
    }

    return normalized;
  }

  static String? _normalizeOptionalValue(
    String? value,
    String parameterName,
  ) {
    if (value == null) {
      return null;
    }

    final normalized = value.trim();

    if (normalized.isEmpty) {
      throw ArgumentError.value(
        value,
        parameterName,
        'Optional metadata values must be null or non-empty.',
      );
    }

    return normalized;
  }

  static void _validateSchemaVersion(int value) {
    if (value < 1) {
      throw ArgumentError.value(
        value,
        'schemaVersion',
        'Schema version must be greater than zero.',
      );
    }
  }

  @override
  String toString() {
    return 'AppEventMetadata('
        'environment: ${environment.name}, '
        'origin: ${origin.name}, '
        'schemaVersion: $schemaVersion, '
        'producer: $producer, '
        'producerVersion: $producerVersion, '
        'schemaName: $schemaName, '
        'attributes: $attributes, '
        'tags: $tags'
        ')';
  }
}
