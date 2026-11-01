
import 'app_clock.dart';
import 'app_event.dart';

/// Creates unique identifiers for event envelopes.
///
/// Envelope identifiers are independent from the identifiers of the
/// underlying domain events.
abstract interface class AppEventEnvelopeIdGenerator {
  String generate();
}

/// Generates sequential envelope identifiers within one generator instance.
///
/// This generator is suitable for deterministic local execution and testing.
/// It is not intended to provide globally unique identifiers across devices
/// or distributed processes.
final class SequentialAppEventEnvelopeIdGenerator
    implements AppEventEnvelopeIdGenerator {
  SequentialAppEventEnvelopeIdGenerator({
    String prefix = 'envelope',
    int initialValue = 0,
  })  : _prefix = _validatePrefix(prefix),
        _nextValue = _validateInitialValue(initialValue);

  final String _prefix;
  int _nextValue;

  static String _validatePrefix(String value) {
    final normalized = value.trim();

    if (normalized.isEmpty) {
      throw ArgumentError.value(
        value,
        'prefix',
        'Envelope identifier prefix cannot be empty.',
      );
    }

    return normalized;
  }

  static int _validateInitialValue(int value) {
    if (value < 0) {
      throw ArgumentError.value(
        value,
        'initialValue',
        'Initial value cannot be negative.',
      );
    }

    return value;
  }

  @override
  String generate() {
    if (_nextValue == 0x7FFFFFFFFFFFFFFF) {
      throw StateError(
        'Envelope identifier sequence has reached its maximum value.',
      );
    }

    final identifier = '$_prefix-${_nextValue.toString().padLeft(12, '0')}';
    _nextValue++;

    return identifier;
  }
}

/// Immutable transport envelope around an application event.
///
/// The envelope contains distribution metadata without modifying the
/// original event. Its sequence number is scoped to the publisher or
/// distribution channel that assigns it.
final class AppEventEnvelope {
  AppEventEnvelope({
    required this.envelopeId,
    required this.event,
    required this.sequence,
    required DateTime createdAt,
    String? correlationId,
    String? causationId,
  })  : createdAt = createdAt.toUtc(),
        correlationId = _normalizeOptionalIdentifier(
          correlationId,
          'correlationId',
        ),
        causationId = _normalizeOptionalIdentifier(
          causationId,
          'causationId',
        ) {
    _validateEnvelopeId(envelopeId);
    _validateSequence(sequence);
  }

  /// Unique identifier of this transport envelope.
  ///
  /// This is deliberately different from [event.id].
  final String envelopeId;

  /// Original event, retained without modification.
  final AppEvent event;

  /// Position of this envelope in its publisher's sequence.
  ///
  /// Sequence numbers are scoped to the publisher or channel and should not
  /// be interpreted as globally unique identifiers.
  final int sequence;

  /// UTC time at which this envelope was created.
  ///
  /// This is distinct from the timestamp of the underlying event.
  final DateTime createdAt;

  /// Identifier shared by events belonging to the same logical operation.
  ///
  /// For example, several events generated while completing one user action
  /// may share the same correlation identifier.
  final String? correlationId;

  /// Identifier of the event or envelope that directly caused this event.
  ///
  /// The value is a reference identifier; it does not imply that the
  /// referenced event is available in the current process.
  final String? causationId;

  /// Identifier of the original event.
  String get eventId => event.id;

  /// Event type carried by this envelope.
  String get eventType => event.eventType;

  /// Source of the original event.
  AppEventSource get source => event.source;

  /// Timestamp of the original event.
  DateTime get eventTimestamp => event.timestamp;

  /// Whether this envelope belongs to a correlated operation.
  bool get hasCorrelation => correlationId != null;

  /// Whether this envelope records a causal predecessor.
  bool get hasCausation => causationId != null;

  static void _validateEnvelopeId(String value) {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(
        value,
        'envelopeId',
        'Envelope identifier cannot be empty.',
      );
    }
  }

  static void _validateSequence(int value) {
    if (value < 0) {
      throw ArgumentError.value(
        value,
        'sequence',
        'Envelope sequence cannot be negative.',
      );
    }
  }

  static String? _normalizeOptionalIdentifier(
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
        'Optional identifiers must be null or non-empty.',
      );
    }

    return normalized;
  }

  @override
  String toString() {
    return 'AppEventEnvelope('
        'envelopeId: $envelopeId, '
        'eventId: $eventId, '
        'eventType: $eventType, '
        'sequence: $sequence, '
        'createdAt: ${createdAt.toIso8601String()}, '
        'correlationId: $correlationId, '
        'causationId: $causationId'
        ')';
  }
}

/// Creates event envelopes using injected clock and identifier services.
///
/// The factory does not publish events and does not assign global sequence
/// numbers. The caller supplies the sequence number appropriate to its
/// publisher or channel.
final class AppEventEnvelopeFactory {
  AppEventEnvelopeFactory({
    required AppClock clock,
    required AppEventEnvelopeIdGenerator idGenerator,
  })  : _clock = clock,
        _idGenerator = idGenerator;

  final AppClock _clock;
  final AppEventEnvelopeIdGenerator _idGenerator;

  /// Wraps an existing event with transport metadata.
  ///
  /// [sequence] must be assigned by the publisher responsible for ordering.
  /// [correlationId] groups related events.
  /// [causationId] identifies the direct causal predecessor, when available.
  AppEventEnvelope create({
    required AppEvent event,
    required int sequence,
    String? correlationId,
    String? causationId,
  }) {
    return AppEventEnvelope(
      envelopeId: _idGenerator.generate(),
      event: event,
      sequence: sequence,
      createdAt: _clock.utcNow,
      correlationId: correlationId,
      causationId: causationId,
    );
  }
}
