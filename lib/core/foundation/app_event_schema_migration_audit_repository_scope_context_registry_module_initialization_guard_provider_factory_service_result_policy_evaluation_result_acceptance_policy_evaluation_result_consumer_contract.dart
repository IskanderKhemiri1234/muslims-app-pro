
import 'app_event_schema_migration_audit_repository_scope_context_registry_module_initialization_guard_provider_factory_service_result_policy_evaluation_result_acceptance_policy_evaluation_result.dart'
    as acceptance_result;

/// Defines the information that downstream consumers may observe.
///
/// This contract is descriptive and provides a read-only projection.
/// It is not an authorization mechanism or a security boundary.
enum AppEventSchemaMigrationAuditAcceptanceConsumerReadableField {
  resultStatus,
  resultValidity,
  resultIssuePresence,
  resultIssueCount,
  resultIssueCodes,
  resultIssueDescriptions,
  acceptanceEvaluationState,
}

/// Defines the architectural operations that consumers must not perform
/// based on an acceptance evaluation result.
enum AppEventSchemaMigrationAuditAcceptanceConsumerProhibitedOperation {
  initializeModule,
  createProvider,
  createRepository,
  createService,
  allocateResources,
  disposeResources,
  changeInitializationState,
  bypassCompositionRoot,
  interpretValidationAsAuthorization,
  interpretAcceptanceAsExecutionPermission,
  inferResourceReadiness,
}

/// Describes the semantic state of the underlying acceptance evaluation.
///
/// These states describe the evaluation only. They do not authorize execution.
enum AppEventSchemaMigrationAuditAcceptanceConsumerEvaluationState {
  acceptedAndConsistent,
  rejectedAndConsistent,
  inconsistent,
}

/// Immutable read-only view exposed to downstream consumers.
///
/// Important distinctions:
///
/// - [isResultValid] describes consistency between the result and its
///   validation report.
/// - [evaluationState] describes the underlying acceptance evaluation.
/// - Neither property grants initialization or execution permission.
class AppEventSchemaMigrationAuditAcceptanceConsumerSnapshot {
  AppEventSchemaMigrationAuditAcceptanceConsumerSnapshot._({
    required this.resultStatus,
    required this.isResultValid,
    required this.hasIssues,
    required this.issueCount,
    required List<String> issueCodes,
    required List<String> issueDescriptions,
    required this.evaluationState,
  })  : issueCodes = List<String>.unmodifiable(issueCodes),
        issueDescriptions = List<String>.unmodifiable(issueDescriptions);

  /// Human-readable status of the result.
  final String resultStatus;

  /// Whether the result agrees with its validation report.
  ///
  /// This does not mean that the underlying acceptance evaluation
  /// was accepted.
  final bool isResultValid;

  /// Whether the aggregated result contains issues.
  final bool hasIssues;

  /// Number of aggregated issues exposed by the result.
  final int issueCount;

  /// Stable issue codes in their original order.
  final List<String> issueCodes;

  /// Issue descriptions in their original order.
  final List<String> issueDescriptions;

  /// State of the underlying acceptance evaluation.
  final AppEventSchemaMigrationAuditAcceptanceConsumerEvaluationState
      evaluationState;

  /// Indicates whether the underlying evaluation was accepted consistently.
  ///
  /// This is descriptive information, not execution authorization.
  bool get isEvaluationAccepted =>
      evaluationState ==
      AppEventSchemaMigrationAuditAcceptanceConsumerEvaluationState
          .acceptedAndConsistent;

  /// Indicates whether the underlying evaluation was rejected consistently.
  bool get isEvaluationRejected =>
      evaluationState ==
      AppEventSchemaMigrationAuditAcceptanceConsumerEvaluationState
          .rejectedAndConsistent;

  /// Indicates whether the underlying evaluation was inconsistent.
  bool get isEvaluationInconsistent =>
      evaluationState ==
      AppEventSchemaMigrationAuditAcceptanceConsumerEvaluationState
          .inconsistent;

  /// Indicates whether the result contains no reported issues.
  ///
  /// This is an observation only. It must not be interpreted as permission
  /// to initialize or execute anything.
  bool get hasNoIssues => !hasIssues;
}

/// Architectural consumer contract for acceptance evaluation results.
///
/// Responsibilities:
///
/// - Define the information that consumers may read.
/// - Preserve the distinction between result validity and policy acceptance.
/// - Expose a read-only snapshot.
/// - Document prohibited interpretations and operations.
///
/// This contract does not enforce restrictions on arbitrary Dart code.
/// Actual execution decisions remain exclusively with the Composition Root.
class AppEventSchemaMigrationAuditAcceptanceConsumerContract {
  const AppEventSchemaMigrationAuditAcceptanceConsumerContract();

  /// Contract version for future compatibility management.
  static const int version = 1;

  /// Declares the fields available to downstream consumers.
  static const List<
      AppEventSchemaMigrationAuditAcceptanceConsumerReadableField>
      permittedReadableFields = [
    AppEventSchemaMigrationAuditAcceptanceConsumerReadableField.resultStatus,
    AppEventSchemaMigrationAuditAcceptanceConsumerReadableField.resultValidity,
    AppEventSchemaMigrationAuditAcceptanceConsumerReadableField
        .resultIssuePresence,
    AppEventSchemaMigrationAuditAcceptanceConsumerReadableField
        .resultIssueCount,
    AppEventSchemaMigrationAuditAcceptanceConsumerReadableField
        .resultIssueCodes,
    AppEventSchemaMigrationAuditAcceptanceConsumerReadableField
        .resultIssueDescriptions,
    AppEventSchemaMigrationAuditAcceptanceConsumerReadableField
        .acceptanceEvaluationState,
  ];

  /// Declares operations that must remain outside consumer responsibility.
  static const List<
      AppEventSchemaMigrationAuditAcceptanceConsumerProhibitedOperation>
      prohibitedOperations = [
    AppEventSchemaMigrationAuditAcceptanceConsumerProhibitedOperation
        .initializeModule,
    AppEventSchemaMigrationAuditAcceptanceConsumerProhibitedOperation
        .createProvider,
    AppEventSchemaMigrationAuditAcceptanceConsumerProhibitedOperation
        .createRepository,
    AppEventSchemaMigrationAuditAcceptanceConsumerProhibitedOperation
        .createService,
    AppEventSchemaMigrationAuditAcceptanceConsumerProhibitedOperation
        .allocateResources,
    AppEventSchemaMigrationAuditAcceptanceConsumerProhibitedOperation
        .disposeResources,
    AppEventSchemaMigrationAuditAcceptanceConsumerProhibitedOperation
        .changeInitializationState,
    AppEventSchemaMigrationAuditAcceptanceConsumerProhibitedOperation
        .bypassCompositionRoot,
    AppEventSchemaMigrationAuditAcceptanceConsumerProhibitedOperation
        .interpretValidationAsAuthorization,
    AppEventSchemaMigrationAuditAcceptanceConsumerProhibitedOperation
        .interpretAcceptanceAsExecutionPermission,
    AppEventSchemaMigrationAuditAcceptanceConsumerProhibitedOperation
        .inferResourceReadiness,
  ];

  /// Creates a read-only consumer snapshot from an existing result.
  ///
  /// No policy is re-evaluated.
  /// No validator is executed.
  /// No resource is created, initialized, or disposed.
  ///
  /// The evaluation state and result validity are intentionally projected
  /// as separate values.
  AppEventSchemaMigrationAuditAcceptanceConsumerSnapshot createSnapshot({
    required acceptance_result
        .AppEventSchemaMigrationAuditRepositoryScopeContextRegistryModuleInitializationGuardProviderFactoryServiceResultPolicyEvaluationResultAcceptancePolicyEvaluationResult
            result,
  }) {
    final evaluation = result.evaluation;

    final AppEventSchemaMigrationAuditAcceptanceConsumerEvaluationState
        evaluationState;

    if (evaluation.isAcceptedAndConsistent) {
      evaluationState =
          AppEventSchemaMigrationAuditAcceptanceConsumerEvaluationState
              .acceptedAndConsistent;
    } else if (evaluation.isRejectedAndConsistent) {
      evaluationState =
          AppEventSchemaMigrationAuditAcceptanceConsumerEvaluationState
              .rejectedAndConsistent;
    } else {
      evaluationState =
          AppEventSchemaMigrationAuditAcceptanceConsumerEvaluationState
              .inconsistent;
    }

    return AppEventSchemaMigrationAuditAcceptanceConsumerSnapshot._(
      resultStatus: result.statusName,
      isResultValid: result.isValid,
      hasIssues: result.hasIssues,
      issueCount: result.issueCount,
      issueCodes: result.issueCodes,
      issueDescriptions: result.issueDescriptions,
      evaluationState: evaluationState,
    );
  }

  /// Returns whether a field is part of the documented read contract.
  bool permitsReading(
    AppEventSchemaMigrationAuditAcceptanceConsumerReadableField field,
  ) {
    return permittedReadableFields.contains(field);
  }

  /// Returns whether an operation is explicitly prohibited.
  bool prohibits(
    AppEventSchemaMigrationAuditAcceptanceConsumerProhibitedOperation
        operation,
  ) {
    return prohibitedOperations.contains(operation);
  }

  /// Documents the contract's execution boundary.
  ///
  /// This is always false because this contract never grants execution
  /// authority, regardless of the result or evaluation state.
  bool get grantsExecutionPermission => false;

  /// Documents the contract's initialization boundary.
  ///
  /// Initialization decisions belong exclusively to the Composition Root.
  bool get grantsInitializationPermission => false;

  /// Documents whether this contract establishes resource readiness.
  bool get establishesResourceReadiness => false;
}
