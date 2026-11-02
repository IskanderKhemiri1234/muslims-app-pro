
import 'app_event_schema_migration_audit_repository_scope_context_registry_module_initialization_guard.dart';
import 'app_event_schema_migration_audit_repository_scope_context_registry_module_initialization_guard_provider.dart';

/// Optional factory for creating a provider around an existing
/// initialization guard.
///
/// This factory:
/// - Requires an already-created guard.
/// - Never creates an initialization guard.
/// - Never takes ownership of the supplied guard.
/// - Never requests or consumes initialization permits.
/// - Never initializes or disposes external resources.
/// - Returns a provider that references the exact supplied guard.
///
/// The Composition Root remains responsible for:
/// - Creating and retaining the guard.
/// - Retaining the returned provider for the intended scope.
/// - Coordinating initialization and permit consumption.
/// - Preventing overlapping initialization operations.
final class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactory {
  /// Creates a stateless factory.
  const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactory();

  /// Creates a provider around [guard].
  ///
  /// The supplied guard must already exist and must not be disabled.
  ///
  /// The returned provider references the same guard instance.
  /// No guard is created, cloned, replaced, or transferred.
  ///
  /// Throws [ArgumentError] when [guard] is disabled.
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProvider
      create({
    required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuard
        guard,
  }) {
    if (guard.isDisposed) {
      throw ArgumentError.value(
        guard,
        'guard',
        'The initialization guard must be active.',
      );
    }

    return AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProvider(
      guard: guard,
    );
  }
}
