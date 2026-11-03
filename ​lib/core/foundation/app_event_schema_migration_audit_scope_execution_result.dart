/// Represents the outcome of one operation executed within an explicitly
/// identified application event schema migration audit repository scope.
///
/// The result preserves two independent aspects of execution:
///
/// - The original result returned by the operation.
/// - The outcome of the post-execution scope validation.
///
/// Architectural responsibilities:
///
/// - Preserve the original operation result without transforming it.
/// - Preserve the normalized scope identifier associated with execution.
/// - Represent post-execution validation independently from operation result.
/// - Preserve a successful operation result even when post-execution
///   scope validation does not succeed.
/// - Provide an immutable representation of the completed execution.
///
/// Architectural restrictions:
///
/// - Does not execute operations.
/// - Does not resolve or validate scopes.
/// - Does not access a scope registry.
/// - Does not access a scope context.
/// - Does not create or access repositories.
/// - Does not record audit events.
/// - Does not infer authorization.
/// - Does not classify arbitrary operation results as successful or failed.
/// - Does not claim rollback, atomicity, or transaction guarantees.
///
/// An instance represents an operation that returned a result.
/// An operation that throws before returning a result does not produce
/// an instance through this contract.
final class AppEventSchemaMigrationAuditScopeExecutionResult<TResult> {
  /// Creates an immutable execution result.
  ///
  /// The caller must supply the normalized scope identifier associated
  /// with the operation, the original operation result, and the outcome
  /// of the post-execution scope validation.
  ///
  /// This constructor does not independently verify that the scope exists
  /// or remains active.
  AppEventSchemaMigrationAuditScopeExecutionResult({
    required String scopeId,
    required TResult result,
    required AppEventSchemaMigrationAuditScopeExecutionValidationResult
        validationResult,
  })  : scopeId = _validateScopeId(scopeId),
        result = result,
        validationResult = validationResult;

  /// The normalized identifier of the scope associated with this execution.
  final String scopeId;

  /// The original result returned by the executed operation.
  ///
  /// This value is preserved without interpretation or transformation.
  ///
  /// Its presence means that the operation returned a value. It does not
  /// independently establish that the post-execution scope validation
  /// succeeded.
  final TResult result;

  /// The outcome of the post-execution scope validation.
  ///
  /// This value is independent of [result].
  ///
  /// A successful operation can therefore retain its original result
  /// while reporting that the scope could not be verified afterward.
  final AppEventSchemaMigrationAuditScopeExecutionValidationResult
      validationResult;

  /// Indicates whether the post-execution scope validation succeeded.
  bool get isPostExecutionValidationSuccessful {
    return validationResult ==
        AppEventSchemaMigrationAuditScopeExecutionValidationResult.verified;
  }

  /// Validates that the supplied scope identifier is already normalized.
  ///
  /// Scope identifiers must contain between 1 and 128 characters after
  /// trimming whitespace.
  ///
  /// Identifiers containing leading or trailing whitespace are rejected
  /// rather than silently normalized. This prevents the result from
  /// representing an identifier different from the one supplied by
  /// the execution service.
  static String _validateScopeId(String value) {
    final normalized = value.trim();

    if (normalized.isEmpty || normalized.length > 128) {
      throw ArgumentError.value(
        value,
        'scopeId',
        'A scope identifier must contain 1 to 128 characters.',
      );
    }

    if (normalized != value) {
      throw ArgumentError.value(
        value,
        'scopeId',
        'The scope identifier must already be normalized.',
      );
    }

    return normalized;
  }
}

/// Describes the outcome of post-execution scope validation.
///
/// This enum describes validation only. It does not describe whether
/// the operation itself succeeded or failed.
///
/// Operation failures that occur before a result is returned continue
/// to propagate as their original exceptions and do not produce an
/// execution result instance.
enum AppEventSchemaMigrationAuditScopeExecutionValidationResult {
  /// The scope was successfully verified after operation completion.
  verified,

  /// The scope could not be verified after operation completion.
  ///
  /// The original operation result remains available in the enclosing
  /// execution result.
  notVerified,
}
