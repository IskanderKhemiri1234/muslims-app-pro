
import 'app_event_schema_migration_audit_repository.dart';
import 'app_event_schema_migration_audit_query.dart';
import 'app_event_schema_migration_audit_reader.dart';
import 'app_event_schema_migration_audit_repository_scope_context.dart';
import 'app_event_schema_migration_audit_scope_operation.dart';

/// Executes a paginated audit repository read within the supplied scope.
///
/// The repository is obtained exclusively from the supplied context.
/// No repository reference is captured or retained by this operation.
final class AppEventSchemaMigrationAuditFindPageScopeOperation
    implements
        AppEventSchemaMigrationAuditScopeOperation<
            AppEventSchemaMigrationAuditQuery,
            AppEventSchemaMigrationAuditPage> {
  const AppEventSchemaMigrationAuditFindPageScopeOperation();

  @override
  Future<AppEventSchemaMigrationAuditPage> execute({
    required AppEventSchemaMigrationAuditRepositoryScopeContext context,
    required AppEventSchemaMigrationAuditQuery request,
  }) {
    return context.execute(
      (repository) => repository.findPage(request),
    );
  }
}

/// Executes an audit record count within the supplied scope.
///
/// The repository is obtained exclusively from the supplied context.
/// No repository reference is captured or retained by this operation.
final class AppEventSchemaMigrationAuditCountScopeOperation
    implements
        AppEventSchemaMigrationAuditScopeOperation<
            AppEventSchemaMigrationAuditFilter,
            int> {
  const AppEventSchemaMigrationAuditCountScopeOperation();

  @override
  Future<int> execute({
    required AppEventSchemaMigrationAuditRepositoryScopeContext context,
    required AppEventSchemaMigrationAuditFilter request,
  }) {
    return context.execute(
      (repository) => repository.count(
        filter: request,
      ),
    );
  }
}
