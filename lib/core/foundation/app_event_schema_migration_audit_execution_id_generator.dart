
/// Defines the contract for generating execution identifiers.
///
/// Each generated identifier represents one execution instance within
/// the application event schema migration audit subsystem.
///
/// Architectural responsibilities:
///
/// - Generate an execution identifier.
/// - Provide a synchronous identifier-generation contract.
/// - Allow identifier-generation implementations to be injected.
///
/// Architectural restrictions:
///
/// - Does not execute repository operations.
/// - Does not resolve or validate repository scopes.
/// - Does not create diagnostic records.
/// - Does not record diagnostic events.
/// - Does not measure execution duration.
/// - Does not access repositories or scope registries.
/// - Does not define a specific identifier-generation algorithm.
/// - Does not guarantee global uniqueness unless the implementation
///   explicitly provides that guarantee.
///
/// Contract requirements:
///
/// - Generated identifiers must not be empty.
/// - Generated identifiers must contain no leading or trailing
///   whitespace.
/// - Generated identifiers must contain no more than 128 characters.
///
/// Consumers remain responsible for validating generated identifiers
/// against the diagnostic model's identifier constraints.
abstract interface class
    AppEventSchemaMigrationAuditExecutionIdGenerator {
  /// Generates an identifier for one execution instance.
  ///
  /// Implementations must return a non-empty, already-normalized
  /// identifier containing no more than 128 characters.
  ///
  /// This contract does not prescribe UUID, ULID, or any other
  /// identifier-generation strategy.
  String generate();
}
