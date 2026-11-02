
import 'app_event_schema_migration_audit_repository_scope_context_registry_module.dart';
import 'app_event_schema_migration_audit_repository_scope_context_registry_lifecycle_factory.dart';
import 'app_event_schema_migration_audit_repository_scope_context_registry_lifecycle_observer.dart';

/// Coordinates the lifecycle components associated with the audit
/// repository scope context registry.
///
/// This module is deliberately non-owning.
///
/// Responsibilities:
/// - Exposes the registry module supplied by the composition root.
/// - Exposes the lifecycle assembly supplied by the composition root.
/// - Exposes the lifecycle controller and configuration from that assembly.
/// - Exposes the externally created observer dispatcher.
///
/// Ownership rules:
/// - Does not create any of its dependencies.
/// - Does not initialize or dispose external resources.
/// - Does not own the registry module.
/// - Does not own the lifecycle assembly or its controller.
/// - Does not own the observer dispatcher.
///
/// Resource creation, initialization, orchestration, and disposal remain
/// the responsibility of the external composition root or its coordinator.
class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModule {
  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModule
      _registryModule;

  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleAssembly
      _lifecycleAssembly;

  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleObserverDispatcher
      _observerDispatcher;

  const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModule({
    required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModule
        registryModule,
    required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleAssembly
        lifecycleAssembly,
    required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleObserverDispatcher
        observerDispatcher,
  })  : _registryModule = registryModule,
        _lifecycleAssembly = lifecycleAssembly,
        _observerDispatcher = observerDispatcher;

  /// Returns the externally owned registry module.
  ///
  /// This getter does not initialize the registry module and does not
  /// transfer ownership to this lifecycle module.
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModule
      get registryModule => _registryModule;

  /// Returns the lifecycle assembly supplied by the composition root.
  ///
  /// The assembly remains externally owned.
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleAssembly
      get lifecycleAssembly => _lifecycleAssembly;

  /// Returns the lifecycle controller contained in the supplied assembly.
  ///
  /// The controller is exposed without creating, replacing, or disposing it.
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleController
      get lifecycleController => _lifecycleAssembly.controller;

  /// Returns the immutable lifecycle configuration contained in the assembly.
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleConfiguration
      get lifecycleConfiguration => _lifecycleAssembly.configuration;

  /// Returns the externally created observer dispatcher.
  ///
  /// This getter exposes the same dispatcher instance supplied to the
  /// constructor. It does not create subscriptions, dispatch notifications,
  /// or assume ownership of the dispatcher.
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleObserverDispatcher
      get observerDispatcher => _observerDispatcher;

  /// Indicates that all required dependencies were supplied.
  ///
  /// Since the constructor requires non-null dependencies, this confirms
  /// dependency assembly only. It does not indicate that initialization
  /// has completed or that the underlying resources are active.
  bool get isConfigured => true;

  /// Indicates whether the lifecycle controller has reached its disposed
  /// state.
  ///
  /// This is a read-only state query. It does not dispose the controller,
  /// assembly, registry module, or observer dispatcher.
  bool get isLifecycleDisposed => _lifecycleAssembly.isDisposed;
}
