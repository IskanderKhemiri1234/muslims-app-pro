
import 'dart:convert';

import 'app_event.dart';
import 'app_event_envelope.dart';
import 'app_event_metadata.dart';
import 'app_event_serializer.dart';

/// Describes an error encountered while deserializing an application event.
final class AppEventDeserializationException implements Exception {
  AppEventDeserializationException({
    required this.message,
    this.eventType,
    this.field,
    this.cause,
  });

  final String message;
  final String? eventType;
  final String? field;
  final Object? cause;

  @override
  String toString() {
    final typeInformation =
        eventType == null ? '' : ' Event type: $eventType.';

    final fieldInformation =
        field == null ? '' : ' Field: $field.';

    final causeInformation =
        cause == null ? '' : ' Cause: $cause';

    return 'AppEventDeserializationException: '
        '$message$typeInformation$fieldInformation$causeInformation';
  }
}

/// Contains the validated information required to reconstruct an event.
///
/// This object is passed to an explicitly registered event codec.
final class AppEventDeserializationContext {
  const AppEventDeserializationContext({
    required this.eventId,
    required this.eventType,
    required this.source,
    required this.timestamp,
  });

  final String eventId;
  final String eventType;
  final AppEventSource source;
  final DateTime timestamp;
}

/// Reconstructs one specific application event type.
///
/// Implementations must validate the payload structure and construct
/// the correct concrete AppEvent subtype.
///
/// A codec must not silently accept a different event type.
abstract interface class AppEventPayloadDecoder {
  /// Stable event type handled by this decoder.
  String get eventType;

  /// Reconstructs the concrete event from its validated context and payload.
  AppEvent decode({
    required AppEventDeserializationContext context,
    required Map<String, Object?> payload,
  });
}

/// Registry of explicitly supported event deserialization codecs.
final class AppEventPayloadDecoderRegistry {
  AppEventPayloadDecoderRegistry({
    required Iterable<AppEventPayloadDecoder> decoders,
  }) : _decoders = _buildRegistry(decoders);

  final Map<String, AppEventPayloadDecoder> _decoders;

  /// Returns all registered event types.
  Set<String> get registeredEventTypes =>
      Set<String>.unmodifiable(_decoders.keys);

  /// Checks whether a decoder is registered for an event type.
  bool supports(String eventType) {
    return _decoders.containsKey(eventType);
  }

  /// Retrieves the decoder associated with an event type.
  AppEventPayloadDecoder decoderFor(String eventType) {
    final decoder = _decoders[eventType];

    if (decoder == null) {
      throw AppEventDeserializationException(
        message: 'No decoder is registered for this event type.',
        eventType: eventType,
      );
    }

    return decoder;
  }

  static Map<String, AppEventPayloadDecoder> _buildRegistry(
    Iterable<AppEventPayloadDecoder> decoders,
  ) {
    final registry = <String, AppEventPayloadDecoder>{};

    for (final decoder in decoders) {
      final eventType = decoder.eventType.trim();

      if (eventType.isEmpty) {
        throw ArgumentError(
          'Decoder event type cannot be empty.',
        );
      }

      if (registry.containsKey(eventType)) {
        throw ArgumentError(
          'A decoder is already registered for event type: $eventType',
        );
      }

      registry[eventType] = decoder;
    }

    return Map<String, AppEventPayloadDecoder>.unmodifiable(registry);
  }
}

/// Represents a completely reconstructed serialized event document.
///
/// The event, envelope, and metadata remain separate objects.
final class AppDeserializedEvent {
  const AppDeserializedEvent({
    required this.envelope,
    required this.event,
    required this.metadata,
    required this.formatVersion,
  });

  final AppEventEnvelope envelope;
  final AppEvent event;
  final AppEventMetadata metadata;
  final int formatVersion;
}

/// Reads and reconstructs serialized application event documents.
///
/// This component performs data validation and reconstruction only.
/// It does not publish events, access storage, or perform network requests.
final class AppEventDeserializer {
  AppEventDeserializer({
    required AppEventPayloadDecoderRegistry decoderRegistry,
  }) : _decoderRegistry = decoderRegistry;

  final AppEventPayloadDecoderRegistry _decoderRegistry;

  /// Deserializes a previously serialized JSON string.
  AppDeserializedEvent deserializeJson(String json) {
    final Object? decoded;

    try {
      decoded = jsonDecode(json);
    } catch (error) {
      throw AppEventDeserializationException(
        message: 'The supplied content is not valid JSON.',
        cause: error,
      );
    }

    if (decoded is! Map) {
      throw AppEventDeserializationException(
        message: 'The JSON root must be an object.',
      );
    }

    return deserialize(
      Map<String, Object?>.from(decoded),
    );
  }

  /// Validates and reconstructs a serialized event document.
  AppDeserializedEvent deserialize(
    Map<String, Object?> document,
  ) {
    try {
      _validateFormatIdentifier(document);

      final formatVersion = _readRequiredInteger(
        document,
        'formatVersion',
      );

      _validateFormatVersion(formatVersion);

      final envelopeData = _readRequiredMap(
        document,
        'envelope',
      );

      final eventData = _readRequiredMap(
        document,
        'event',
      );

      final metadataData = _readRequiredMap(
        document,
        'metadata',
      );

      final eventType = _readRequiredString(
        eventData,
        'type',
      );

      final eventContext = _deserializeEventContext(
        eventData,
        eventType,
      );

      final payload = _readRequiredMap(
        eventData,
        'payload',
      );

      final decoder = _decoderRegistry.decoderFor(eventType);

      final event = _decodeEvent(
        decoder: decoder,
        context: eventContext,
        payload: payload,
      );

      _validateDecodedEvent(
        event: event,
        context: eventContext,
      );

      final envelope = _deserializeEnvelope(
        envelopeData,
        event,
      );

      final metadata = _deserializeMetadata(
        metadataData,
      );

      return AppDeserializedEvent(
        envelope: envelope,
        event: event,
        metadata: metadata,
        formatVersion: formatVersion,
      );
    } on AppEventDeserializationException {
      rethrow;
    } catch (error) {
      throw AppEventDeserializationException(
        message: 'Failed to reconstruct the application event document.',
        cause: error,
      );
    }
  }

  void _validateFormatIdentifier(
    Map<String, Object?> document,
  ) {
    final format = _readRequiredString(
      document,
      'format',
    );

    if (format != AppEventSerializer.formatIdentifier) {
      throw AppEventDeserializationException(
        message: 'Unsupported serialized document format.',
        field: 'format',
      );
    }
  }

  void _validateFormatVersion(int version) {
    if (version != AppEventSerializer.formatVersion) {
      throw AppEventDeserializationException(
        message: 'Unsupported event serialization format version.',
        field: 'formatVersion',
      );
    }
  }

  AppEventDeserializationContext _deserializeEventContext(
    Map<String, Object?> eventData,
    String eventType,
  ) {
    final eventId = _readRequiredString(
      eventData,
      'id',
    );

    final sourceName = _readRequiredString(
      eventData,
      'source',
    );

    final timestamp = _readRequiredDateTime(
      eventData,
      'timestamp',
    );

    final source = _readEnumValue<AppEventSource>(
      sourceName,
      AppEventSource.values,
      'event.source',
    );

    return AppEventDeserializationContext(
      eventId: eventId,
      eventType: eventType,
      source: source,
      timestamp: timestamp,
    );
  }

  AppEvent _decodeEvent({
    required AppEventPayloadDecoder decoder,
    required AppEventDeserializationContext context,
    required Map<String, Object?> payload,
  }) {
    if (decoder.eventType != context.eventType) {
      throw AppEventDeserializationException(
        message: 'Decoder event type does not match the document event type.',
        eventType: context.eventType,
      );
    }

    try {
      return decoder.decode(
        context: context,
        payload: payload,
      );
    } on AppEventDeserializationException {
      rethrow;
    } catch (error) {
      throw AppEventDeserializationException(
        message: 'The event payload decoder failed.',
        eventType: context.eventType,
        field: 'event.payload',
        cause: error,
      );
    }
  }

  void _validateDecodedEvent({
    required AppEvent event,
    required AppEventDeserializationContext context,
  }) {
    if (event.id != context.eventId) {
      throw AppEventDeserializationException(
        message: 'Decoded event identifier does not match the document.',
        eventType: context.eventType,
        field: 'event.id',
      );
    }

    if (event.eventType != context.eventType) {
      throw AppEventDeserializationException(
        message: 'Decoded event type does not match the document.',
        eventType: context.eventType,
        field: 'event.type',
      );
    }

    if (event.source != context.source) {
      throw AppEventDeserializationException(
        message: 'Decoded event source does not match the document.',
        eventType: context.eventType,
        field: 'event.source',
      );
    }

    if (!event.timestamp.toUtc().isAtSameMomentAs(context.timestamp)) {
      throw AppEventDeserializationException(
        message: 'Decoded event timestamp does not match the document.',
        eventType: context.eventType,
        field: 'event.timestamp',
      );
    }
  }

  AppEventEnvelope _deserializeEnvelope(
    Map<String, Object?> envelopeData,
    AppEvent event,
  ) {
    final envelopeId = _readRequiredString(
      envelopeData,
      'id',
    );

    final sequence = _readRequiredInteger(
      envelopeData,
      'sequence',
    );

    if (sequence < 0) {
      throw AppEventDeserializationException(
        message: 'Envelope sequence cannot be negative.',
        field: 'envelope.sequence',
      );
    }

    final createdAt = _readRequiredDateTime(
      envelopeData,
      'createdAt',
    );

    final correlationId = _readOptionalString(
      envelopeData,
      'correlationId',
    );

    final causationId = _readOptionalString(
      envelopeData,
      'causationId',
    );

    return AppEventEnvelope(
      envelopeId: envelopeId,
      event: event,
      sequence: sequence,
      createdAt: createdAt,
      correlationId: correlationId,
      causationId: causationId,
    );
  }

  AppEventMetadata _deserializeMetadata(
    Map<String, Object?> metadataData,
  ) {
    final environmentName = _readRequiredString(
      metadataData,
      'environment',
    );

    final originName = _readRequiredString(
      metadataData,
      'origin',
    );

    final schemaVersion = _readRequiredInteger(
      metadataData,
      'schemaVersion',
    );

    if (schemaVersion < 1) {
      throw AppEventDeserializationException(
        message: 'Schema version must be greater than zero.',
        field: 'metadata.schemaVersion',
      );
    }

    final environment = _readEnumValue<AppEventEnvironment>(
      environmentName,
      AppEventEnvironment.values,
      'metadata.environment',
    );

    final origin = _readEnumValue<AppEventOrigin>(
      originName,
      AppEventOrigin.values,
      'metadata.origin',
    );

    return AppEventMetadata(
      environment: environment,
      origin: origin,
      schemaVersion: schemaVersion,
      schemaName: _readOptionalString(
        metadataData,
        'schemaName',
      ),
      producer: _readOptionalString(
        metadataData,
        'producer',
      ),
      producerVersion: _readOptionalString(
        metadataData,
        'producerVersion',
      ),
      attributes: _readStringMap(
        metadataData,
        'attributes',
      ),
      tags: _readStringMap(
        metadataData,
        'tags',
      ),
    );
  }

  Map<String, String> _readStringMap(
    Map<String, Object?> source,
    String key,
  ) {
    final value = source[key];

    if (value == null) {
      return const {};
    }

    if (value is! Map) {
      throw AppEventDeserializationException(
        message: 'Expected an object containing string values.',
        field: key,
      );
    }

    final result = <String, String>{};

    for (final entry in value.entries) {
      if (entry.key is! String || entry.value is! String) {
        throw AppEventDeserializationException(
          message: 'Metadata maps must contain string keys and values.',
          field: key,
        );
      }

      result[entry.key as String] = entry.value as String;
    }

    return result;
  }

  String _readRequiredString(
    Map<String, Object?> source,
    String key,
  ) {
    final value = source[key];

    if (value is! String || value.trim().isEmpty) {
      throw AppEventDeserializationException(
        message: 'A non-empty string value is required.',
        field: key,
      );
    }

    return value.trim();
  }

  String? _readOptionalString(
    Map<String, Object?> source,
    String key,
  ) {
    if (!source.containsKey(key) || source[key] == null) {
      return null;
    }

    final value = source[key];

    if (value is! String || value.trim().isEmpty) {
      throw AppEventDeserializationException(
        message: 'Expected null or a non-empty string.',
        field: key,
      );
    }

    return value.trim();
  }

  int _readRequiredInteger(
    Map<String, Object?> source,
    String key,
  ) {
    final value = source[key];

    if (value is! int) {
      throw AppEventDeserializationException(
        message: 'Expected an integer value.',
        field: key,
      );
    }

    return value;
  }

  DateTime _readRequiredDateTime(
    Map<String, Object?> source,
    String key,
  ) {
    final value = _readRequiredString(
      source,
      key,
    );

    try {
      return DateTime.parse(value).toUtc();
    } catch (error) {
      throw AppEventDeserializationException(
        message: 'Invalid ISO 8601 date-time value.',
        field: key,
        cause: error,
      );
    }
  }

  Map<String, Object?> _readRequiredMap(
    Map<String, Object?> source,
    String key,
  ) {
    final value = source[key];

    if (value is! Map) {
      throw AppEventDeserializationException(
        message: 'Expected an object.',
        field: key,
      );
    }

    final result = <String, Object?>{};

    for (final entry in value.entries) {
      if (entry.key is! String) {
        throw AppEventDeserializationException(
          message: 'Object keys must be strings.',
          field: key,
        );
      }

      result[entry.key as String] = entry.value;
    }

    return result;
  }

  T _readEnumValue<T extends Enum>(
    String name,
    List<T> values,
    String field,
  ) {
    for (final value in values) {
      if (value.name == name) {
        return value;
      }
    }

    throw AppEventDeserializationException(
      message: 'Unknown enum value "$name".',
      field: field,
    );
  }
}
