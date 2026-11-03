
import 'app_event_schema_migration_audit_query.dart';
import 'app_event_schema_migration_audit_reader.dart';
import 'app_event_schema_migration_audit_repository_scope_context.dart';
import 'app_event_schema_migration_audit_scope_operation.dart';

/// Executes a paginated audit read through the repository
/// associated with the supplied active scope context.
final class AppEventSchemaMigrationAuditFindPageScopeOperation
    implements
        AppEventSchemaMigrationAuditScopeOperation<
          AppEventSchemaMigrationAuditQuery,
          AppEventSchemaMigrationAuditPage
        > {
  const AppEventSchemaMigrationAuditFindPageScopeOperation();

  @override
  Future<AppEventSchemaMigrationAuditPage> execute({
    required AppEventSchemaMigrationAuditRepositoryScopeContext context,
    required AppEventSchemaMigrationAuditQuery request,
  }) {
    return context.executeAsync(
      (repository) => repository.findPage(request),
    );
  }
}

/// Executes an audit record count through the repository
/// associated with the supplied active scope context.
final class AppEventSchemaMigrationAuditCountScopeOperation
    implements
        AppEventSchemaMigrationAuditScopeOperation<
          AppEventSchemaMigrationAuditFilter,
          int
        > {
  const AppEventSchemaMigrationAuditCountScopeOperation();

  @override
  Future<int> execute({
    required AppEventSchemaMigrationAuditRepositoryScopeContext context,
    required AppEventSchemaMigrationAuditFilter request,
  }) {
    return context.executeAsync(
      (repository) => repository.count(filter: request),
    );
  }
}
