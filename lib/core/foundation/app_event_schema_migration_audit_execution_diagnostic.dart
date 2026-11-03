
/// Describes the diagnostic outcome of one scope-aware execution.
///
/// This model records execution metadata without owning or performing
/// the execution itself.
///
/// Architectural responsibilities:
///
/// - Identify one execution through a stable execution identifier.
/// - Associate the execution with its repository scope.
/// - Identify the executed operation.
/// - Preserve execution timing information.
/// - Represent operation outcome independently from scope validation.
/// - Optionally preserve the post-execution validation outcome.
/// - Provide a failure classification without retaining raw exceptions.
///
/// Architectural restrictions:
///
/// - Does not execute operations.
/// - Does not resolve or validate scopes.
/// - Does not access repositories or scope registries.
/// - Does not retain operation results or audit record contents.
/// - Does not capture raw exceptions or stack traces.
/// - Does not record or persist diagnostic events.
/// - Does not infer authorization.
/// - Does not claim rollback or transaction guarantees.
final class AppEventSchemaMigrationAuditExecutionDiagnostic {
  /// Creates an immutable execution diagnostic.
  ///
  /// The supplied timestamps must use UTC.
  ///
  /// A completed execution must have a completion timestamp and duration.
  /// A running execution must not have either value.
  ///
  /// Failed executions may have no post-execution validation result,
  /// because an operation that throws does not produce an execution result.
  AppEventSchemaMigrationAuditExecutionDiagnostic({
    required String executionId,
    required String scopeId,
    required AppEventSchemaMigrationAuditExecutionOperation operation,
    required DateTime startedAt,
    required AppEventSchemaMigrationAuditExecutionOutcome outcome,
    DateTime? completedAt,
    Duration? duration,
    AppEventSchemaMigrationAuditScopeExecutionValidationResult?
        validationResult,
    String? failureCode,
  })  : executionId = _validateIdentifier(
          executionId,
          'executionId',
        ),
        scopeId = _validateIdentifier(
          scopeId,
          'scopeId',
        ),
        operation = operation,
        startedAt = _validateUtcDateTime(
          startedAt,
          'startedAt',
        ),
        completedAt = _validateCompletedAt(
          startedAt: startedAt,
          completedAt: completedAt,
          outcome: outcome,
        ),
        duration = _validateDuration(
          duration: duration,
          completedAt: completedAt,
          outcome: outcome,
        ),
        outcome = outcome,
        validationResult = _validateValidationResult(
          validationResult: validationResult,
          outcome: outcome,
        ),
        failureCode = _validateFailureCode(
          failureCode: failureCode,
          outcome: outcome,
        );

  /// Unique identifier associated with this execution.
  final String executionId;

  /// Repository scope identifier associated with this execution.
  final String scopeId;

  /// Operation performed within the scope.
  final AppEventSchemaMigrationAuditExecutionOperation operation;

  /// Execution start timestamp in UTC.
  final DateTime startedAt;

  /// Execution completion timestamp in UTC, when completed.
  final DateTime? completedAt;

  /// Elapsed execution duration, when completed.
  final Duration? duration;

  /// Outcome of the operation itself.
  final AppEventSchemaMigrationAuditExecutionOutcome outcome;

  /// Post-execution scope validation result, when available.
  ///
  /// This is independent from [outcome].
  final AppEventSchemaMigrationAuditScopeExecutionValidationResult?
      validationResult;

  /// Optional stable diagnostic failure code.
  ///
  /// Raw exception messages and stack traces must not be stored here.
  final String? failureCode;

  /// Indicates whether the operation completed successfully.
  bool get isSuccessful {
    return outcome ==
        AppEventSchemaMigrationAuditExecutionOutcome.success;
  }

  /// Indicates whether post-execution scope validation succeeded.
  bool get isPostExecutionValidationSuccessful {
    return validationResult ==
        AppEventSchemaMigrationAuditScopeExecutionValidationResult.verified;
  }

  /// Indicates whether the execution has a completion timestamp.
  bool get isCompleted {
    return completedAt != null;
  }

  static String _validateIdentifier(
    String value,
    String parameterName,
  ) {
    final normalized = value.trim();

    if (normalized.isEmpty || normalized.length > 128) {
      throw ArgumentError.value(
        value,
        parameterName,
        'An identifier must contain 1 to 128 characters.',
      );
    }

    if (normalized != value) {
      throw ArgumentError.value(
        value,
        parameterName,
        'The identifier must already be normalized.',
      );
    }

    return normalized;
  }

  static DateTime _validateUtcDateTime(
    DateTime value,
    String parameterName,
  ) {
    if (!value.isUtc) {
      throw ArgumentError.value(
        value,
        parameterName,
        'The timestamp must use UTC.',
      );
    }

    return value;
  }

  static DateTime? _validateCompletedAt({
    required DateTime startedAt,
    required DateTime? completedAt,
    required AppEventSchemaMigrationAuditExecutionOutcome outcome,
  }) {
    if (outcome ==
        AppEventSchemaMigrationAuditExecutionOutcome.running) {
      if (completedAt != null) {
        throw ArgumentError.value(
          completedAt,
          'completedAt',
          'A running execution cannot have a completion timestamp.',
        );
      }

      return null;
    }

    if (completedAt == null) {
      throw ArgumentError.notNull('completedAt');
    }

    if (!completedAt.isUtc) {
      throw ArgumentError.value(
        completedAt,
        'completedAt',
        'The timestamp must use UTC.',
      );
    }

    if (completedAt.isBefore(startedAt)) {
      throw ArgumentError.value(
        completedAt,
        'completedAt',
        'Completion cannot precede execution start.',
      );
    }

    return completedAt;
  }

  static Duration? _validateDuration({
    required Duration? duration,
    required DateTime? completedAt,
    required AppEventSchemaMigrationAuditExecutionOutcome outcome,
  }) {
    if (outcome ==
        AppEventSchemaMigrationAuditExecutionOutcome.running) {
      if (duration != null) {
        throw ArgumentError.value(
          duration,
          'duration',
          'A running execution cannot have a completed duration.',
        );
      }

      return null;
    }

    if (duration == null) {
      throw ArgumentError.notNull('duration');
    }

    if (duration.isNegative) {
      throw ArgumentError.value(
        duration,
        'duration',
        'Execution duration cannot be negative.',
      );
    }

    if (completedAt == null) {
      throw ArgumentError(
        'A duration requires a completion timestamp.',
      );
    }

    return duration;
  }

  static
      AppEventSchemaMigrationAuditScopeExecutionValidationResult?
      _validateValidationResult({
    required
        AppEventSchemaMigrationAuditScopeExecutionValidationResult?
            validationResult,
    required AppEventSchemaMigrationAuditExecutionOutcome outcome,
  }) {
    if (outcome ==
            AppEventSchemaMigrationAuditExecutionOutcome.running &&
        validationResult != null) {
      throw ArgumentError.value(
        validationResult,
        'validationResult',
        'A running execution cannot have a post-execution validation result.',
      );
    }

    return validationResult;
  }

  static String? _validateFailureCode({
    required String? failureCode,
    required AppEventSchemaMigrationAuditExecutionOutcome outcome,
  }) {
    if (failureCode == null) {
      return null;
    }

    final normalized = failureCode.trim();

    if (normalized.isEmpty || normalized.length > 128) {
      throw ArgumentError.value(
        failureCode,
        'failureCode',
        'A failure code must contain 1 to 128 characters.',
      );
    }

    if (normalized != failureCode) {
      throw ArgumentError.value(
        failureCode,
        'failureCode',
        'The failure code must already be normalized.',
      );
    }

    if (outcome !=
        AppEventSchemaMigrationAuditExecutionOutcome.failure) {
      throw ArgumentError.value(
        failureCode,
        'failureCode',
        'A failure code is only valid for a failed execution.',
      );
    }

    return normalized;
  }
}

/// Identifies the operation represented by an execution diagnostic.
enum AppEventSchemaMigrationAuditExecutionOperation {
  findPage,
  count,
}

/// Describes the operation execution lifecycle outcome.
enum AppEventSchemaMigrationAuditExecutionOutcome {
  /// The execution has started but has not completed.
  running,

  /// The operation returned successfully.
  success,

  /// The operation terminated with an error.
  failure,
}
