/// Represents the outcome of one operation executed within an explicitly
/// identified application event schema migration audit repository scope.
///
/// This contract preserves the original operation result and associates it
/// with the normalized scope identifier used for execution.
///
/// Architectural responsibilities:
///
/// - Preserve the original operation result without transforming it.
/// - Preserve the scope identifier associated with the operation.
/// - Provide an immutable representation of a completed execution.
/// - Distinguish the result's scope identity from the operation's result.
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
/// - Does not classify arbitrary results as successful or failed.
/// - Does not claim rollback, atomicity, or transaction guarantees.
///
/// An instance represents an operation that returned a result.
/// Operations that throw do not produce an instance through this contract.
final class AppEventSchemaMigrationAuditScopeExecutionResult<TResult> {
  /// Creates an immutable execution result.
  ///
  /// The caller must supply the normalized scope identifier associated
  /// with the operation and the original result returned by that operation.
  ///
  /// This constructor does not independently verify that the scope exists
  /// or remains active.
  AppEventSchemaMigrationAuditScopeExecutionResult({
    required String scopeId,
    required TResult result,
  })  : scopeId = _validateScopeId(scopeId),
        result = result;

  /// The normalized identifier of the scope associated with this execution.
  final String scopeId;

  /// The original result returned by the executed operation.
  ///
  /// The value is preserved without interpretation or transformation.
  final TResult result;

  /// Validates that the supplied scope identifier is already normalized.
  ///
  /// Scope identifiers must contain between 1 and 128 characters after
  /// trimming whitespace.
  ///
  /// Unlike a normalizing constructor, this validation rejects identifiers
  /// containing leading or trailing whitespace. This prevents the result
  /// from silently representing a different identifier than the caller used.
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
