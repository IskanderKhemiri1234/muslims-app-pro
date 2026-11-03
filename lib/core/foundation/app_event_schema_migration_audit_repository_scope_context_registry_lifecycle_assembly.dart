
import 'app_event_schema_migration_audit_repository_scope_context_registry_lifecycle_configuration.dart';
import 'app_event_schema_migration_audit_repository_scope_context_registry_lifecycle_controller.dart';
import 'app_event_schema_migration_audit_repository_scope_context_registry_module.dart';

/// Immutable assembly of the scope context registry lifecycle components.
///
/// Responsibilities:
/// - Retains the lifecycle controller.
/// - Retains the lifecycle configuration.
/// - Exposes the initial and current lifecycle state.
/// - Provides a consistent lifecycle composition boundary.
///
/// Ownership contract:
/// - The assembly does not own the registry module.
/// - The assembly does not own the scope context registry.
/// - The assembly does not own the observer dispatcher.
/// - The assembly does not own the clock or observer error handler.
/// - The assembly does not initialize or dispose external resources.
/// - The assembly does not perform lifecycle transitions.
///
/// The lifecycle coordinator is responsible for orchestrating transitions
/// and coordinating the module and observer dispatcher lifecycles.
final class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleAssembly {
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleAssembly({
    required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleController
        controller,
    required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleConfiguration
        configuration,
  })  : _controller = controller,
        _configuration = configuration;

  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleController
      _controller;

  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleConfiguration
      _configuration;

  /// The lifecycle controller retained by this assembly.
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleController
      get controller => _controller;

  /// The lifecycle configuration retained by this assembly.
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleConfiguration
      get configuration => _configuration;

  /// Current lifecycle state.
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleState
      get currentState => _controller.currentState;

  /// Current lifecycle revision.
  int get revision => _controller.revision;

  /// Whether the lifecycle controller has reached its terminal state.
  bool get isDisposed => _controller.isDisposed;

  /// Whether a transition to [requestedState] is currently permitted.
  ///
  /// This method delegates validation to the controller and does not
  /// perform or mutate a lifecycle transition.
  bool canTransitionTo({
    required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleState
        requestedState,
  }) {
    return _controller.canTransitionTo(
      nextState: requestedState,
    );
  }

  /// Validates a requested lifecycle state without changing the state.
  ///
  /// The returned result is produced by the lifecycle controller's
  /// transition rules.
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleTransitionResult
      validateTransition({
    required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleState
        requestedState,
  }) {
    return _controller.validateNextState(
      nextState: requestedState,
    );
  }
}

/// Creates lifecycle assemblies from explicitly supplied dependencies.
///
/// The factory creates only a lifecycle controller and an assembly.
/// It does not create or own a registry module, dispatcher, registry,
/// clock, observer, or external resource.
abstract interface class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleAssemblyFactory {
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleAssembly
      create({
    required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleConfiguration
        configuration,
    AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleState
        initialState =
        AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleState
            .uninitialized,
  });
}

/// Default implementation of the lifecycle assembly factory.
final class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleAssemblyFactoryImpl
    implements
        AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleAssemblyFactory {
  const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleAssemblyFactoryImpl();

  @override
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleAssembly
      create({
    required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleConfiguration
        configuration,
    AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleState
        initialState =
        AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleState
            .uninitialized,
  }) {
    final controller =
        AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleController(
      initialState: initialState,
    );

    return AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleAssembly(
      controller: controller,
      configuration: configuration,
    );
  }
}
