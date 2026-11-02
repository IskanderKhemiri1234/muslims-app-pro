
import 'app_event_schema_migration_audit_repository_scope_context_registry_module.dart';
import 'app_event_schema_migration_audit_repository_scope_context_registry_lifecycle_factory.dart';
import 'app_event_schema_migration_audit_repository_scope_context_registry_lifecycle_observer.dart';

/// Coordinates the lifecycle components associated with the audit
/// repository scope context registry.
///
/// This module is deliberately non-owning:
/// - It does not create the registry module.
/// - It does not create the lifecycle assembly.
/// - It does not create the observer dispatcher.
/// - It does not initialize or dispose external resources.
/// - Resource ownership remains with the external composition root.
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

  /// The externally owned registry module.
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModule
      get registryModule =>
          _registryModule;

  /// The lifecycle assembly supplied by the external composition root.
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleAssembly
      get lifecycleAssembly =>
          _lifecycleAssembly;

  /// The lifecycle controller contained in the supplied assembly.
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleController
      get lifecycleController =>
          _lifecycleAssembly.controller;

  /// The immutable lifecycle configuration contained in the assembly.
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleConfiguration
      get lifecycleConfiguration =>
          _lifecycleAssembly.configuration;

  /// The externally created observer dispatcher.
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleObserverDispatcher
      get observerDispatcher =>
          _observerDispatcher;

  /// Indicates that all required lifecycle components were supplied.
  ///
  /// The constructor requires non-null dependencies, so this value confirms
  /// dependency assembly only. It does not imply that the registry module
  /// has been initialized or that its resources are currently active.
  bool get isConfigured => true;

  /// Indicates whether the lifecycle controller has reached its disposed
  /// state. This does not dispose the controller or any related resource.
  bool get isLifecycleDisposed =>
      _lifecycleAssembly.isDisposed;
}
