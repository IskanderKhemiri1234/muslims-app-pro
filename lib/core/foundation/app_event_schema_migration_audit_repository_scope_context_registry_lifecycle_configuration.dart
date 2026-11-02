
import 'app_clock.dart';
import 'app_event_schema_migration_audit_repository_scope_context_registry_lifecycle_observer.dart';

/// Determines which lifecycle transition outcomes produce notifications.
enum AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleNotificationPolicy {
  all,
  acceptedOnly,
  rejectedOnly,
  disabled,
}

/// Immutable configuration for registry lifecycle notifications.
///
/// This configuration describes policies and injected dependencies only.
/// It does not create, own, initialize, or dispose any external resource.
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
  /// The configuration retains the reference supplied by the composition root.
  /// It does not own or dispose the clock.
  final AppClock clock;

  /// Handles failures raised by lifecycle observers.
  ///
  /// The configuration does not own or dispose the error handler.
  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleObserverErrorHandler
      observerErrorHandler;

  /// Controls which transition outcomes are published to observers.
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
  bool get notificationsEnabled =>
      notificationPolicy !=
      AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleNotificationPolicy
          .disabled;

  /// Determines whether a notification should be emitted for an outcome.
  bool shouldNotify({
    required bool transitionAccepted,
  }) {
    return transitionAccepted
        ? notifyAcceptedTransitions
        : notifyRejectedTransitions;
  }
}
