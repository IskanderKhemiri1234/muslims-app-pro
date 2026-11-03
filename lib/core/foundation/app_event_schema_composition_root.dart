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
import 'app_event_schema_migration_audit_repository_scope_context.dart';
import 'app_event_schema_migration_audit_repository_scope_context_registry.dart';
import 'app_event_schema_migration_audit_repository_scope_context_registry_lifecycle_configuration.dart';
import 'app_event_schema_migration_audit_repository_scope_context_registry_lifecycle_controller.dart';
import 'app_event_schema_migration_audit_repository_scope_context_registry_lifecycle_factory.dart';
import 'app_event_schema_migration_audit_repository_scope_context_registry_lifecycle_observer.dart';
import 'app_event_schema_migration_audit_repository_scope_context_registry_coordinator.dart';

/// Central composition root for the event schema subsystem.
///
/// Responsibilities:
/// - Creates and wires the schema registry and validator exactly once.
/// - Creates one migration executor using those same instances.
/// - Creates one shared audit sink for both writing and reading.
/// - Creates one audit reader and one repository adapter.
/// - Creates one scope registry and one resolver.
/// - Manages Coordinator lifecycles per scope context.
/// - Owns the lifecycle of scopes and coordinators registered through this root.
///
/// This class does not use global state, service locators, or implicit
/// initialization.
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

  /// Shared clock used across subsystem.
  late final AppClock clock;

  /// The single schema registry instance.
  late final AppEventSchemaRegistry registry;

  /// The single validator instance.
  late final AppEventSchemaValidator validator;

  /// The migration executor wired to [registry] and [validator].
  late final AppEventSchemaMigrationExecutor migrationExecutor;

  /// The one shared in-memory audit sink.
  late final InMemoryAppEventSchemaMigrationAuditSink auditSink;

  /// Shared audit ID generator.
  late final AppEventSchemaMigrationAuditIdGenerator auditIdGenerator;

  /// Audit writer using [auditSink].
  late final AppEventSchemaMigrationAuditLogger auditLogger;

  /// Audit read source using [auditSink].
  late final InMemoryAppEventSchemaMigrationAuditReadSource auditReadSource;

  /// Audit reader using [auditReadSource].
  late final AppEventSchemaMigrationAuditReader auditReader;

  /// Single repository adapter using [auditReader].
  late final ReaderBackedAppEventSchemaMigrationAuditRepository auditRepository;

  /// Owns the lifecycle of scopes registered through this root.
  late final AppEventSchemaMigrationAuditRepositoryScopeRegistry scopeRegistry;

  /// Resolves registered scopes through [scopeRegistry].
  late final AppEventSchemaMigrationAuditRepositoryScopeResolver scopeResolver;

  /// Active scope context coordinators managed by this root.
  final List<AppEventSchemaMigrationAuditRepositoryScopeContextRegistryCoordinator>
      _activeCoordinators = [];

  bool _disposed = false;

  /// Indicates whether this composition root has been disposed.
  bool get isDisposed => _disposed;

  /// Creates and registers a repository scope.
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

  /// Creates, wires, and manages a fully bound scope context coordinator.
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryCoordinator createScopeCoordinator({
    required String scopeId,
  }) {
    _ensureActive();

    final scopeContext = AppEventSchemaMigrationAuditRepositoryScopeContext(
      scopeId: scopeId,
      repository: auditRepository,
    );

    final contextRegistry = AppEventSchemaMigrationAuditRepositoryScopeContextRegistry(
      scopeContext: scopeContext,
    );

    final configuration = AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleConfiguration(
      clock: clock,
    );

    final factory = AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleFactory(
      configuration: configuration,
    );

    final controller = AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleController(
      factory: factory,
    );

    final coordinator = AppEventSchemaMigrationAuditRepositoryScopeContextRegistryCoordinator(
      registry: contextRegistry,
      controller: controller,
      clock: clock,
    );

    _activeCoordinators.add(coordinator);
    return coordinator;
  }

  /// Resolves a registered scope.
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

  /// Disposes this composition root and all managed coordinators and scopes.
  ///
  /// Disposal order:
  /// 1. Mark root inactive.
  /// 2. Asynchronously/Synchronously dispose all active scope coordinators.
  /// 3. Dispose the scope registry.
  ///
  /// This operation is idempotent.
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }

    // Mark the root inactive before starting lifecycle teardown.
    _disposed = true;

    // Dispose all active scope coordinators first.
    for (final coordinator in List.of(_activeCoordinators)) {
      if (!coordinator.isDisposed) {
        await coordinator.dispose();
      }
    }
    _activeCoordinators.clear();

    // Dispose scope registry.
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
