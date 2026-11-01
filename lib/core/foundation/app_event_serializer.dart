
import 'dart:convert';

import 'app_event.dart';
import 'app_event_envelope.dart';
import 'app_event_metadata.dart';

/// Represents a failure that occurs while serializing an application event.
final class AppEventSerializationException implements Exception {
  AppEventSerializationException({
    required this.message,
    this.eventType,
    this.cause,
  });

  final String message;
  final String? eventType;
  final Object? cause;

  @override
  String toString() {
    final typeInformation =
        eventType == null ? '' : ' Event type: $eventType.';

    final causeInformation =
        cause == null ? '' : ' Cause: $cause';

    return 'AppEventSerializationException: '
        '$message$typeInformation$causeInformation';
  }
}

/// Encodes the domain-specific payload of one event type.
///
/// Implementations must return JSON-compatible values only:
/// null, bool, num, String, lists, and maps with String keys.
///
/// DateTime, enums, custom objects, and binary data must be converted
/// explicitly by the codec.
abstract interface class AppEventPayloadCodec {
  /// Stable event type handled by this codec.
  String get eventType;

  /// Converts an event payload into a serializable map.
  ///
  /// Implementations must validate the concrete event type before
  /// extracting its payload.
  Map<String, Object?> encode(AppEvent event);
}

/// Registry of payload codecs supported by the serializer.
///
/// The registry is immutable after construction. This prevents codec
/// replacement from silently changing serialization behavior at runtime.
final class AppEventPayloadCodecRegistry {
  AppEventPayloadCodecRegistry({
    required Iterable<AppEventPayloadCodec> codecs,
  }) : _codecs = _buildRegistry(codecs);

  final Map<String, AppEventPayloadCodec> _codecs;

  /// Returns all registered event types.
  Set<String> get registeredEventTypes =>
      Set<String>.unmodifiable(_codecs.keys);

  /// Returns whether a codec exists for the specified event type.
  bool supports(String eventType) {
    return _codecs.containsKey(eventType);
  }

  /// Retrieves the codec for an event type.
  ///
  /// Throws [AppEventSerializationException] when no codec is registered.
  AppEventPayloadCodec codecFor(String eventType) {
    final codec = _codecs[eventType];

    if (codec == null) {
      throw AppEventSerializationException(
        message: 'No payload codec is registered for this event type.',
        eventType: eventType,
      );
    }

    return codec;
  }

  static Map<String, AppEventPayloadCodec> _buildRegistry(
    Iterable<AppEventPayloadCodec> codecs,
  ) {
    final registry = <String, AppEventPayloadCodec>{};

    for (final codec in codecs) {
      final eventType = codec.eventType.trim();

      if (eventType.isEmpty) {
        throw ArgumentError(
          'Codec event type cannot be empty.',
        );
      }

      if (registry.containsKey(eventType)) {
        throw ArgumentError(
          'A codec is already registered for event type: $eventType',
        );
      }

      registry[eventType] = codec;
    }

    return Map<String, AppEventPayloadCodec>.unmodifiable(registry);
  }
}

/// Serializes application events and their independent metadata.
///
/// This component is deliberately limited to data transformation.
/// It does not publish events, manage subscriptions, write to storage,
/// perform network requests, or control delivery.
final class AppEventSerializer {
  AppEventSerializer({
    required AppEventPayloadCodecRegistry codecRegistry,
  }) : _codecRegistry = codecRegistry;

  static const int formatVersion = 1;

  static const String formatIdentifier = 'muslims_app_event';

  final AppEventPayloadCodecRegistry _codecRegistry;

  /// Serializes an event envelope and its metadata into a structured map.
  ///
  /// The original event and envelope remain unchanged.
  ///
  /// Every event type must have an explicitly registered payload codec.
  Map<String, Object?> serialize({
    required AppEventEnvelope envelope,
    required AppEventMetadata metadata,
  }) {
    final event = envelope.event;

    try {
      final codec = _codecRegistry.codecFor(event.eventType);
      final encodedPayload = codec.encode(event);

      final normalizedPayload = _normalizeMap(
        encodedPayload,
        path: r'$.event.payload',
      );

      final document = <String, Object?>{
        'format': formatIdentifier,
        'formatVersion': formatVersion,
        'envelope': _serializeEnvelope(envelope),
        'event': _serializeEvent(
          event: event,
          payload: normalizedPayload,
        ),
        'metadata': _serializeMetadata(metadata),
      };

      return _normalizeMap(
        document,
        path: r'$',
      );
    } on AppEventSerializationException {
      rethrow;
    } catch (error) {
      throw AppEventSerializationException(
        message: 'Failed to serialize the application event.',
        eventType: event.eventType,
        cause: error,
      );
    }
  }

  /// Serializes an event envelope and metadata into a JSON string.
  ///
  /// JSON encoding errors are wrapped in
  /// [AppEventSerializationException].
  String serializeToJson({
    required AppEventEnvelope envelope,
    required AppEventMetadata metadata,
  }) {
    final document = serialize(
      envelope: envelope,
      metadata: metadata,
    );

    try {
      return jsonEncode(document);
    } catch (error) {
      throw AppEventSerializationException(
        message: 'Failed to encode the serialized event as JSON.',
        eventType: envelope.event.eventType,
        cause: error,
      );
    }
  }

  Map<String, Object?> _serializeEnvelope(
    AppEventEnvelope envelope,
  ) {
    return {
      'id': envelope.envelopeId,
      'sequence': envelope.sequence,
      'createdAt': envelope.createdAt.toUtc().toIso8601String(),
      'correlationId': envelope.correlationId,
      'causationId': envelope.causationId,
    };
  }

  Map<String, Object?> _serializeEvent({
    required AppEvent event,
    required Map<String, Object?> payload,
  }) {
    return {
      'id': event.id,
      'type': event.eventType,
      'source': event.source.name,
      'timestamp': event.timestamp.toUtc().toIso8601String(),
      'payload': payload,
    };
  }

  Map<String, Object?> _serializeMetadata(
    AppEventMetadata metadata,
  ) {
    return {
      'environment': metadata.environment.name,
      'origin': metadata.origin.name,
      'schemaVersion': metadata.schemaVersion,
      'schemaName': metadata.schemaName,
      'producer': metadata.producer,
      'producerVersion': metadata.producerVersion,
      'attributes': metadata.attributes,
      'tags': metadata.tags,
    };
  }

  /// Converts an arbitrary map into a deeply immutable JSON-compatible map.
  ///
  /// Unsupported values and non-string keys are rejected instead of being
  /// silently converted or discarded.
  Map<String, Object?> _normalizeMap(
    Map<dynamic, dynamic> source, {
    required String path,
  }) {
    final normalized = <String, Object?>{};

    for (final entry in source.entries) {
      final key = entry.key;

      if (key is! String) {
        throw AppEventSerializationException(
          message: 'Map keys must be strings at $path.',
        );
      }

      if (key.trim().isEmpty) {
        throw AppEventSerializationException(
          message: 'Map keys cannot be empty at $path.',
        );
      }

      if (normalized.containsKey(key)) {
        throw AppEventSerializationException(
          message: 'Duplicate map key "$key" at $path.',
        );
      }

      normalized[key] = _normalizeValue(
        entry.value,
        path: '$path.$key',
      );
    }

    return Map<String, Object?>.unmodifiable(normalized);
  }

  /// Validates and normalizes a JSON-compatible value recursively.
  Object? _normalizeValue(
    Object? value, {
    required String path,
  }) {
    if (value == null || value is String || value is bool) {
      return value;
    }

    if (value is int) {
      return value;
    }

    if (value is double) {
      if (!value.isFinite) {
        throw AppEventSerializationException(
          message: 'Non-finite numbers are not valid JSON values at $path.',
        );
      }

      return value;
    }

    if (value is num) {
      if (!value.isFinite) {
        throw AppEventSerializationException(
          message: 'Non-finite numbers are not valid JSON values at $path.',
        );
      }

      return value;
    }

    if (value is Map) {
      return _normalizeMap(
        value,
        path: path,
      );
    }

    if (value is List) {
      final normalized = <Object?>[];

      for (var index = 0; index < value.length; index++) {
        normalized.add(
          _normalizeValue(
            value[index],
            path: '$path[$index]',
          ),
        );
      }

      return List<Object?>.unmodifiable(normalized);
    }

    throw AppEventSerializationException(
      message: 'Unsupported value of type ${value.runtimeType} at $path. '
          'Convert it explicitly in the event payload codec.',
    );
  }
}
