
import 'dart:async';

import 'app_clock.dart';
import 'app_event_schema_registry.dart';
import 'app_event_schema_validator.dart';
import 'app_event_schema_migration.dart';
import 'app_event_schema_migration_audit.dart';
import 'app_event_schema_migration_audit_query.dart';
import 'app_event_schema_migration_audit_reader.dart';
import 'app_event_schema_migration_audit_repository.dart';
import 'app_event_schema_migration_audit_repository_scope.dart';
import 'app_event_schema_migration_audit_repository_scope_registry.dart';
import 'app_event_schema_migration_audit_repository_scope_resolver.dart';

import 'app_event_schema_migration_audit_repository_scope_context.dart';
import 'app_event_schema_migration_audit_repository_scope_context_provider.dart';
import 'app_event_schema_migration_audit_repository_scope_context_registry.dart';
import 'app_event_schema_migration_audit_repository_scope_context_registry_configuration.dart';
import 'app_event_schema_migration_audit_repository_scope_context_registry_module.dart';

import 'app_event_schema_migration_audit_repository_scope_context_registry_lifecycle_configuration.dart';
import 'app_event_schema_migration_audit_repository_scope_context_registry_lifecycle_observer.dart';
import 'app_event_schema_migration_audit_repository_scope_context_registry_lifecycle_controller.dart';
import 'app_event_schema_migration_audit_repository_scope_context_registry_lifecycle_assembly.dart';
import 'app_event_schema_migration_audit_repository_scope_context_registry_coordinator.dart';

import 'app_event_schema_migration_audit_scope_execution_result.dart';
import 'app_event_schema_migration_audit_repository_scope_executor.dart';
import 'app_event_schema_migration_audit_scope_aware_execution_service.dart';
import 'app_event_schema_migration_audit_scope_operations.dart';

import 'app_event_schema_migration_audit_execution_diagnostic.dart';
import 'app_event_schema_migration_audit_execution_diagnostics_recorder.dart';
import 'app_event_schema_migration_audit_execution_id_generator.dart';
import 'app_event_schema_migration_audit_execution_clock.dart';

import 'app_event_schema_migration_audit_in_memory_diagnostics_recorder.dart';
import 'app_event_schema_migration_audit_uuid_execution_id_generator.dart';
import 'app_event_schema_migration_audit_execution_clock_impl.dart';

/// Central composition root for the event schema subsystem.
///
/// Responsibilities:
/// - Creates and wires the schema registry and validator exactly once.
/// - Creates one migration executor using those same instances.
/// - Creates one shared audit sink for both writing and reading.
/// - Creates one audit reader and one repository adapter.
/// - Creates one legacy scope registry and one resolver.
/// - Creates one scope context registry.
/// - Creates independent FindPage and Count scope operations.
/// - Creates an independent repository scope executor for each operation.
/// - Creates an independent scope-aware execution service for each executor.
/// - Shares one diagnostics recorder across both execution services.
/// - Shares one execution ID generator across both execution services.
/// - Shares one execution clock across both execution services.
/// - Creates and owns the registry lifecycle coordinator.
/// - Owns the lifecycle of scopes registered through this root.
/// - Provides serialized, retryable asynchronous disposal.
///
/// Ownership contract:
/// - This root owns the legacy scope registry.
/// - This root owns the scope context registry.
/// - The legacy scope registry owns successfully registered scopes.
/// - Every registered scope references the shared audit repository.
/// - The scope context registry owns provider-to-identifier associations,
///   not the providers themselves.
/// - The registry module owns its access provider.
/// - The registry module does not own the scope context registry.
/// - The coordinator owns the lifecycle of the registry module
///   and the observer dispatcher.
/// - This root owns the coordinator.
/// - The scope operations, executors, and execution services are
///   composition objects and do not own the repository or scopes.
/// - The diagnostic recorder, ID generator, and execution clock are
///   shared dependencies and are not disposed by this root.
/// - This root does not dispose the shared clock, audit sink, logger,
///   reader, repository, schema registry, validator, migration executor,
///   scope operations, executors, execution services, or observer
///   implementations.
///
/// Disposal order:
/// 1. Coordinator.
/// 2. Scope context registry.
/// 3. Legacy scope registry.
///
/// No global state, service locator, or implicit initialization is used.
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
    AppEventSchemaMigrationAuditExecutionDiagnosticsRecorder?
        diagnosticsRecorder,
    AppEventSchemaMigrationAuditExecutionIdGenerator?
        executionIdGenerator,
    AppEventSchemaMigrationAuditExecutionClock? executionClock,
    int maximumNestingDepth = 32,
    int maximumAuditRecords = 1000,
    int maximumAuditPageSize = 200,
    AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleObserverErrorHandler
        observerErrorHandler =
        const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleSilentErrorHandler(),
    AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleNotificationPolicy
        notificationPolicy =
        AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleNotificationPolicy
            .all,
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

    // Shared execution diagnostics infrastructure.
    this.diagnosticsRecorder = diagnosticsRecorder ??
        AppEventSchemaMigrationAuditInMemoryDiagnosticsRecorder();

    this.executionIdGenerator = executionIdGenerator ??
        AppEventSchemaMigrationAuditUuidExecutionIdGenerator();

    this.executionClock = executionClock ??
        AppEventSchemaMigrationAuditSystemExecutionClock();

    // FindPage operation pipeline.
    findPageScopeOperation =
        const AppEventSchemaMigrationAuditFindPageScopeOperation();

    findPageScopeExecutor =
        AppEventSchemaMigrationAuditRepositoryScopeExecutor<
            AppEventSchemaMigrationAuditQuery,
            AppEventSchemaMigrationAuditPage>(
      operation: findPageScopeOperation,
    );

    findPageExecutionService =
        AppEventSchemaMigrationAuditScopeAwareExecutionService<
            AppEventSchemaMigrationAuditQuery,
            AppEventSchemaMigrationAuditPage>(
      scopeRegistry: scopeRegistry,
      scopeExecutor: findPageScopeExecutor,
      operation:
          AppEventSchemaMigrationAuditExecutionOperation.findPage,
      diagnosticsRecorder: this.diagnosticsRecorder,
      executionIdGenerator: this.executionIdGenerator,
      executionClock: this.executionClock,
    );

    // Count operation pipeline.
    countScopeOperation =
        const AppEventSchemaMigrationAuditCountScopeOperation();

    countScopeExecutor =
        AppEventSchemaMigrationAuditRepositoryScopeExecutor<
            AppEventSchemaMigrationAuditFilter,
            int>(
      operation: countScopeOperation,
    );

    countExecutionService =
        AppEventSchemaMigrationAuditScopeAwareExecutionService<
            AppEventSchemaMigrationAuditFilter,
            int>(
      scopeRegistry: scopeRegistry,
      scopeExecutor: countScopeExecutor,
      operation:
          AppEventSchemaMigrationAuditExecutionOperation.count,
      diagnosticsRecorder: this.diagnosticsRecorder,
      executionIdGenerator: this.executionIdGenerator,
      executionClock: this.executionClock,
    );

    scopeContextRegistry =
        AppEventSchemaMigrationAuditRepositoryScopeContextRegistry();

    this.observerErrorHandler = observerErrorHandler;

    scopeContextRegistryConfiguration =
        AppEventSchemaMigrationAuditRepositoryScopeContextRegistryConfiguration(
      registry: scopeContextRegistry,
    );

    lifecycleConfiguration =
        AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleConfiguration(
      clock: this.clock,
      observerErrorHandler: this.observerErrorHandler,
      notificationPolicy: notificationPolicy,
    );

    registryModule =
        AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModule(
      configuration: scopeContextRegistryConfiguration,
    );

    observerDispatcher =
        AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleObserverDispatcher(
      errorHandler: this.observerErrorHandler,
    );

    lifecycleController =
        AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleController();

    lifecycleAssembly =
        AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleAssembly(
      controller: lifecycleController,
      configuration: lifecycleConfiguration,
    );

    coordinator =
        AppEventSchemaMigrationAuditRepositoryScopeContextRegistryCoordinator(
      registryModule: registryModule,
      lifecycleAssembly: lifecycleAssembly,
      observerDispatcher: observerDispatcher,
    );
  }

  /// Shared clock used by audit logging and lifecycle notifications.
  late final AppClock clock;

  /// The single schema registry instance.
  late final AppEventSchemaRegistry registry;

  /// The single validator instance.
  ///
  /// Its registry is identical to [registry].
  late final AppEventSchemaValidator validator;

  /// Migration executor wired to [registry] and [validator].
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
  late final InMemoryAppEventSchemaMigrationAuditReadSource auditReadSource;

  /// Audit reader using [auditReadSource].
  late final AppEventSchemaMigrationAuditReader auditReader;

  /// Single repository adapter using [auditReader].
  late final ReaderBackedAppEventSchemaMigrationAuditRepository
      auditRepository;

  /// Owns the lifecycle of legacy repository scopes.
  late final AppEventSchemaMigrationAuditRepositoryScopeRegistry
      scopeRegistry;

  /// Resolves registered legacy repository scopes.
  late final AppEventSchemaMigrationAuditRepositoryScopeResolver
      scopeResolver;

  /// Shared execution diagnostics recorder.
  late final AppEventSchemaMigrationAuditExecutionDiagnosticsRecorder
      diagnosticsRecorder;

  /// Shared execution identifier generator.
  late final AppEventSchemaMigrationAuditExecutionIdGenerator
      executionIdGenerator;

  /// Shared monotonic execution clock.
  late final AppEventSchemaMigrationAuditExecutionClock executionClock;

  /// Dedicated operation for reading an audit page.
  late final AppEventSchemaMigrationAuditFindPageScopeOperation
      findPageScopeOperation;

  /// Dedicated repository scope executor for FindPage.
  late final AppEventSchemaMigrationAuditRepositoryScopeExecutor<
      AppEventSchemaMigrationAuditQuery,
      AppEventSchemaMigrationAuditPage> findPageScopeExecutor;

  /// Dedicated scope-aware execution service for FindPage.
  late final AppEventSchemaMigrationAuditScopeAwareExecutionService<
      AppEventSchemaMigrationAuditQuery,
      AppEventSchemaMigrationAuditPage> findPageExecutionService;

  /// Dedicated operation for counting audit records.
  late final AppEventSchemaMigrationAuditCountScopeOperation
      countScopeOperation;

  /// Dedicated repository scope executor for Count.
  late final AppEventSchemaMigrationAuditRepositoryScopeExecutor<
      AppEventSchemaMigrationAuditFilter,
      int> countScopeExecutor;

  /// Dedicated scope-aware execution service for Count.
  late final AppEventSchemaMigrationAuditScopeAwareExecutionService<
      AppEventSchemaMigrationAuditFilter,
      int> countExecutionService;

  /// Registry associating scope identifiers with context providers.
  ///
  /// This root owns and disposes this registry.
  late final AppEventSchemaMigrationAuditRepositoryScopeContextRegistry
      scopeContextRegistry;

  /// Configuration for the externally managed context registry.
  ///
  /// The configuration does not own the registry.
  late final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryConfiguration
      scopeContextRegistryConfiguration;

  /// Error handler injected into the lifecycle configuration
  /// and observer dispatcher.
  ///
  /// The root retains the reference but does not dispose the handler.
  late final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleObserverErrorHandler
      observerErrorHandler;

  /// Lifecycle notification configuration.
  late final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleConfiguration
      lifecycleConfiguration;

  /// Registry module managed by [coordinator].
  ///
  /// The module owns its access provider, not [scopeContextRegistry].
  late final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModule
      registryModule;

  /// Observer dispatcher managed by [coordinator].
  late final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleObserverDispatcher
      observerDispatcher;

  /// Lifecycle controller used by [lifecycleAssembly].
  late final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleController
      lifecycleController;

  /// Lifecycle assembly used by [coordinator].
  late final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleAssembly
      lifecycleAssembly;

  /// Sole lifecycle coordinator owned by this composition root.
  late final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryCoordinator
      coordinator;

  bool _disposed = false;

  /// The completer for the currently active disposal attempt.
  ///
  /// A failed attempt releases this reference so a later call can retry.
  Completer<void>? _disposalCompleter;

  /// Indicates whether this composition root is still active.
  bool get isDisposed => _disposed;

  /// Indicates whether asynchronous disposal has been requested.
  bool get isDisposalRequested => _disposed;

  /// Indicates whether the current disposal attempt has completed.
  ///
  /// After a failed attempt, the attempt reference is cleared to allow
  /// another call to [dispose].
  bool get isDisposalCompleted =>
      _disposalCompleter?.isCompleted ?? false;

  /// Initializes the lifecycle coordinator and its registry module.
  ///
  /// Concurrent calls are coalesced by the coordinator.
  ///
  /// The context registry itself is created by the composition root
  /// during construction and is not recreated during initialization.
  Future<void> initialize() {
    _ensureActive();
    return coordinator.initialize();
  }

  /// Subscribes an observer to lifecycle notifications.
  ///
  /// Observers are externally owned and are never disposed by this root.
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleObserverSubscriptionResult
      subscribeLifecycleObserver(
    AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleObserver
        observer,
  ) {
    _ensureActive();
    return observerDispatcher.subscribe(observer);
  }

  /// Creates and registers a repository scope and its context provider.
  ///
  /// Registration order:
  /// 1. Register the scope in the legacy scope registry.
  /// 2. Register its context provider in the context registry.
  ///
  /// If context registration fails, the first registration is rolled back
  /// using disposeAndUnregister.
  AppEventSchemaMigrationAuditRepositoryScope createScope({
    required String scopeId,
  }) {
    _ensureActive();

    final normalizedScopeId = _normalizeScopeId(scopeId);

    // Preflight both registries before creating or registering resources.
    if (scopeRegistry.isReserved(normalizedScopeId)) {
      throw AppEventSchemaMigrationAuditRepositoryScopeRegistryException(
        code:
            AppEventSchemaMigrationAuditRepositoryScopeRegistryErrorCode
                .duplicateScopeId,
        message:
            'The scope identifier "$normalizedScopeId" is already reserved.',
      );
    }

    if (scopeContextRegistry.isReserved(
      scopeId: normalizedScopeId,
    )) {
      throw AppEventSchemaMigrationAuditRepositoryScopeContextRegistryException(
        code:
            AppEventSchemaMigrationAuditRepositoryScopeContextRegistryError
                .duplicateScopeId,
        scopeId: normalizedScopeId,
      );
    }

    final scope = AppEventSchemaMigrationAuditRepositoryScope(
      scopeId: normalizedScopeId,
      repository: auditRepository,
    );

    final contextProvider =
        AppEventSchemaMigrationAuditRepositoryScopeContextProvider(
      resolver: scopeResolver,
    );

    var scopeRegistered = false;

    try {
      // The scope registry becomes the lifecycle owner first.
      scopeRegistry.register(scope);
      scopeRegistered = true;

      // Provider registration is performed only after scope ownership
      // has been established successfully.
      scopeContextRegistry.register(
        scopeId: normalizedScopeId,
        provider: contextProvider,
      );

      return scope;
    } catch (error, stackTrace) {
      if (scopeRegistered) {
        // Roll back through the owning registry. Do not unregister first:
        // an active unregistered scope intentionally keeps its ID reserved.
        //
        // If disposal fails, ScopeRegistry retains ownership and reservation
        // so the root's disposal sequence can retry it later.
        try {
          scopeRegistry.disposeAndUnregister(
            normalizedScopeId,
          );
        } catch (_) {
          // Preserve the original registration error and stack trace.
        }
      } else {
        // The scope was never accepted by ScopeRegistry, so the root
        // still has responsibility for cleaning up this unregistered object.
        try {
          if (!scope.isDisposed) {
            scope.dispose();
          }
        } catch (_) {
          // Preserve the original registration error and stack trace.
        }
      }

      Error.throwWithStackTrace(
        error,
        stackTrace,
      );
    }
  }

  /// Resolves a registered legacy scope.
  ///
  /// The returned resolution does not extend the scope lifetime.
  AppEventSchemaMigrationAuditRepositoryScopeResolution resolveScope(
    String scopeId,
  ) {
    _ensureActive();
    return scopeResolver.resolve(scopeId);
  }

  /// Resolves a repository through a registered legacy scope.
  AppEventSchemaMigrationAuditRepository resolveRepository(
    String scopeId,
  ) {
    _ensureActive();
    return scopeResolver.resolveRepository(scopeId);
  }

  /// Resolves an execution context through the context registry.
  ///
  /// The registry delegates to the registered provider, which uses
  /// the injected legacy scope resolver.
  AppEventSchemaMigrationAuditRepositoryScopeContext resolveScopeContext({
    required String scopeId,
  }) {
    _ensureActive();

    return scopeContextRegistry.provideContext(
      scopeId: scopeId,
    );
  }

  /// Executes the FindPage operation through its dedicated
  /// scope-aware execution service.
  Future<
      AppEventSchemaMigrationAuditScopeExecutionResult<
          AppEventSchemaMigrationAuditPage>> executeFindPage({
    required String scopeId,
    required AppEventSchemaMigrationAuditQuery request,
  }) {
    _ensureActive();

    final context = resolveScopeContext(
      scopeId: scopeId,
    );

    return findPageExecutionService.execute(
      scopeId: scopeId,
      context: context,
      request: request,
    );
  }

  /// Executes the Count operation through its dedicated
  /// scope-aware execution service.
  Future<
      AppEventSchemaMigrationAuditScopeExecutionResult<int>> executeCount({
    required String scopeId,
    required AppEventSchemaMigrationAuditFilter request,
  }) {
    _ensureActive();

    final context = resolveScopeContext(
      scopeId: scopeId,
    );

    return countExecutionService.execute(
      scopeId: scopeId,
      context: context,
      request: request,
    );
  }

  /// Executes a synchronous operation through a resolved scope context.
  T executeWithScopeContext<T>({
    required String scopeId,
    required T Function(
      AppEventSchemaMigrationAuditRepositoryScopeContext context,
    ) operation,
  }) {
    _ensureActive();

    final context = resolveScopeContext(
      scopeId: scopeId,
    );

    context.verifyActive();

    return operation(context);
  }

  /// Executes an asynchronous operation through a resolved scope context.
  ///
  /// This method does not lock the scope or prevent its disposal while
  /// the asynchronous operation is pending.
  Future<T> executeWithScopeContextAsync<T>({
    required String scopeId,
    required Future<T> Function(
      AppEventSchemaMigrationAuditRepositoryScopeContext context,
    ) operation,
  }) {
    _ensureActive();

    final context = resolveScopeContext(
      scopeId: scopeId,
    );

    context.verifyActive();

    return operation(context);
  }

  /// Disposes all resources owned by this composition root.
  ///
  /// Concurrent calls during the same attempt share one Future.
  ///
  /// The root becomes inactive synchronously when this method is called.
  ///
  /// If an attempt fails, a later call can start a new attempt.
  ///
  /// Cleanup is serialized:
  /// 1. Await coordinator disposal.
  /// 2. Dispose the owned context registry.
  /// 3. Dispose the owned legacy scope registry.
  ///
  /// Later cleanup operations are attempted even if an earlier operation
  /// fails. The first cleanup error is rethrown after all cleanup attempts.
  Future<void> dispose() {
    final existingCompleter = _disposalCompleter;

    if (existingCompleter != null) {
      return existingCompleter.future;
    }

    if (_disposalCompletedSuccessfully) {
      return Future<void>.value();
    }

    final completer = Completer<void>();

    // Stop accepting new work before starting asynchronous cleanup.
    _disposed = true;
    _disposalCompleter = completer;

    unawaited(
      _disposeOwnedResources(completer),
    );

    return completer.future;
  }

  bool get _disposalCompletedSuccessfully =>
      _coordinatorDisposalSucceeded &&
      scopeContextRegistry.isDisposed &&
      scopeRegistry.isDisposed;

  bool _coordinatorDisposalSucceeded = false;

  Future<void> _disposeOwnedResources(
    Completer<void> completer,
  ) async {
    Object? firstError;
    StackTrace? firstStackTrace;

    // 1. Coordinator.
    try {
      await coordinator.dispose();
      _coordinatorDisposalSucceeded = coordinator.isDisposed;

      if (!_coordinatorDisposalSucceeded) {
        throw StateError(
          'Coordinator disposal completed without reaching its disposed state.',
        );
      }
    } catch (error, stackTrace) {
      firstError ??= error;
      firstStackTrace ??= stackTrace;
    }

    // 2. ScopeContextRegistry.
    try {
      scopeContextRegistry.dispose();
    } catch (error, stackTrace) {
      firstError ??= error;
      firstStackTrace ??= stackTrace;
    }

    // 3. ScopeRegistry.
    try {
      scopeRegistry.dispose();
    } catch (error, stackTrace) {
      firstError ??= error;
      firstStackTrace ??= stackTrace;
    }

    if (firstError != null) {
      _completeDisposalAttemptWithError(
        completer,
        firstError,
        firstStackTrace ?? StackTrace.current,
      );
      return;
    }

    if (!_disposalCompletedSuccessfully) {
      _completeDisposalAttemptWithError(
        completer,
        StateError(
          'Composition root cleanup did not reach its completed state.',
        ),
        StackTrace.current,
      );
      return;
    }

    _completeDisposalAttemptSuccessfully(completer);
  }

  /// Releases a failed disposal attempt so a subsequent call to
  /// [dispose] can start a fresh cleanup attempt.
  void _completeDisposalAttemptWithError(
    Completer<void> completer,
    Object error,
    StackTrace stackTrace,
  ) {
    if (identical(_disposalCompleter, completer)) {
      _disposalCompleter = null;
    }

    if (!completer.isCompleted) {
      completer.completeError(
        error,
        stackTrace,
      );
    }
  }

  /// Completes the current disposal attempt successfully.
  void _completeDisposalAttemptSuccessfully(
    Completer<void> completer,
  ) {
    if (!completer.isCompleted) {
      completer.complete();
    }
  }

  String _normalizeScopeId(String value) {
    final normalized = value.trim();

    if (normalized.isEmpty || normalized.length > 128) {
      throw const AppEventSchemaMigrationAuditRepositoryScopeContextException(
        AppEventSchemaMigrationAuditRepositoryScopeContextError
            .invalidScopeId,
      );
    }

    return normalized;
  }

  void _ensureActive() {
    if (_disposed) {
      throw StateError(
        'AppEventSchemaCompositionRoot has been disposed.',
      );
    }
  }
}
