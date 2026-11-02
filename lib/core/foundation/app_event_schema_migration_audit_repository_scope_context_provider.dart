
import 'app_event_schema_migration_audit_repository_scope_context.dart';
import 'app_event_schema_migration_audit_repository_scope_resolver.dart';

/// Provides repository scope contexts to application services.
///
/// This provider is deliberately limited to dependency resolution:
/// - It receives an existing scope resolver through constructor injection.
/// - It resolves only scopes that have already been registered.
/// - It creates contexts from successful resolver results.
/// - It does not create, register, unregister, or dispose scopes.
/// - It does not create, own, or dispose repositories.
/// - It does not use a global repository provider.
final class AppEventSchemaMigrationAuditRepositoryScopeContextProvider {
  final AppEventSchemaMigrationAuditRepositoryScopeResolver _resolver;

  AppEventSchemaMigrationAuditRepositoryScopeContextProvider({
    required AppEventSchemaMigrationAuditRepositoryScopeResolver resolver,
  }) : _resolver = resolver;

  /// Resolves an existing scope and returns its execution context.
  ///
  /// The identifier is normalized before it is passed to the resolver.
  /// Resolver errors and context validation errors are allowed to propagate
  /// unchanged so callers can handle the original failure information.
  AppEventSchemaMigrationAuditRepositoryScopeContext provide({
    required String scopeId,
  }) {
    final normalizedScopeId = scopeId.trim();

    if (normalizedScopeId.isEmpty) {
      throw const AppEventSchemaMigrationAuditRepositoryScopeContextException(
        AppEventSchemaMigrationAuditRepositoryScopeContextError.invalidScopeId,
      );
    }

    final resolution = _resolver.resolve(normalizedScopeId);

    return AppEventSchemaMigrationAuditRepositoryScopeContext.fromResolution(
      resolution: resolution,
    );
  }

  /// Provides a context and executes a synchronous operation through it.
  ///
  /// The context validates the scope immediately before exposing the
  /// repository to the operation.
  T provideAndExecute<T>({
    required String scopeId,
    required T Function(
      AppEventSchemaMigrationAuditRepositoryScopeContext context,
    ) operation,
  }) {
    final context = provide(scopeId: scopeId);

    context.verifyActive();

    return operation(context);
  }

  /// Provides a context and starts an asynchronous operation through it.
  ///
  /// The scope is validated before the callback starts. This method does not
  /// lock the scope or prevent its disposal while the returned future runs.
  Future<T> provideAndExecuteAsync<T>({
    required String scopeId,
    required Future<T> Function(
      AppEventSchemaMigrationAuditRepositoryScopeContext context,
    ) operation,
  }) {
    final context = provide(scopeId: scopeId);

    context.verifyActive();

    return operation(context);
  }
}
