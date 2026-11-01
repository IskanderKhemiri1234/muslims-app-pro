
import 'app_clock.dart';
import 'app_lifecycle_observer.dart';
import 'app_lifecycle_state.dart';

/// Describes the outcome of requesting an application lifecycle transition.
enum AppLifecycleTransitionStatus {
  /// The requested state was accepted and dispatched.
  accepted,

  /// The requested state is already the current state.
  unchanged,

  /// The requested transition is not allowed by lifecycle rules.
  rejected,

  /// The controller has already been disposed.
  disposed,
}

/// Immutable result returned after processing a lifecycle state request.
final class AppLifecycleTransitionResult {
  const AppLifecycleTransitionResult({
    required this.status,
    required this.previousState,
    required this.currentState,
    required this.sequence,
    this.transition,
    this.dispatchReport,
    this.rejectionReason,
  });

  final AppLifecycleTransitionStatus status;

  final AppLifecycleState previousState;

  final AppLifecycleState currentState;

  /// Sequence number of the accepted transition.
  ///
  /// This remains unchanged for rejected and unchanged requests.
  final int sequence;

  /// The generated transition, if the request was accepted.
  final AppLifecycleTransition? transition;

  /// Observer dispatch outcome, if a transition was dispatched.
  final AppLifecycleDispatchReport? dispatchReport;

  /// Explanation for a rejected transition.
  final String? rejectionReason;

  bool get wasAccepted =>
      status == AppLifecycleTransitionStatus.accepted;

  bool get wasRejected =>
      status == AppLifecycleTransitionStatus.rejected;

  bool get wasUnchanged =>
      status == AppLifecycleTransitionStatus.unchanged;

  bool get isDisposed =>
      status == AppLifecycleTransitionStatus.disposed;

  bool get hasObserverFailures =>
      dispatchReport?.hasFailures ?? false;
}

/// Coordinates application lifecycle state transitions.
///
/// This class is independent of Flutter and operating-system APIs.
///
/// External lifecycle adapters should translate platform lifecycle events
/// into [AppLifecycleState] values and submit them through [transitionTo].
///
/// The controller:
/// - Validates state transitions.
/// - Maintains the current lifecycle state.
/// - Generates monotonically increasing transition sequence numbers.
/// - Timestamps transitions using an injected [AppClock].
/// - Dispatches accepted transitions to an injected observer registry.
final class AppLifecycleController {
  AppLifecycleController({
    required AppClock clock,
    required AppLifecycleObserverRegistry observerRegistry,
    AppLifecycleState initialState = AppLifecycleState.unknown,
    int initialSequence = 0,
    AppLifecycleEventSource initialSource =
        AppLifecycleEventSource.system,
  })  : _clock = clock,
        _observerRegistry = observerRegistry,
        _currentState = initialState,
        _sequence = initialSequence,
        _initialSource = initialSource {
    if (initialSequence < 0) {
      throw ArgumentError.value(
        initialSequence,
        'initialSequence',
        'Sequence must not be negative.',
      );
    }

    if (_observerRegistry.isDisposed) {
      throw StateError(
        'Cannot create an AppLifecycleController with a disposed '
        'observer registry.',
      );
    }
  }

  final AppClock _clock;
  final AppLifecycleObserverRegistry _observerRegistry;
  final AppLifecycleEventSource _initialSource;

  AppLifecycleState _currentState;
  int _sequence;

  bool _isDisposed = false;

  /// Current accepted lifecycle state.
  AppLifecycleState get currentState => _currentState;

  /// Sequence number of the most recently accepted transition.
  int get sequence => _sequence;

  /// Whether this controller has been disposed.
  bool get isDisposed => _isDisposed;

  /// Whether the application is currently in the foreground.
  bool get isForeground => _currentState.isForeground;

  /// Whether the application is currently resumed.
  bool get isResumed => _currentState.isResumed;

  /// Whether the application is currently in a background state.
  bool get isBackground => _currentState.isBackground;

  /// Requests a transition to [nextState].
  ///
  /// The controller validates the transition using [AppLifecycleRules].
  /// Accepted transitions receive a new sequence number and a timestamp
  /// from the injected clock.
  ///
  /// [source] identifies the adapter or subsystem that originated the event.
  ///
  /// If the requested state is unchanged, no event is generated.
  ///
  /// If the transition is rejected, the current state and sequence remain
  /// unchanged.
  AppLifecycleTransitionResult transitionTo(
    AppLifecycleState nextState, {
    AppLifecycleEventSource source = AppLifecycleEventSource.system,
  }) {
    if (_isDisposed) {
      return AppLifecycleTransitionResult(
        status: AppLifecycleTransitionStatus.disposed,
        previousState: _currentState,
        currentState: _currentState,
        sequence: _sequence,
      );
    }

    final previousState = _currentState;

    if (nextState == previousState) {
      return AppLifecycleTransitionResult(
        status: AppLifecycleTransitionStatus.unchanged,
        previousState: previousState,
        currentState: _currentState,
        sequence: _sequence,
      );
    }

    if (!AppLifecycleRules.canTransition(
      previousState,
      nextState,
    )) {
      return AppLifecycleTransitionResult(
        status: AppLifecycleTransitionStatus.rejected,
        previousState: previousState,
        currentState: _currentState,
        sequence: _sequence,
        rejectionReason:
            'Transition from $previousState to $nextState is not allowed.',
      );
    }

    final nextSequence = _sequence + 1;

    final transition = AppLifecycleTransition(
      previousState: previousState,
      currentState: nextState,
      sequence: nextSequence,
      timestamp: _clock.now,
      source: source,
    );

    // Commit the accepted state before notifying observers.
    // This ensures observers always see the latest accepted state.
    _currentState = nextState;
    _sequence = nextSequence;

    final dispatchReport = _observerRegistry.dispatch(transition);

    return AppLifecycleTransitionResult(
      status: AppLifecycleTransitionStatus.accepted,
      previousState: previousState,
      currentState: nextState,
      sequence: nextSequence,
      transition: transition,
      dispatchReport: dispatchReport,
    );
  }

  /// Restores the controller to a known state.
  ///
  /// This operation still follows the configured transition rules.
  /// It does not bypass validation or reset the sequence number.
  AppLifecycleTransitionResult restoreState(
    AppLifecycleState restoredState, {
    AppLifecycleEventSource source = AppLifecycleEventSource.restoration,
  }) {
    return transitionTo(
      restoredState,
      source: source,
    );
  }

  /// Permanently disposes the controller.
  ///
  /// The observer registry is not disposed here because it may be shared
  /// with other lifecycle-aware components.
  ///
  /// Calling this method repeatedly is safe.
  void dispose() {
    if (_isDisposed) {
      return;
    }

    _isDisposed = true;
  }
}
