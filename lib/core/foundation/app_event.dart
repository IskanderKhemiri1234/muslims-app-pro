
import 'app_clock.dart';

/// Identifies the subsystem or boundary that produced an application event.
///
/// The source describes the origin of an event, not the module that consumes
/// it. Feature modules can use [custom] when none of the predefined sources
/// accurately describes their origin.
enum AppEventSource {
  application,
  system,
  prayerEngine,
  qiblaEngine,
  quran,
  adhkar,
  offlineMaps,
  landmarks,
  hijriCalendar,
  notifications,
  storage,
  networking,
  userInteraction,
  restoration,
  custom,
}

/// Generates unique identifiers for application events.
abstract interface class AppEventIdGenerator {
  String generate();
}

/// Generates event identifiers using a monotonically increasing sequence.
///
/// The generated identifier is unique within the lifetime of this generator.
/// It is not intended to provide distributed uniqueness across devices.
final class SequentialAppEventIdGenerator
    implements AppEventIdGenerator {
  SequentialAppEventIdGenerator({
    String prefix = 'evt',
    int initialSequence = 0,
  })  : _prefix = _validatePrefix(prefix),
        _sequence = _validateInitialSequence(initialSequence);

  final String _prefix;
  int _sequence;

  static String _validatePrefix(String prefix) {
    final normalized = prefix.trim();

    if (normalized.isEmpty) {
      throw ArgumentError.value(
        prefix,
        'prefix',
        'Event identifier prefix must not be empty.',
      );
    }

    if (normalized.contains(':')) {
      throw ArgumentError.value(
        prefix,
        'prefix',
        'Event identifier prefix must not contain a colon.',
      );
    }

    return normalized;
  }

  static int _validateInitialSequence(int value) {
    if (value < 0) {
      throw ArgumentError.value(
        value,
        'initialSequence',
        'Initial sequence must not be negative.',
      );
    }

    return value;
  }

  @override
  String generate() {
    if (_sequence == 0x7FFFFFFFFFFFFFFF) {
      throw StateError(
        'Application event identifier sequence is exhausted.',
      );
    }

    _sequence++;

    return '$_prefix:$_sequence';
  }

  int get currentSequence => _sequence;
}

/// Describes the common contract of every internal application event.
///
/// Events are immutable after construction. Each event has:
/// - A unique identifier.
/// - A creation timestamp.
/// - An originating source.
/// - An event type name.
abstract class AppEvent {
  AppEvent({
    required this.id,
    required DateTime timestamp,
    required this.source,
  }) : timestamp = timestamp.toUtc() {
    if (id.trim().isEmpty) {
      throw ArgumentError.value(
        id,
        'id',
        'Event identifier must not be empty.',
      );
    }
  }

  /// Unique identifier of this event.
  final String id;

  /// Event creation timestamp normalized to UTC.
  final DateTime timestamp;

  /// Origin of the event.
  final AppEventSource source;

  /// Stable event type identifier.
  ///
  /// Subclasses should override this getter with a stable identifier.
  String get eventType;

  /// Whether this event originated from a predefined custom source.
  bool get hasCustomSource => source == AppEventSource.custom;

  @override
  String toString() {
    return 'AppEvent('
        'id: $id, '
        'eventType: $eventType, '
        'source: ${source.name}, '
        'timestamp: ${timestamp.toIso8601String()}'
        ')';
  }
}

/// Base implementation for application events with a typed payload.
///
/// The payload should itself be immutable. This class deliberately does not
/// assume that arbitrary generic payloads are deeply immutable.
abstract class AppDataEvent<T> extends AppEvent {
  AppDataEvent({
    required super.id,
    required super.timestamp,
    required super.source,
    required this.payload,
  });

  /// Data carried by this event.
  final T payload;
}

/// Factory responsible for creating application events with consistent
/// identifiers, timestamps, and source metadata.
final class AppEventFactory {
  AppEventFactory({
    required AppClock clock,
    required AppEventIdGenerator idGenerator,
  })  : _clock = clock,
        _idGenerator = idGenerator;

  final AppClock _clock;
  final AppEventIdGenerator _idGenerator;

  /// Creates an immutable event instance using the supplied constructor.
  ///
  /// The constructor receives a generated identifier, the current UTC
  /// timestamp, and the specified source.
  E create<E extends AppEvent>({
    required E Function({
      required String id,
      required DateTime timestamp,
      required AppEventSource source,
    }) constructor,
    required AppEventSource source,
  }) {
    return constructor(
      id: _idGenerator.generate(),
      timestamp: _clock.utcNow,
      source: source,
    );
  }

  /// Creates an event with a typed payload.
  ///
  /// The returned event uses an immutable payload reference. Callers remain
  /// responsible for providing an immutable payload object.
  AppPayloadEvent<T> createPayload<T>({
    required T payload,
    required AppEventSource source,
    required String eventType,
  }) {
    return AppPayloadEvent<T>(
      id: _idGenerator.generate(),
      timestamp: _clock.utcNow,
      source: source,
      payload: payload,
      eventType: eventType,
    );
  }
}

/// Generic immutable event carrying a typed payload.
///
/// This is useful when a feature needs to publish an event without creating
/// a dedicated event subclass.
final class AppPayloadEvent<T> extends AppDataEvent<T> {
  AppPayloadEvent({
    required super.id,
    required super.timestamp,
    required super.source,
    required super.payload,
    required String eventType,
  }) : _eventType = _validateEventType(eventType);

  final String _eventType;

  static String _validateEventType(String value) {
    final normalized = value.trim();

    if (normalized.isEmpty) {
      throw ArgumentError.value(
        value,
        'eventType',
        'Event type must not be empty.',
      );
    }

    return normalized;
  }

  @override
  String get eventType => _eventType;
}
