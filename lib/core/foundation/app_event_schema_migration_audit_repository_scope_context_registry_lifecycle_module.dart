
import 'app_event_schema_migration_audit_repository_scope_context_registry_module.dart';
import 'app_event_schema_migration_audit_repository_scope_context_registry_lifecycle_factory.dart';
import 'app_event_schema_migration_audit_repository_scope_context_registry_lifecycle_observer.dart';

/// Coordinates access to the lifecycle components associated with the
/// audit repository scope context registry.
///
/// This module is a non-owning dependency assembly boundary.
///
/// It exposes the registry module, lifecycle assembly, lifecycle controller,
/// lifecycle configuration, and observer dispatcher supplied by the
/// composition root.
///
/// It does not create, initialize, transition, or dispose these resources.
///
/// Resource ownership and lifecycle orchestration remain with the
/// composition root or its explicitly designated coordinator.
final class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModule {
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
  /// This getter does not initialize the registry module or transfer
  /// ownership to this lifecycle module.
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModule
      get registryModule => _registryModule;

  /// Returns the externally owned lifecycle assembly.
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleAssembly
      get lifecycleAssembly => _lifecycleAssembly;

  /// Returns the controller contained in the supplied lifecycle assembly.
  ///
  /// The controller is not created, replaced, or disposed here.
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleController
      get lifecycleController => _lifecycleAssembly.controller;

  /// Returns the immutable configuration contained in the assembly.
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleConfiguration
      get lifecycleConfiguration => _lifecycleAssembly.configuration;

  /// Returns the externally owned observer dispatcher.
  ///
  /// No subscriptions or notifications are created by this getter.
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleObserverDispatcher
      get observerDispatcher => _observerDispatcher;

  /// Indicates that all required dependencies were supplied.
  ///
  /// This confirms dependency assembly only. It does not indicate that
  /// initialization has completed or that any resource is active.
  bool get isConfigured => true;

  /// Indicates whether the lifecycle assembly reports a disposed state.
  ///
  /// This is a read-only query and does not dispose any resource.
  bool get isLifecycleDisposed => _lifecycleAssembly.isDisposed;
}
