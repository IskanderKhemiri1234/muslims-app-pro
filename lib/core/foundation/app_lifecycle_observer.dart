
/// A contract implemented by objects that need to react to application
/// lifecycle transitions.
abstract interface class AppLifecycleObserver {
  void onLifecycleChanged(AppLifecycleTransition transition);
}

/// A callback-based lifecycle observer.
///
/// This adapter allows services to subscribe using a function without
/// creating a dedicated observer class.
final class CallbackAppLifecycleObserver
    implements AppLifecycleObserver {
  CallbackAppLifecycleObserver(this._callback);

  final AppLifecycleCallback _callback;

  @override
  void onLifecycleChanged(AppLifecycleTransition transition) {
    _callback(transition);
  }
}

/// Callback signature used by [CallbackAppLifecycleObserver].
typedef AppLifecycleCallback = void Function(
  AppLifecycleTransition transition,
);

/// Represents a failure thrown by an observer during event dispatch.
///
/// A failure is isolated so that one observer cannot prevent other observers
/// from receiving the same lifecycle transition.
final class AppLifecycleObserverFailure {
  const AppLifecycleObserverFailure({
    required this.observer,
    required this.error,
    required this.stackTrace,
  });

  final AppLifecycleObserver observer;
  final Object error;
  final StackTrace stackTrace;
}

/// Describes the outcome of dispatching a lifecycle transition.
final class AppLifecycleDispatchReport {
  AppLifecycleDispatchReport({
    required this.invokedCount,
    required List<AppLifecycleObserverFailure> failures,
  }) : failures = List<AppLifecycleObserverFailure>.unmodifiable(
          failures,
        );

  /// Number of observer callbacks that were invoked.
  ///
  /// This includes callbacks that threw an exception.
  final int invokedCount;

  /// Errors thrown by observers during dispatch.
  final List<AppLifecycleObserverFailure> failures;

  /// Number of callbacks that completed without throwing.
  int get successfulCount => invokedCount - failures.length;

  /// Whether at least one observer failed.
  bool get hasFailures => failures.isNotEmpty;

  /// Whether every invoked callback completed successfully.
  bool get wasSuccessful => failures.isEmpty;
}

/// Internal registration record shared by the registry and subscription.
final class _AppLifecycleObserverEntry {
  _AppLifecycleObserverEntry({
    required this.id,
    required this.observer,
    required AppLifecycleObserverRegistry owner,
  }) : _owner = owner;

  final int id;
  final AppLifecycleObserver observer;

  AppLifecycleObserverRegistry? _owner;

  bool _isActive = true;

  bool get isActive => _isActive;

  void deactivate() {
    if (!_isActive) {
      return;
    }

    _isActive = false;

    final owner = _owner;
    _owner = null;

    owner?._removeEntry(id, this);
  }
}

/// Handle representing one observer registration.
///
/// Calling [cancel] multiple times is safe. The handle also reflects
/// cancellation performed by its owning registry.
final class AppLifecycleSubscription {
  AppLifecycleSubscription._(this._entry);

  final _AppLifecycleObserverEntry _entry;

  /// Whether this subscription is currently active.
  bool get isActive => _entry.isActive;

  /// Cancels this subscription.
  ///
  /// This operation is idempotent.
  void cancel() {
    _entry.deactivate();
  }
}

/// Manages lifecycle observers and dispatches lifecycle transitions.
///
/// Responsibilities:
/// - Registering and removing observers.
/// - Preserving registration order.
/// - Safely handling modifications during dispatch.
/// - Isolating observer exceptions.
/// - Preventing registrations after disposal.
///
/// This class does not listen to the operating system and does not depend
/// on Flutter or any UI framework.
final class AppLifecycleObserverRegistry {
  final Map<int, _AppLifecycleObserverEntry> _entries =
      <int, _AppLifecycleObserverEntry>{};

  int _nextId = 0;

  bool _isDisposed = false;

  /// Number of currently registered observers.
  int get length => _entries.length;

  /// Whether the registry contains no active observers.
  bool get isEmpty => _entries.isEmpty;

  /// Whether at least one observer is registered.
  bool get hasObservers => _entries.isNotEmpty;

  /// Whether this registry has been disposed.
  bool get isDisposed => _isDisposed;

  /// Registers [observer] and returns its subscription handle.
  ///
  /// Observers are invoked in registration order.
  ///
  /// A newly registered observer is not invoked during a dispatch that
  /// was already in progress when it was registered.
  AppLifecycleSubscription add(AppLifecycleObserver observer) {
    _ensureNotDisposed();

    final id = _nextId++;

    final entry = _AppLifecycleObserverEntry(
      id: id,
      observer: observer,
      owner: this,
    );

    _entries[id] = entry;

    return AppLifecycleSubscription._(entry);
  }

  /// Registers a callback without requiring an observer implementation.
  AppLifecycleSubscription addCallback(
    AppLifecycleCallback callback,
  ) {
    return add(CallbackAppLifecycleObserver(callback));
  }

  /// Dispatches a lifecycle transition to all eligible observers.
  ///
  /// The registry uses a snapshot of registration identifiers:
  /// - Observers removed before their turn are skipped.
  /// - Observers added during dispatch wait until the next dispatch.
  /// - Observer exceptions are captured in the returned report.
  ///
  /// Transitions that should not notify observers according to
  /// [AppLifecycleRules.shouldNotify] are ignored.
  AppLifecycleDispatchReport dispatch(
    AppLifecycleTransition transition,
  ) {
    _ensureNotDisposed();

    if (!AppLifecycleRules.shouldNotify(transition)) {
      return AppLifecycleDispatchReport(
        invokedCount: 0,
        failures: const <AppLifecycleObserverFailure>[],
      );
    }

    final observerIds = List<int>.of(_entries.keys);

    final failures = <AppLifecycleObserverFailure>[];
    var invokedCount = 0;

    for (final id in observerIds) {
      final entry = _entries[id];

      if (entry == null || !entry.isActive) {
        continue;
      }

      invokedCount++;

      try {
        entry.observer.onLifecycleChanged(transition);
      } catch (error, stackTrace) {
        failures.add(
          AppLifecycleObserverFailure(
            observer: entry.observer,
            error: error,
            stackTrace: stackTrace,
          ),
        );
      }
    }

    return AppLifecycleDispatchReport(
      invokedCount: invokedCount,
      failures: failures,
    );
  }

  /// Removes every registered observer.
  ///
  /// Existing subscription handles become inactive.
  /// The registry remains usable after this operation.
  void clear() {
    final entries = List<_AppLifecycleObserverEntry>.of(
      _entries.values,
    );

    for (final entry in entries) {
      entry.deactivate();
    }
  }

  /// Permanently disposes this registry.
  ///
  /// All active subscriptions are cancelled. Further calls to [add],
  /// [addCallback], or [dispatch] throw a [StateError].
  ///
  /// Calling [dispose] repeatedly is safe.
  void dispose() {
    if (_isDisposed) {
      return;
    }

    _isDisposed = true;
    clear();
  }

  void _removeEntry(
    int id,
    _AppLifecycleObserverEntry entry,
  ) {
    if (identical(_entries[id], entry)) {
      _entries.remove(id);
    }
  }

  void _ensureNotDisposed() {
    if (_isDisposed) {
      throw StateError(
        'AppLifecycleObserverRegistry has been disposed.',
      );
    }
  }
}
