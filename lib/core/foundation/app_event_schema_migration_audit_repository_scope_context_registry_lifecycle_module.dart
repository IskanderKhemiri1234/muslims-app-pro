
import 'app_event_schema_migration_audit_repository_scope_context_registry_lifecycle_assembly.dart';
import 'app_event_schema_migration_audit_repository_scope_context_registry_lifecycle_observer.dart';
import 'app_event_schema_migration_audit_repository_scope_context_registry_module.dart';

/// Provides a unified, non-owning access boundary for the
/// Scope Context Registry lifecycle components.
///
/// Ownership remains with the Composition Root and Coordinator.
/// This wrapper does not initialize, dispose, or mutate the lifecycle
/// components independently.
final class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModule {
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModule({
    required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModule
        registryModule,
    required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleAssembly
        lifecycleAssembly,
    required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleObserverDispatcher
        observerDispatcher,
  })  : _registryModule = registryModule,
        _lifecycleAssembly = lifecycleAssembly,
        _observerDispatcher = observerDispatcher;

  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModule
      _registryModule;

  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleAssembly
      _lifecycleAssembly;

  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleObserverDispatcher
      _observerDispatcher;

  /// The registry module managed by the coordinator.
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModule
      get registryModule => _registryModule;

  /// The lifecycle assembly containing the controller and configuration.
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleAssembly
      get lifecycleAssembly => _lifecycleAssembly;

  /// The lifecycle controller responsible for state transitions.
  get lifecycleController => _lifecycleAssembly.controller;

  /// The immutable lifecycle configuration.
  get lifecycleConfiguration => _lifecycleAssembly.configuration;

  /// The dispatcher used for lifecycle notifications.
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleObserverDispatcher
      get observerDispatcher => _observerDispatcher;

  /// Whether all required references are available and not disposed.
  bool get isConfigured =>
      !_registryModule.isDisposed &&
      !_lifecycleAssembly.isDisposed &&
      !_observerDispatcher.isDisposed;

  /// Whether the lifecycle controller has reached its terminal state.
  bool get isLifecycleDisposed => _lifecycleAssembly.isDisposed;

  /// Whether the registry module has been disposed.
  bool get isRegistryModuleDisposed => _registryModule.isDisposed;

  /// Whether the observer dispatcher has been disposed.
  bool get isObserverDispatcherDisposed => _observerDispatcher.isDisposed;
}
