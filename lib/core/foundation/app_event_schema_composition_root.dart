
import 'app_clock.dart';
import 'app_event_schema_registry.dart';
import 'app_event_schema_validator.dart';
import 'app_event_schema_migration.dart';
import 'app_event_schema_migration_audit.dart';
import 'app_event_schema_migration_audit_reader.dart';
import 'app_event_schema_migration_audit_repository.dart';
import 'app_event_schema_migration_audit_repository_scope.dart';
import 'app_event_schema_migration_audit_repository_scope_registry.dart';
import 'app_event_schema_migration_audit_repository_scope_resolver.dart';

/// Central composition root for the event schema subsystem.
///
/// Responsibilities:
/// - Creates and wires the schema registry and validator exactly once.
/// - Creates one migration executor using those same instances.
/// - Creates one shared audit sink for both writing and reading.
/// - Creates one audit reader and one repository adapter.
/// - Creates one scope registry and one resolver.
/// - Owns the lifecycle of scopes registered through this root.
///
/// This class does not use global state, service locators, or implicit
/// initialization.
///
/// The migration path resolver and validation callback are explicitly
/// supplied by the application because their behavior belongs to the
/// application's migration and validation policies.
final class AppEventSchemaCompositionRoot {
  AppEventSchemaCompositionRoot({
    Iterable<AppEventSchemaDefinition> definitions =
        const <AppEventSchemaDefinition>[],
    Iterable<AppEventSchemaMigration> migrations =
        const <AppEventSchemaMigration>[],
    required AppEventSchemaMigrationPathResolver pathResolver,
    required AppEventSchemaMigrationValidationCallback validationCallback,
    AppClock? clock,
    AppEventSchemaMigrationAuditIdGenerator? auditIdGenerator,
    int maximumNestingDepth = 32,
    int maximumAuditRecords = 1000,
    int maximumAuditPageSize = 200,
  }) {
    // One shared clock instance.
    this.clock = clock ?? SystemAppClock();

    // One schema registry instance.
    registry = AppEventSchemaRegistry(
      definitions: definitions,
      migrations: migrations,
    );

    // One validator instance, using the exact registry above.
    validator = AppEventSchemaValidator(
      registry: registry,
      maximumNestingDepth: maximumNestingDepth,
    );

    // One executor, sharing the same registry and validator.
    migrationExecutor = AppEventSchemaMigrationExecutor(
      registry: registry,
      validator: validator,
      pathResolver: pathResolver,
      validationCallback: validationCallback,
    );

    // One audit sink shared by the logger and read source.
    auditSink = InMemoryAppEventSchemaMigrationAuditSink(
      maximumRecords: maximumAuditRecords,
    );

    // One shared ID generator for all audit records.
    this.auditIdGenerator = auditIdGenerator ??
        SequentialAppEventSchemaMigrationAuditIdGenerator();

    auditLogger = AppEventSchemaMigrationAuditLogger(
      sink: auditSink,
      clock: this.clock,
      idGenerator: this.auditIdGenerator,
    );

    auditReadSource =
        InMemoryAppEventSchemaMigrationAuditReadSource(
      sink: auditSink,
    );

    auditReader = AppEventSchemaMigrationAuditReader(
      source: auditReadSource,
      maximumPageSize: maximumAuditPageSize,
    );

    auditRepository =
        ReaderBackedAppEventSchemaMigrationAuditRepository(
      reader: auditReader,
    );

    // The registry owns registered scope lifecycles.
    scopeRegistry =
        AppEventSchemaMigrationAuditRepositoryScopeRegistry();

    // The resolver only accesses scopes through that registry.
    scopeResolver =
        AppEventSchemaMigrationAuditRepositoryScopeResolver(
      registry: scopeRegistry,
    );
  }

  /// Shared clock used by the audit logger.
  late final AppClock clock;

  /// The single schema registry instance.
  late final AppEventSchemaRegistry registry;

  /// The single validator instance.
  ///
  /// Its registry is identical to [registry].
  late final AppEventSchemaValidator validator;

  /// The migration executor wired to [registry] and [validator].
  late final AppEventSchemaMigrationExecutor migrationExecutor;

  /// The one shared in-memory audit sink.
  ///
  /// Both [auditLogger] and [auditReadSource] use this exact instance.
  late final InMemoryAppEventSchemaMigrationAuditSink auditSink;

  /// Shared audit ID generator.
  late final AppEventSchemaMigrationAuditIdGenerator
      auditIdGenerator;

  /// Audit writer using [auditSink].
  late final AppEventSchemaMigrationAuditLogger auditLogger;

  /// Audit read source using [auditSink].
  late final InMemoryAppEventSchemaMigrationAuditReadSource
      auditReadSource;

  /// Audit reader using [auditReadSource].
  late final AppEventSchemaMigrationAuditReader auditReader;

  /// Single repository adapter using [auditReader].
  late final ReaderBackedAppEventSchemaMigrationAuditRepository
      auditRepository;

  /// Owns the lifecycle of scopes registered through this root.
  late final AppEventSchemaMigrationAuditRepositoryScopeRegistry
      scopeRegistry;

  /// Resolves registered scopes through [scopeRegistry].
  late final AppEventSchemaMigrationAuditRepositoryScopeResolver
      scopeResolver;

  bool _disposed = false;

  /// Indicates whether this composition root has been disposed.
  bool get isDisposed => _disposed;

  /// Creates and registers a repository scope.
  ///
  /// Every scope references the shared [auditRepository].
  ///
  /// The scope registry becomes responsible for disposing the scope
  /// after successful registration.
  ///
  /// If registration fails, the newly created scope is disposed before
  /// the original error is rethrown.
  AppEventSchemaMigrationAuditRepositoryScope createScope({
    required String scopeId,
  }) {
    _ensureActive();

    final scope = AppEventSchemaMigrationAuditRepositoryScope(
      scopeId: scopeId,
      repository: auditRepository,
    );

    try {
      scopeRegistry.register(scope);
      return scope;
    } catch (_) {
      scope.dispose();
      rethrow;
    }
  }

  /// Resolves a registered scope.
  ///
  /// The returned resolution does not extend the scope lifetime.
  AppEventSchemaMigrationAuditRepositoryScopeResolution resolveScope(
    String scopeId,
  ) {
    _ensureActive();
    return scopeResolver.resolve(scopeId);
  }

  /// Resolves a repository through a registered scope.
  AppEventSchemaMigrationAuditRepository resolveRepository(
    String scopeId,
  ) {
    _ensureActive();
    return scopeResolver.resolveRepository(scopeId);
  }

  /// Disposes this composition root.
  ///
  /// Disposal order:
  /// 1. Dispose all scopes owned by the scope registry.
  /// 2. Leave non-disposable components untouched.
  ///
  /// The registry itself has a dispose contract and disposes its
  /// registered scopes. Those scopes do not dispose their repositories.
  ///
  /// The remaining components expose no dispose contract in the
  /// supplied implementations, so this method does not call dispose
  /// on them.
  ///
  /// This operation is idempotent.
  void dispose() {
    if (_disposed) {
      return;
    }

    // Mark the root inactive before starting lifecycle teardown.
    _disposed = true;

    // First and only owned disposal operation.
    scopeRegistry.dispose();
  }

  void _ensureActive() {
    if (_disposed) {
      throw StateError(
        'AppEventSchemaCompositionRoot has been disposed.',
      );
    }
  }
}
