
import 'app_event_schema_migration_audit_repository_scope_context_registry_lifecycle_controller.dart';
import 'app_event_schema_migration_audit_repository_scope_context_registry_module.dart';

/// Describes the kind of lifecycle notification being delivered.
enum AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleNotificationType {
  transitionAccepted,
  transitionRejected,
}

/// Immutable lifecycle notification delivered to observers.
final class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleNotification {
  const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleNotification({
    required this.type,
    required this.snapshot,
    required this.occurredAt,
  });

  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleNotificationType
      type;

  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleSnapshot
      snapshot;

  final DateTime occurredAt;

  bool get isAccepted =>
      type ==
      AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleNotificationType
          .transitionAccepted;

  bool get isRejected => !isAccepted;

  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleState
      get previousState => snapshot.previousState;

  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleState
      get currentState => snapshot.currentState;

  int get revision => snapshot.revision;
}

/// Receives lifecycle notifications from the notification dispatcher.
///
/// Implementations must not assume ownership of the registry module or
/// any resource associated with it.
abstract interface class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleObserver {
  void onLifecycleNotification(
    AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleNotification
        notification,
  );
}

/// Callback-based lifecycle observer.
final class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleCallbackObserver
    implements
        AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleObserver {
  const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleCallbackObserver({
    required this.onNotification,
  });

  final void Function(
    AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleNotification
        notification,
  ) onNotification;

  @override
  void onLifecycleNotification(
    AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleNotification
        notification,
  ) {
    onNotification(notification);
  }
}

/// Describes an observer delivery failure.
final class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleObserverFailure {
  const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleObserverFailure({
    required this.observer,
    required this.notification,
    required this.error,
    required this.stackTrace,
  });

  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleObserver
      observer;

  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleNotification
      notification;

  final Object error;

  final StackTrace stackTrace;
}

/// Reports failures raised while notifying lifecycle observers.
abstract interface class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleObserverErrorHandler {
  void onObserverFailure(
    AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleObserverFailure
        failure,
  );
}

/// Default error handler that intentionally does not throw.
final class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleSilentErrorHandler
    implements
        AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleObserverErrorHandler {
  const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleSilentErrorHandler();

  @override
  void onObserverFailure(
    AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleObserverFailure
        failure,
  ) {}
}

/// Identifies the outcome of an observer subscription operation.
enum AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleObserverSubscriptionStatus {
  subscribed,
  alreadySubscribed,
  dispatcherDisposed,
}

/// Immutable result of an observer subscription operation.
final class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleObserverSubscriptionResult {
  const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleObserverSubscriptionResult({
    required this.status,
    required this.subscription,
  });

  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleObserverSubscriptionStatus
      status;

  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleObserverSubscription?
      subscription;

  bool get isSubscribed =>
      status ==
      AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleObserverSubscriptionStatus
          .subscribed;
}

/// Represents one observer registration.
///
/// Cancelling a subscription removes only its observer registration.
/// It does not dispose the observer or any external resource.
final class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleObserverSubscription {
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleObserverSubscription._({
    required this.observer,
    required this.onCancel,
  });

  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleObserver
      observer;

  final void Function(
    AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleObserverSubscription
        subscription,
  ) onCancel;

  bool _isCancelled = false;

  bool get isCancelled => _isCancelled;

  void cancel() {
    if (_isCancelled) {
      return;
    }

    _isCancelled = true;
    onCancel(this);
  }
}

/// Dispatches lifecycle notifications to registered observers.
///
/// The dispatcher manages observer registrations only. It does not own
/// observers, the lifecycle controller, the registry module, or external
/// resources.
final class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleObserverDispatcher {
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleObserverDispatcher({
    AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleObserverErrorHandler
        errorHandler =
        const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleSilentErrorHandler(),
  }) : _errorHandler = errorHandler;

  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleObserverErrorHandler
      _errorHandler;

  final Set<
          AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleObserverSubscription>
      _subscriptions = {};

  bool _isDisposed = false;

  bool get isDisposed => _isDisposed;

  int get observerCount => _subscriptions.length;

  /// Registers an observer unless it is already registered.
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleObserverSubscriptionResult
      subscribe(
    AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleObserver
        observer,
  ) {
    if (_isDisposed) {
      return const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleObserverSubscriptionResult(
        status:
            AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleObserverSubscriptionStatus
                .dispatcherDisposed,
        subscription: null,
      );
    }

    for (final existing in _subscriptions) {
      if (!existing.isCancelled && identical(existing.observer, observer)) {
        return AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleObserverSubscriptionResult(
          status:
              AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleObserverSubscriptionStatus
                  .alreadySubscribed,
          subscription: existing,
        );
      }
    }

    late final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleObserverSubscription
        subscription;

    subscription =
        AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleObserverSubscription._(
      observer: observer,
      onCancel: _removeSubscription,
    );

    _subscriptions.add(subscription);

    return AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleObserverSubscriptionResult(
      status:
          AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleObserverSubscriptionStatus
              .subscribed,
      subscription: subscription,
    );
  }

  /// Delivers a notification to a stable snapshot of active subscriptions.
  ///
  /// Changes to subscriptions during delivery affect subsequent notifications,
  /// not the snapshot currently being processed.
  void dispatch(
    AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleNotification
        notification,
  ) {
    if (_isDisposed) {
      return;
    }

    final subscriptions = List<
            AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleObserverSubscription>.unmodifiable(
      _subscriptions,
    );

    for (final subscription in subscriptions) {
      if (_isDisposed) {
        break;
      }

      if (subscription.isCancelled ||
          !_subscriptions.contains(subscription)) {
        continue;
      }

      try {
        subscription.observer.onLifecycleNotification(notification);
      } catch (error, stackTrace) {
        _reportFailure(
          AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleObserverFailure(
            observer: subscription.observer,
            notification: notification,
            error: error,
            stackTrace: stackTrace,
          ),
        );
      }
    }
  }

  void _reportFailure(
    AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleObserverFailure
        failure,
  ) {
    try {
      _errorHandler.onObserverFailure(failure);
    } catch (_) {
      // Error reporting must not interrupt delivery to other observers.
    }
  }

  void _removeSubscription(
    AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleObserverSubscription
        subscription,
  ) {
    _subscriptions.remove(subscription);
  }

  /// Stops notification delivery and removes all registrations.
  ///
  /// Observers are not disposed. The dispatcher does not own them.
  void dispose() {
    if (_isDisposed) {
      return;
    }

    _isDisposed = true;

    final subscriptions = List<
            AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleObserverSubscription>.of(
      _subscriptions,
    );

    _subscriptions.clear();

    for (final subscription in subscriptions) {
      subscription.cancel();
    }
  }
}
