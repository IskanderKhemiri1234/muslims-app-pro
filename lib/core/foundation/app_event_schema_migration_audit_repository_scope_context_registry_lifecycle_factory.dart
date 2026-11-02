
import 'app_event_schema_migration_audit_repository_scope_context_registry_lifecycle_configuration.dart';
import 'app_event_schema_migration_audit_repository_scope_context_registry_lifecycle_controller.dart';
import 'app_event_schema_migration_audit_repository_scope_context_registry_module.dart';

/// Immutable collection of lifecycle components prepared by the factory.
///
/// The composition root receives this assembly and remains responsible
/// for retaining and coordinating the returned components.
final class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleAssembly {
  const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleAssembly({
    required this.controller,
    required this.configuration,
  });

  /// Controls lifecycle state transitions.
  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleController
      controller;

  /// Supplies lifecycle notification policies and injected dependencies.
  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleConfiguration
      configuration;

  /// Returns the controller's current lifecycle state.
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleState
      get currentState => controller.currentState;

  /// Indicates whether the lifecycle has reached its terminal state.
  bool get isDisposed => controller.isDisposed;
}

/// Contract for creating a lifecycle component assembly.
abstract interface class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleFactory {
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleAssembly
      create({
    required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleConfiguration
        configuration,
    AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleState
        initialState,
  });
}

/// Default factory for registry lifecycle components.
///
/// This factory creates only the lifecycle controller and its immutable
/// assembly. It does not create a dispatcher, observer, registry, provider,
/// or module. It does not initialize or dispose external resources.
final class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleFactoryImpl
    implements
        AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleFactory {
  const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleFactoryImpl();

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
