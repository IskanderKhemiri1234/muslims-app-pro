
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

/// Central composition root for the event schema subsystem.
///
/// Responsibilities:
/// - Creates and wires the schema registry and validator exactly once.
/// - Creates one migration executor using those same instances.
/// - Creates one shared audit sink for both writing and reading.
/// - Creates one audit reader and one repository adapter.
/// - Creates one legacy scope registry and one resolver.
/// - Creates one scope context registry.
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
/// - The root does not dispose the shared clock, audit sink, logger,
///   reader, repository, schema registry, validator, migration executor,
///   or observer implementations.
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
  late final InMemoryAppEventSchemaMigrationAuditReadSource
      auditReadSource;

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
  ///
  /// The root becomes inactive immediately when disposal is requested.
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
  /// The scope references the shared [auditRepository].
  ///
  /// The legacy scope registry owns the scope after successful
  /// registration. The context registry stores a provider association
  /// for the same identifier.
  ///
  /// If registration fails, the context association is removed where
  /// possible and the newly created scope is disposed.
  AppEventSchemaMigrationAuditRepositoryScope createScope({
    required String scopeId,
  }) {
    _ensureActive();

    final normalizedScopeId = scopeId.trim();

    if (normalizedScopeId.isEmpty) {
      throw const AppEventSchemaMigrationAuditRepositoryScopeContextException(
        AppEventSchemaMigrationAuditRepositoryScopeContextError.invalidScopeId,
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

    var contextRegistered = false;

    try {
      scopeContextRegistry.register(
        scopeId: normalizedScopeId,
        provider: contextProvider,
      );

      contextRegistered = true;

      scopeRegistry.register(scope);

      return scope;
    } catch (error, stackTrace) {
      if (contextRegistered) {
        try {
          scopeContextRegistry.unregister(
            scopeId: normalizedScopeId,
          );
        } catch (_) {
          // Preserve the original registration failure.
        }
      }

      try {
        scope.dispose();
      } catch (_) {
        // Preserve the original registration failure.
      }

      Error.throwWithStackTrace(error, stackTrace);
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

  /// Executes a synchronous operation through a resolved scope context.
  ///
  /// The context verifies that the underlying scope is active before
  /// exposing its repository.
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
  /// The context is validated before the callback starts.
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

    final completer = Completer<void>();

    // The root becomes inactive immediately and remains inactive
    // even if cleanup needs to be retried.
    _disposed = true;
    _disposalCompleter = completer;

    unawaited(
      _disposeOwnedResources(completer),
    );

    return completer.future;
  }

  Future<void> _disposeOwnedResources(
    Completer<void> completer,
  ) async {
    Object? firstError;
    StackTrace? firstStackTrace;

    // 1. Dispose the coordinator first.
    //
    // Coordinator disposal is retryable. If it fails, the next root
    // disposal attempt calls it again.
    try {
      await coordinator.dispose();
    } catch (error, stackTrace) {
      firstError ??= error;
      firstStackTrace ??= stackTrace;
    }

    // 2. Dispose the context registry owned by this root.
    //
    // Its disposal is independent of the registry module's provider.
    try {
      scopeContextRegistry.dispose();
    } catch (error, stackTrace) {
      firstError ??= error;
      firstStackTrace ??= stackTrace;
    }

    // 3. Dispose the legacy scope registry owned by this root.
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

    _completeDisposalAttemptSuccessfully(completer);
  }

  /// Releases a failed disposal attempt so a subsequent call to
  /// [dispose] can start a fresh cleanup attempt.
  ///
  /// The identity check prevents an older attempt from clearing
  /// a newer attempt's completer.
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

  void _ensureActive() {
    if (_disposed) {
      throw StateError(
        'AppEventSchemaCompositionRoot has been disposed.',
      );
    }
  }
}
