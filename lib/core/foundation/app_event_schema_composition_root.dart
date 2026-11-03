
import 'dart:async';

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
/// - Provides idempotent synchronous and asynchronous disposal entry points.
///
/// Ownership contract:
/// - This root owns the scope registry.
/// - The scope registry owns successfully registered scopes.
/// - Every registered scope references the shared audit repository.
/// - Scopes do not own or dispose the shared audit repository.
/// - The root does not dispose the shared clock, audit sink, logger,
///   reader, repository, schema registry, validator, or migration executor.
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
    this.clock = clock ?? SystemAppClock();

    registry = AppEventSchemaRegistry(
      definitions: definitions,
      migrations: migrations,
    );

    validator = AppEventSchemaValidator(
      registry: registry,
      maximumNestingDepth: maximumNestingDepth,
    );

    migrationExecutor = AppEventSchemaMigrationExecutor(
      registry: registry,
      validator: validator,
      pathResolver: pathResolver,
      validationCallback: validationCallback,
    );

    auditSink = InMemoryAppEventSchemaMigrationAuditSink(
      maximumRecords: maximumAuditRecords,
    );

    this.auditIdGenerator = auditIdGenerator ??
        SequentialAppEventSchemaMigrationAuditIdGenerator();

    auditLogger = AppEventSchemaMigrationAuditLogger(
      sink: auditSink,
      clock: this.clock,
      idGenerator: this.auditIdGenerator,
    );

    auditReadSource = InMemoryAppEventSchemaMigrationAuditReadSource(
      sink: auditSink,
    );

    auditReader = AppEventSchemaMigrationAuditReader(
      source: auditReadSource,
      maximumPageSize: maximumAuditPageSize,
    );

    auditRepository = ReaderBackedAppEventSchemaMigrationAuditRepository(
      reader: auditReader,
    );

    scopeRegistry =
        AppEventSchemaMigrationAuditRepositoryScopeRegistry();

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
  late final AppEventSchemaMigrationAuditIdGenerator auditIdGenerator;

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

  Completer<void>? _disposalCompleter;

  /// Indicates whether this composition root has been disposed.
  ///
  /// The root becomes inactive as soon as disposal is requested.
  bool get isDisposed => _disposed;

  /// Indicates whether asynchronous disposal has been requested.
  bool get isDisposalRequested => _disposalCompleter != null;

  /// Indicates whether asynchronous disposal has completed.
  bool get isDisposalCompleted =>
      _disposalCompleter?.isCompleted ?? false;

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

  /// Synchronously disposes the resources owned by this root.
  ///
  /// This preserves the original synchronous API.
  ///
  /// It is idempotent. Calling it after [disposeAsync] has been requested
  /// does not repeat scope registry disposal.
  ///
  /// This method does not wait for asynchronous lifecycle components.
  /// Use [disposeAsync] when asynchronous teardown must be awaited.
  void dispose() {
    if (_disposed) {
      return;
    }

    _disposed = true;

    scopeRegistry.dispose();
  }

  /// Asynchronously disposes this composition root.
  ///
  /// Concurrent calls share the same Future.
  ///
  /// The root becomes inactive synchronously when this method is called.
  /// The owned scope registry is disposed exactly once.
  ///
  /// This method currently has no asynchronous child resource to await.
  /// It provides an awaitable disposal contract for future lifecycle
  /// integration without inventing ownership of external components.
  ///
  /// The external clock, schema registry, validator, migration executor,
  /// audit sink, logger, reader, and repository are not disposed.
  Future<void> disposeAsync() {
    final existingCompleter = _disposalCompleter;

    if (existingCompleter != null) {
      return existingCompleter.future;
    }

    final completer = Completer<void>();

    // Record the disposal request before executing cleanup.
    _disposalCompleter = completer;
    _disposed = true;

    try {
      scopeRegistry.dispose();
      completer.complete();
    } catch (error, stackTrace) {
      completer.completeError(error, stackTrace);
    }

    return completer.future;
  }

  void _ensureActive() {
    if (_disposed) {
      throw StateError(
        'AppEventSchemaCompositionRoot has been disposed.',
      );
    }
  }
}
