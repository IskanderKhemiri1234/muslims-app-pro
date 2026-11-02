
import 'app_clock.dart';
import 'app_event_schema_migration_audit_repository_scope_context_registry_lifecycle_observer.dart';

/// Determines which lifecycle transition outcomes produce notifications.
enum AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleNotificationPolicy {
  /// Publishes notifications for both accepted and rejected transitions.
  all,

  /// Publishes notifications only for accepted transitions.
  acceptedOnly,

  /// Publishes notifications only for rejected transitions.
  rejectedOnly,

  /// Disables all lifecycle notifications.
  disabled,
}

/// Immutable configuration for registry lifecycle notifications.
///
/// This configuration contains policies and externally supplied dependencies.
///
/// Ownership contract:
/// - The composition root owns the injected [AppClock].
/// - The composition root owns the injected observer error handler.
/// - This configuration only retains references to those dependencies.
/// - This configuration does not create, initialize, or dispose resources.
final class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleConfiguration {
  const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleConfiguration({
    required this.clock,
    required this.observerErrorHandler,
    this.notificationPolicy =
        AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleNotificationPolicy
            .all,
  });

  /// Injected application clock used to timestamp lifecycle notifications.
  ///
  /// The configuration retains the supplied reference without taking
  /// ownership of the clock.
  final AppClock clock;

  /// Injected handler for failures raised by lifecycle observers.
  ///
  /// The configuration retains the supplied reference without taking
  /// ownership of the handler.
  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleObserverErrorHandler
      observerErrorHandler;

  /// Policy controlling which lifecycle transition outcomes are published.
  ///
  /// Defaults to [AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleNotificationPolicy.all].
  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleNotificationPolicy
      notificationPolicy;

  /// Whether accepted transitions should be published.
  bool get notifyAcceptedTransitions =>
      notificationPolicy ==
          AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleNotificationPolicy
              .all ||
      notificationPolicy ==
          AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleNotificationPolicy
              .acceptedOnly;

  /// Whether rejected transitions should be published.
  bool get notifyRejectedTransitions =>
      notificationPolicy ==
          AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleNotificationPolicy
              .all ||
      notificationPolicy ==
          AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleNotificationPolicy
              .rejectedOnly;

  /// Whether lifecycle notifications are enabled.
  ///
  /// Returns false only when the policy is [disabled].
  bool get notificationsEnabled =>
      notificationPolicy !=
      AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleNotificationPolicy
          .disabled;

  /// Determines whether a notification should be emitted for a transition.
  ///
  /// The caller must pass the actual outcome returned by the lifecycle
  /// controller. This method does not validate or perform transitions.
  bool shouldNotify({
    required bool transitionAccepted,
  }) {
    return transitionAccepted
        ? notifyAcceptedTransitions
        : notifyRejectedTransitions;
  }
}
