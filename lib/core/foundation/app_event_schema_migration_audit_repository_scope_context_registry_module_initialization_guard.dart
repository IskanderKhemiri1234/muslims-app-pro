
import 'app_event_schema_migration_audit_repository_scope_context_registry_lifecycle_module_result.dart';
import 'app_event_schema_migration_audit_repository_scope_context_registry_module_initialization_policy.dart';

/// Describes the outcome of requesting an initialization permit.
enum AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardStatus {
  permitted,
  rejected,
}

/// Describes why a previously issued permit cannot be consumed.
enum AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationPermitRejection {
  none,
  permitUnavailable,
  permitAlreadyConsumed,
  preparationResultMismatch,
  observedStateChanged,
  revisionChanged,
}

/// A one-time authorization to begin initialization.
///
/// The constructor is private so callers cannot manufacture permits.
/// A permit is bound to the preparation result, observed state, and
/// lifecycle revision used when it was issued.
class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationPermit {
  final int id;

  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleObservedState
      authorizedState;

  final int authorizedRevision;

  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleResult
      _preparationResult;

  const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationPermit._({
    required this.id,
    required this.authorizedState,
    required this.authorizedRevision,
    required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleResult
        preparationResult,
  }) : _preparationResult = preparationResult;

  bool matchesPreparationResult(
    AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleResult
        preparationResult,
  ) {
    return identical(_preparationResult, preparationResult);
  }
}

/// Immutable response returned when requesting initialization authorization.
class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardResult {
  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardStatus
      status;

  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationDecision
      policyDecision;

  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationPermit?
      permit;

  const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardResult({
    required this.status,
    required this.policyDecision,
    required this.permit,
  });

  bool get isPermitted =>
      status ==
      AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardStatus
          .permitted;

  bool get isRejected => !isPermitted;
}

/// Immutable response returned when a permit is checked for consumption.
class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationPermitValidation {
  final bool isValid;

  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationPermitRejection
      rejection;

  final String description;

  const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationPermitValidation({
    required this.isValid,
    required this.rejection,
    required this.description,
  });
}

/// Guards initialization authorization against stale or reused decisions.
///
/// This class does not initialize, own, or dispose the registry module.
/// The composition root remains responsible for executing initialization
/// immediately after a permit has been successfully consumed.
class AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuard {
  final AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationPolicy
      _policy;

  final Map<int,
          AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationPermit>
      _activePermits = {};

  int _nextPermitId = 0;

  bool _isDisposed = false;

  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuard({
    required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationPolicy
        policy,
  }) : _policy = policy;

  bool get isDisposed => _isDisposed;

  int get activePermitCount => _activePermits.length;

  /// Issues a one-time permit if the initialization policy allows it.
  ///
  /// [lifecycleRevision] must be a monotonically increasing revision supplied
  /// by the lifecycle controller or composition root. It must change whenever
  /// the observed lifecycle state changes.
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardResult
      requestPermit({
    required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleResult
        preparationResult,
    required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleObservedState
        observedState,
    required int lifecycleRevision,
    bool previousFailureResolved = false,
  }) {
    _ensureNotDisposed();

    if (lifecycleRevision < 0) {
      throw ArgumentError.value(
        lifecycleRevision,
        'lifecycleRevision',
        'Lifecycle revision cannot be negative.',
      );
    }

    final decision = _policy.evaluate(
      preparationResult: preparationResult,
      observedState: observedState,
      previousFailureResolved: previousFailureResolved,
    );

    if (!decision.isAllowed) {
      return AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardResult(
        status:
            AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardStatus
                .rejected,
        policyDecision: decision,
        permit: null,
      );
    }

    if (_nextPermitId == 0x7FFFFFFFFFFFFFFF) {
      throw StateError('Initialization permit identifier space exhausted.');
    }

    final permitId = ++_nextPermitId;

    final permit =
        AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationPermit._(
      id: permitId,
      authorizedState: observedState,
      authorizedRevision: lifecycleRevision,
      preparationResult: preparationResult,
    );

    _activePermits[permitId] = permit;

    return AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardResult(
      status:
          AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardStatus
              .permitted,
      policyDecision: decision,
      permit: permit,
    );
  }

  /// Validates and consumes a previously issued permit.
  ///
  /// A permit is removed from the active set on its first validation attempt.
  /// Therefore, it cannot be replayed, including after a failed validation.
  ///
  /// The composition root must call this immediately before starting the
  /// actual initialization operation.
  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationPermitValidation
      consumePermit({
    required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationPermit
        permit,
    required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryLifecycleModuleResult
        preparationResult,
    required AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleObservedState
        currentObservedState,
    required int currentLifecycleRevision,
  }) {
    _ensureNotDisposed();

    if (currentLifecycleRevision < 0) {
      throw ArgumentError.value(
        currentLifecycleRevision,
        'currentLifecycleRevision',
        'Lifecycle revision cannot be negative.',
      );
    }

    final registeredPermit = _activePermits.remove(permit.id);

    if (registeredPermit == null ||
        !identical(registeredPermit, permit)) {
      return _rejectPermit(
        AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationPermitRejection
            .permitUnavailable,
        'The permit is unknown, expired, or has already been consumed.',
      );
    }

    if (!permit.matchesPreparationResult(preparationResult)) {
      return _rejectPermit(
        AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationPermitRejection
            .preparationResultMismatch,
        'The preparation result differs from the result used to issue this permit.',
      );
    }

    if (currentObservedState != permit.authorizedState) {
      return _rejectPermit(
        AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationPermitRejection
            .observedStateChanged,
        'The lifecycle state changed after the permit was issued.',
      );
    }

    if (currentLifecycleRevision != permit.authorizedRevision) {
      return _rejectPermit(
        AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationPermitRejection
            .revisionChanged,
        'The lifecycle revision changed after the permit was issued.',
      );
    }

    return const AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationPermitValidation(
      isValid: true,
      rejection:
          AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationPermitRejection
              .none,
      description: 'The initialization permit was validated and consumed.',
    );
  }

  /// Invalidates all outstanding permits.
  ///
  /// This only clears authorization records. It does not dispose or mutate
  /// any external lifecycle resource.
  void invalidateAllPermits() {
    _ensureNotDisposed();
    _activePermits.clear();
  }

  /// Disables this guard and invalidates its outstanding permits.
  ///
  /// This is local authorization-state cleanup only. It does not dispose
  /// the registry module, lifecycle controller, or observer dispatcher.
  void disable() {
    if (_isDisposed) {
      return;
    }

    _activePermits.clear();
    _isDisposed = true;
  }

  AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationPermitValidation
      _rejectPermit(
    AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationPermitRejection
        rejection,
    String description,
  ) {
    return AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationPermitValidation(
      isValid: false,
      rejection: rejection,
      description: description,
    );
  }

  void _ensureNotDisposed() {
    if (_isDisposed) {
      throw StateError(
        'The initialization guard has been disabled.',
      );
    }
  }
}
