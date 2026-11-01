
/// Represents the lifecycle state of the application independently
/// of any UI framework or platform implementation.
enum AppLifecycleState {
  /// The application is starting or its lifecycle is not yet known.
  unknown,

  /// The application is visible and actively executing.
  resumed,

  /// The application is visible but has temporarily lost focus.
  inactive,

  /// The application is running in the background.
  background,

  /// The application is no longer actively executing.
  paused,

  /// The application is being terminated.
  detached,

  /// The application has entered a shutdown sequence.
  terminating;

  /// Whether the application is currently in the foreground.
  bool get isForeground => this == resumed || this == inactive;

  /// Whether the application can safely perform foreground UI work.
  bool get isResumed => this == resumed;

  /// Whether the application is not actively visible.
  bool get isBackground =>
      this == background ||
      this == paused ||
      this == detached ||
      this == terminating;

  /// Whether the application has lost interactive focus.
  bool get hasLostFocus =>
      this == inactive ||
      this == background ||
      this == paused ||
      this == detached ||
      this == terminating;

  /// Whether the application is shutting down or detached.
  bool get isShuttingDown =>
      this == detached || this == terminating;

  /// Whether the state represents a known lifecycle condition.
  bool get isKnown => this != unknown;
}

/// Describes the origin of a lifecycle transition.
enum AppLifecycleEventSource {
  system,
  platform,
  application,
  test,
}

/// Immutable description of a lifecycle transition.
///
/// Every transition receives a sequence number so consumers can
/// identify ordering and ignore stale events.
final class AppLifecycleTransition {
  const AppLifecycleTransition({
    required this.previousState,
    required this.currentState,
    required this.sequence,
    required this.timestamp,
    required this.source,
  });

  final AppLifecycleState previousState;
  final AppLifecycleState currentState;

  /// Monotonically increasing sequence number within the event source.
  final int sequence;

  /// Time at which the transition was observed.
  ///
  /// The timestamp is supplied by the lifecycle coordinator.
  final DateTime timestamp;

  final AppLifecycleEventSource source;

  bool get enteredForeground =>
      !previousState.isForeground && currentState.isForeground;

  bool get enteredBackground =>
      !previousState.isBackground && currentState.isBackground;

  bool get resumed =>
      previousState != AppLifecycleState.resumed &&
      currentState == AppLifecycleState.resumed;

  bool get isStateChange => previousState != currentState;
}

/// Defines lifecycle transition validation rules.
abstract final class AppLifecycleRules {
  AppLifecycleRules._();

  /// Determines whether a transition is permitted.
  ///
  /// Transitions to unknown are rejected because unknown represents
  /// the absence of reliable lifecycle information, not an active
  /// runtime event.
  static bool canTransition(
    AppLifecycleState from,
    AppLifecycleState to,
  ) {
    if (from == to) {
      return true;
    }

    if (to == AppLifecycleState.unknown) {
      return false;
    }

    if (from == AppLifecycleState.terminating) {
      return false;
    }

    if (from == AppLifecycleState.detached) {
      return to == AppLifecycleState.resumed ||
          to == AppLifecycleState.terminating;
    }

    return true;
  }

  /// Determines whether a transition should notify subscribers.
  static bool shouldNotify(
    AppLifecycleState from,
    AppLifecycleState to,
  ) {
    return from != to;
  }
}
