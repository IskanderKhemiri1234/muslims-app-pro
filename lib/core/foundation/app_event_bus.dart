
import 'app_event.dart';

/// Receives an application event published through [AppEventBus].
typedef AppEventCallback = void Function(AppEvent event);

/// Defines the subscription filter used by the event bus.
enum AppEventSubscriptionType {
  all,
  eventType,
  source,
}

/// Describes a failure thrown by an event subscriber.
final class AppEventListenerFailure {
  const AppEventListenerFailure({
    required this.subscriptionId,
    required this.error,
    required this.stackTrace,
  });

  final int subscriptionId;
  final Object error;
  final StackTrace stackTrace;
}

/// Describes the result of publishing an event.
final class AppEventPublishReport {
  AppEventPublishReport({
    required this.eventId,
    required this.matchedCount,
    required this.invokedCount,
    required List<AppEventListenerFailure> failures,
  }) : failures = List<AppEventListenerFailure>.unmodifiable(
          failures,
        );

  /// Identifier of the published event.
  final String eventId;

  /// Number of active subscriptions matching the event.
  final int matchedCount;

  /// Number of callbacks actually invoked.
  ///
  /// This includes callbacks that threw an exception.
  final int invokedCount;

  /// Subscriber failures captured during publication.
  final List<AppEventListenerFailure> failures;

  int get successfulCount => invokedCount - failures.length;

  bool get hasFailures => failures.isNotEmpty;

  bool get wasSuccessful => failures.isEmpty;
}

/// Internal record representing one event subscription.
final class _AppEventSubscriptionEntry {
  _AppEventSubscriptionEntry({
    required this.id,
    required this.callback,
    required this.type,
    this.eventType,
    this.source,
    required AppEventBus owner,
  }) : _owner = owner;

  final int id;
  final AppEventCallback callback;
  final AppEventSubscriptionType type;
  final String? eventType;
  final AppEventSource? source;

  AppEventBus? _owner;

  bool _isActive = true;

  bool get isActive => _isActive;

  bool matches(AppEvent event) {
    if (!_isActive) {
      return false;
    }

    switch (type) {
      case AppEventSubscriptionType.all:
        return true;

      case AppEventSubscriptionType.eventType:
        return event.eventType == eventType;

      case AppEventSubscriptionType.source:
        return event.source == source;
    }
  }

  void cancel() {
    if (!_isActive) {
      return;
    }

    _isActive = false;

    final owner = _owner;
    _owner = null;

    owner?._removeSubscription(id, this);
  }
}

/// Handle for an event bus subscription.
///
/// Cancellation is idempotent. The handle also reflects cancellation
/// performed by the owning event bus.
final class AppEventSubscription {
  AppEventSubscription._(this._entry);

  final _AppEventSubscriptionEntry _entry;

  bool get isActive => _entry.isActive;

  void cancel() {
    _entry.cancel();
  }
}

/// Central in-process event bus.
///
/// Feature modules publish events without importing or depending on
/// other feature modules.
///
/// Subscribers can listen to:
/// - Every event.
/// - A specific event type.
/// - Events originating from a specific source.
///
/// This implementation is synchronous. Subscriber callbacks are invoked
/// in registration order during [publish].
final class AppEventBus {
  final Map<int, _AppEventSubscriptionEntry> _subscriptions =
      <int, _AppEventSubscriptionEntry>{};

  int _nextSubscriptionId = 0;

  bool _isDisposed = false;

  /// Number of currently active subscriptions.
  int get subscriptionCount => _subscriptions.length;

  /// Whether the bus has no active subscriptions.
  bool get isEmpty => _subscriptions.isEmpty;

  /// Whether at least one subscription exists.
  bool get hasSubscribers => _subscriptions.isNotEmpty;

  /// Whether this event bus has been disposed.
  bool get isDisposed => _isDisposed;

  /// Subscribes to every published event.
  AppEventSubscription subscribe(
    AppEventCallback callback,
  ) {
    return _register(
      callback: callback,
      type: AppEventSubscriptionType.all,
    );
  }

  /// Subscribes to events with the specified [eventType].
  AppEventSubscription subscribeToType(
    String eventType,
    AppEventCallback callback,
  ) {
    final normalizedType = eventType.trim();

    if (normalizedType.isEmpty) {
      throw ArgumentError.value(
        eventType,
        'eventType',
        'Event type must not be empty.',
      );
    }

    return _register(
      callback: callback,
      type: AppEventSubscriptionType.eventType,
      eventType: normalizedType,
    );
  }

  /// Subscribes to events originating from [source].
  AppEventSubscription subscribeToSource(
    AppEventSource source,
    AppEventCallback callback,
  ) {
    return _register(
      callback: callback,
      type: AppEventSubscriptionType.source,
      source: source,
    );
  }

  /// Publishes [event] to all matching active subscribers.
  ///
  /// The method uses a snapshot of subscription identifiers:
  /// - A subscription cancelled before its turn is skipped.
  /// - A subscription added during publication receives no current event.
  /// - Subscriber exceptions are captured and do not stop other callbacks.
  ///
  /// Calling this method after disposal throws a [StateError].
  AppEventPublishReport publish(AppEvent event) {
    _ensureNotDisposed();

    final matchingIds = <int>[];

    for (final entry in _subscriptions.values) {
      if (entry.matches(event)) {
        matchingIds.add(entry.id);
      }
    }

    final failures = <AppEventListenerFailure>[];
    var invokedCount = 0;

    for (final id in matchingIds) {
      final entry = _subscriptions[id];

      if (entry == null || !entry.matches(event)) {
        continue;
      }

      invokedCount++;

      try {
        entry.callback(event);
      } catch (error, stackTrace) {
        failures.add(
          AppEventListenerFailure(
            subscriptionId: id,
            error: error,
            stackTrace: stackTrace,
          ),
        );
      }
    }

    return AppEventPublishReport(
      eventId: event.id,
      matchedCount: matchingIds.length,
      invokedCount: invokedCount,
      failures: failures,
    );
  }

  /// Cancels every active subscription.
  ///
  /// The bus remains usable after this operation.
  void clear() {
    final entries = List<_AppEventSubscriptionEntry>.of(
      _subscriptions.values,
    );

    for (final entry in entries) {
      entry.cancel();
    }
  }

  /// Permanently disposes this event bus.
  ///
  /// Existing subscription handles become inactive.
  /// Further subscriptions and publications are rejected.
  ///
  /// Calling this method repeatedly is safe.
  void dispose() {
    if (_isDisposed) {
      return;
    }

    _isDisposed = true;
    clear();
  }

  AppEventSubscription _register({
    required AppEventCallback callback,
    required AppEventSubscriptionType type,
    String? eventType,
    AppEventSource? source,
  }) {
    _ensureNotDisposed();

    final id = _nextSubscriptionId++;

    final entry = _AppEventSubscriptionEntry(
      id: id,
      callback: callback,
      type: type,
      eventType: eventType,
      source: source,
      owner: this,
    );

    _subscriptions[id] = entry;

    return AppEventSubscription._(entry);
  }

  void _removeSubscription(
    int id,
    _AppEventSubscriptionEntry entry,
  ) {
    if (identical(_subscriptions[id], entry)) {
      _subscriptions.remove(id);
    }
  }

  void _ensureNotDisposed() {
    if (_isDisposed) {
      throw StateError(
        'AppEventBus has been disposed.',
      );
    }
  }
}
