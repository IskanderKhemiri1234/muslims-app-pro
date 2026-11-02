
import 'app_event_schema_migration_audit_repository_scope_context_registry_module_initialization_guard_provider_factory_service_result_policy_evaluation_result_acceptance_policy_evaluation_result_consumer_contract.dart';

/// Describes the type of an architectural consumer contract validation issue.
enum AppEventSchemaMigrationAuditAcceptanceConsumerContractValidationIssueType {
  missingReadableField,
  missingProhibitedOperation,
  duplicateReadableField,
  duplicateProhibitedOperation,
  executionPermissionGranted,
  initializationPermissionGranted,
  resourceReadinessEstablished,
  negativeIssueCount,
  issuePresenceMismatch,
  issueCountMismatch,
  issueCodesCountMismatch,
  issueDescriptionsCountMismatch,
  emptyIssueCode,
  emptyIssueDescription,
  evaluationStateMismatch,
  resultValidityMismatch,
  noIssuesStateMismatch,
}

/// Stable validation codes for consumer contract validation.
enum AppEventSchemaMigrationAuditAcceptanceConsumerContractValidationCode {
  missingReadableField(
    'ACCEPTANCE_CONSUMER_CONTRACT_MISSING_READABLE_FIELD',
  ),
  missingProhibitedOperation(
    'ACCEPTANCE_CONSUMER_CONTRACT_MISSING_PROHIBITED_OPERATION',
  ),
  duplicateReadableField(
    'ACCEPTANCE_CONSUMER_CONTRACT_DUPLICATE_READABLE_FIELD',
  ),
  duplicateProhibitedOperation(
    'ACCEPTANCE_CONSUMER_CONTRACT_DUPLICATE_PROHIBITED_OPERATION',
  ),
  executionPermissionGranted(
    'ACCEPTANCE_CONSUMER_CONTRACT_EXECUTION_PERMISSION_GRANTED',
  ),
  initializationPermissionGranted(
    'ACCEPTANCE_CONSUMER_CONTRACT_INITIALIZATION_PERMISSION_GRANTED',
  ),
  resourceReadinessEstablished(
    'ACCEPTANCE_CONSUMER_CONTRACT_RESOURCE_READINESS_ESTABLISHED',
  ),
  negativeIssueCount(
    'ACCEPTANCE_CONSUMER_SNAPSHOT_NEGATIVE_ISSUE_COUNT',
  ),
  issuePresenceMismatch(
    'ACCEPTANCE_CONSUMER_SNAPSHOT_ISSUE_PRESENCE_MISMATCH',
  ),
  issueCountMismatch(
    'ACCEPTANCE_CONSUMER_SNAPSHOT_ISSUE_COUNT_MISMATCH',
  ),
  issueCodesCountMismatch(
    'ACCEPTANCE_CONSUMER_SNAPSHOT_ISSUE_CODES_COUNT_MISMATCH',
  ),
  issueDescriptionsCountMismatch(
    'ACCEPTANCE_CONSUMER_SNAPSHOT_ISSUE_DESCRIPTIONS_COUNT_MISMATCH',
  ),
  emptyIssueCode(
    'ACCEPTANCE_CONSUMER_SNAPSHOT_EMPTY_ISSUE_CODE',
  ),
  emptyIssueDescription(
    'ACCEPTANCE_CONSUMER_SNAPSHOT_EMPTY_ISSUE_DESCRIPTION',
  ),
  evaluationStateMismatch(
    'ACCEPTANCE_CONSUMER_SNAPSHOT_EVALUATION_STATE_MISMATCH',
  ),
  resultValidityMismatch(
    'ACCEPTANCE_CONSUMER_SNAPSHOT_RESULT_VALIDITY_MISMATCH',
  ),
  noIssuesStateMismatch(
    'ACCEPTANCE_CONSUMER_SNAPSHOT_NO_ISSUES_STATE_MISMATCH',
  );

  const AppEventSchemaMigrationAuditAcceptanceConsumerContractValidationCode(
    this.value,
  );

  final String value;
}

/// Represents one immutable consumer contract validation issue.
class AppEventSchemaMigrationAuditAcceptanceConsumerContractValidationIssue {
  const AppEventSchemaMigrationAuditAcceptanceConsumerContractValidationIssue({
    required this.type,
    required this.code,
    required this.description,
  });

  final AppEventSchemaMigrationAuditAcceptanceConsumerContractValidationIssueType
      type;

  final AppEventSchemaMigrationAuditAcceptanceConsumerContractValidationCode
      code;

  final String description;

  String get codeValue => code.value;
}

/// Immutable report produced by the consumer contract validator.
class AppEventSchemaMigrationAuditAcceptanceConsumerContractValidationReport {
  AppEventSchemaMigrationAuditAcceptanceConsumerContractValidationReport({
    required List<
            AppEventSchemaMigrationAuditAcceptanceConsumerContractValidationIssue>
        issues,
  }) : issues = List<
            AppEventSchemaMigrationAuditAcceptanceConsumerContractValidationIssue>
        .unmodifiable(issues);

  final List<
      AppEventSchemaMigrationAuditAcceptanceConsumerContractValidationIssue>
      issues;

  bool get isValid => issues.isEmpty;

  bool get isInvalid => !isValid;

  bool get hasIssues => issues.isNotEmpty;

  int get issueCount => issues.length;

  List<String> get issueCodes => List<String>.unmodifiable(
        issues.map((issue) => issue.codeValue),
      );

  List<String> get issueDescriptions => List<String>.unmodifiable(
        issues.map((issue) => issue.description),
      );

  static AppEventSchemaMigrationAuditAcceptanceConsumerContractValidationReport
      fromIssues({
    required List<
            AppEventSchemaMigrationAuditAcceptanceConsumerContractValidationIssue>
        issues,
  }) {
    return AppEventSchemaMigrationAuditAcceptanceConsumerContractValidationReport(
      issues: issues,
    );
  }
}

/// Validates the structural and semantic consistency of a consumer contract
/// and its read-only snapshot.
///
/// This validator:
///
/// - Checks the declared readable fields.
/// - Checks the declared prohibited operations.
/// - Rejects duplicated contract declarations.
/// - Verifies that the contract grants no execution permissions.
/// - Verifies that the snapshot issue metadata is internally consistent.
/// - Verifies that the snapshot evaluation state agrees with its derived flags.
///
/// This validator does not:
///
/// - Re-evaluate acceptance policies.
/// - Execute another validator.
/// - Initialize modules or providers.
/// - Create, allocate, or dispose resources.
/// - Determine resource readiness.
/// - Grant execution or initialization permissions.
///
/// Execution authority remains exclusively with the Composition Root.
class AppEventSchemaMigrationAuditAcceptanceConsumerContractValidator {
  const AppEventSchemaMigrationAuditAcceptanceConsumerContractValidator();

  /// Validates a consumer contract and its corresponding snapshot.
  AppEventSchemaMigrationAuditAcceptanceConsumerContractValidationReport
      validate({
    required AppEventSchemaMigrationAuditAcceptanceConsumerContract contract,
    required AppEventSchemaMigrationAuditAcceptanceConsumerSnapshot snapshot,
  }) {
    final issues =
        <AppEventSchemaMigrationAuditAcceptanceConsumerContractValidationIssue>[];

    _validateReadableFields(
      contract: contract,
      issues: issues,
    );

    _validateProhibitedOperations(
      contract: contract,
      issues: issues,
    );

    _validatePermissionBoundaries(
      contract: contract,
      issues: issues,
    );

    _validateSnapshot(
      snapshot: snapshot,
      issues: issues,
    );

    return AppEventSchemaMigrationAuditAcceptanceConsumerContractValidationReport
        .fromIssues(
      issues: issues,
    );
  }

  void _validateReadableFields({
    required AppEventSchemaMigrationAuditAcceptanceConsumerContract contract,
    required List<
            AppEventSchemaMigrationAuditAcceptanceConsumerContractValidationIssue>
        issues,
  }) {
    final declaredFields =
        AppEventSchemaMigrationAuditAcceptanceConsumerContract
            .permittedReadableFields;

    final expectedFields =
        AppEventSchemaMigrationAuditConsumerExpectedValues.readableFields;

    for (final expectedField in expectedFields) {
      if (!contract.permitsReading(expectedField)) {
        issues.add(
          _issue(
            type:
                AppEventSchemaMigrationAuditAcceptanceConsumerContractValidationIssueType
                    .missingReadableField,
            code:
                AppEventSchemaMigrationAuditAcceptanceConsumerContractValidationCode
                    .missingReadableField,
            description:
                'The consumer contract does not permit the required readable field: ${expectedField.name}.',
          ),
        );
      }
    }

    _validateDuplicates(
      values: declaredFields,
      type:
          AppEventSchemaMigrationAuditAcceptanceConsumerContractValidationIssueType
              .duplicateReadableField,
      code:
          AppEventSchemaMigrationAuditAcceptanceConsumerContractValidationCode
              .duplicateReadableField,
      description:
          'The consumer contract contains a duplicated readable field declaration.',
      issues: issues,
    );
  }

  void _validateProhibitedOperations({
    required AppEventSchemaMigrationAuditAcceptanceConsumerContract contract,
    required List<
            AppEventSchemaMigrationAuditAcceptanceConsumerContractValidationIssue>
        issues,
  }) {
    final declaredOperations =
        AppEventSchemaMigrationAuditAcceptanceConsumerContract
            .prohibitedOperations;

    final expectedOperations =
        AppEventSchemaMigrationAuditConsumerExpectedValues.prohibitedOperations;

    for (final expectedOperation in expectedOperations) {
      if (!contract.prohibits(expectedOperation)) {
        issues.add(
          _issue(
            type:
                AppEventSchemaMigrationAuditAcceptanceConsumerContractValidationIssueType
                    .missingProhibitedOperation,
            code:
                AppEventSchemaMigrationAuditAcceptanceConsumerContractValidationCode
                    .missingProhibitedOperation,
            description:
                'The consumer contract does not prohibit the required operation: ${expectedOperation.name}.',
          ),
        );
      }
    }

    _validateDuplicates(
      values: declaredOperations,
      type:
          AppEventSchemaMigrationAuditAcceptanceConsumerContractValidationIssueType
              .duplicateProhibitedOperation,
      code:
          AppEventSchemaMigrationAuditAcceptanceConsumerContractValidationCode
              .duplicateProhibitedOperation,
      description:
          'The consumer contract contains a duplicated prohibited operation declaration.',
      issues: issues,
    );
  }

  void _validatePermissionBoundaries({
    required AppEventSchemaMigrationAuditAcceptanceConsumerContract contract,
    required List<
            AppEventSchemaMigrationAuditAcceptanceConsumerContractValidationIssue>
        issues,
  }) {
    if (contract.grantsExecutionPermission) {
      issues.add(
        _issue(
          type:
              AppEventSchemaMigrationAuditAcceptanceConsumerContractValidationIssueType
                  .executionPermissionGranted,
          code:
              AppEventSchemaMigrationAuditAcceptanceConsumerContractValidationCode
                  .executionPermissionGranted,
          description:
              'The consumer contract must never grant execution permission.',
        ),
      );
    }

    if (contract.grantsInitializationPermission) {
      issues.add(
        _issue(
          type:
              AppEventSchemaMigrationAuditAcceptanceConsumerContractValidationIssueType
                  .initializationPermissionGranted,
          code:
              AppEventSchemaMigrationAuditAcceptanceConsumerContractValidationCode
                  .initializationPermissionGranted,
          description:
              'The consumer contract must never grant initialization permission.',
        ),
      );
    }

    if (contract.establishesResourceReadiness) {
      issues.add(
        _issue(
          type:
              AppEventSchemaMigrationAuditAcceptanceConsumerContractValidationIssueType
                  .resourceReadinessEstablished,
          code:
              AppEventSchemaMigrationAuditConsumerExpectedValues
                  .resourceReadinessCode,
          description:
              'The consumer contract must not establish or infer resource readiness.',
        ),
      );
    }
  }

  void _validateSnapshot({
    required AppEventSchemaMigrationAuditAcceptanceConsumerSnapshot snapshot,
    required List<
            AppEventSchemaMigrationAuditAcceptanceConsumerContractValidationIssue>
        issues,
  }) {
    if (snapshot.issueCount < 0) {
      issues.add(
        _issue(
          type:
              AppEventSchemaMigrationAuditAcceptanceConsumerContractValidationIssueType
                  .negativeIssueCount,
          code:
              AppEventSchemaMigrationAuditAcceptanceConsumerContractValidationCode
                  .negativeIssueCount,
          description:
              'The snapshot issue count cannot be negative.',
        ),
      );
    }

    if (snapshot.hasIssues != (snapshot.issueCount > 0)) {
      issues.add(
        _issue(
          type:
              AppEventSchemaMigrationAuditAcceptanceConsumerContractValidationIssueType
                  .issuePresenceMismatch,
          code:
              AppEventSchemaMigrationAuditAcceptanceConsumerContractValidationCode
                  .issuePresenceMismatch,
          description:
              'The snapshot issue presence flag does not match its issue count.',
        ),
      );
    }

    if (snapshot.issueCodes.length != snapshot.issueCount) {
      issues.add(
        _issue(
          type:
              AppEventSchemaMigrationAuditAcceptanceConsumerContractValidationIssueType
                  .issueCodesCountMismatch,
          code:
              AppEventSchemaMigrationAuditAcceptanceConsumerContractValidationCode
                  .issueCodesCountMismatch,
          description:
              'The number of issue codes does not match the snapshot issue count.',
        ),
      );
    }

    if (snapshot.issueDescriptions.length != snapshot.issueCount) {
      issues.add(
        _issue(
          type:
              AppEventSchemaMigrationAuditAcceptanceConsumerContractValidationIssueType
                  .issueDescriptionsCountMismatch,
          code:
              AppEventSchemaMigrationAuditAcceptanceConsumerContractValidationCode
                  .issueDescriptionsCountMismatch,
          description:
              'The number of issue descriptions does not match the snapshot issue count.',
        ),
      );
    }

    _validateNonEmptyValues(
      values: snapshot.issueCodes,
      type:
          AppEventSchemaMigrationAuditAcceptanceConsumerContractValidationIssueType
              .emptyIssueCode,
      code:
          AppEventSchemaMigrationAuditAcceptanceConsumerContractValidationCode
              .emptyIssueCode,
      description:
          'The snapshot contains an empty or whitespace-only issue code.',
      issues: issues,
    );

    _validateNonEmptyValues(
      values: snapshot.issueDescriptions,
      type:
          AppEventSchemaMigrationAuditAcceptanceConsumerContractValidationIssueType
              .emptyIssueDescription,
      code:
          AppEventSchemaMigrationAuditAcceptanceConsumerContractValidationCode
              .emptyIssueDescription,
      description:
          'The snapshot contains an empty or whitespace-only issue description.',
      issues: issues,
    );

    _validateEvaluationState(snapshot, issues);
    _validateResultValidity(snapshot, issues);
    _validateNoIssuesState(snapshot, issues);
  }

  void _validateEvaluationState(
    AppEventSchemaMigrationAuditAcceptanceConsumerSnapshot snapshot,
    List<
            AppEventSchemaMigrationAuditAcceptanceConsumerContractValidationIssue>
        issues,
  ) {
    final accepted = snapshot.isEvaluationAccepted;
    final rejected = snapshot.isEvaluationRejected;
    final inconsistent = snapshot.isEvaluationInconsistent;

    final stateFlagCount = <bool>[
      accepted,
      rejected,
      inconsistent,
    ].where((value) => value).length;

    final expectedStateFlagCount = 1;

    final stateMatches =
        stateFlagCount == expectedStateFlagCount &&
        _matchesEvaluationState(snapshot);

    if (!stateMatches) {
      issues.add(
        _issue(
          type:
              AppEventSchemaMigrationAuditAcceptanceConsumerContractValidationIssueType
                  .evaluationStateMismatch,
          code:
              AppEventSchemaMigrationAuditAcceptanceConsumerContractValidationCode
                  .evaluationStateMismatch,
          description:
              'The snapshot evaluation state does not agree with its derived evaluation flags.',
        ),
      );
    }
  }

  bool _matchesEvaluationState(
    AppEventSchemaMigrationAuditAcceptanceConsumerSnapshot snapshot,
  ) {
    switch (snapshot.evaluationState) {
      case AppEventSchemaMigrationAuditAcceptanceConsumerEvaluationState
            .acceptedAndConsistent:
        return snapshot.isEvaluationAccepted &&
            !snapshot.isEvaluationRejected &&
            !snapshot.isEvaluationInconsistent;

      case AppEventSchemaMigrationAuditAcceptanceConsumerEvaluationState
            .rejectedAndConsistent:
        return !snapshot.isEvaluationAccepted &&
            snapshot.isEvaluationRejected &&
            !snapshot.isEvaluationInconsistent;

      case AppEventSchemaMigrationAuditAcceptanceConsumerEvaluationState
            .inconsistent:
        return !snapshot.isEvaluationAccepted &&
            !snapshot.isEvaluationRejected &&
            snapshot.isEvaluationInconsistent;
    }
  }

  void _validateResultValidity(
    AppEventSchemaMigrationAuditAcceptanceConsumerSnapshot snapshot,
    List<
            AppEventSchemaMigrationAuditAcceptanceConsumerContractValidationIssue>
        issues,
  ) {
    if (snapshot.isResultValid && snapshot.resultStatus != 'valid') {
      issues.add(
        _issue(
          type:
              AppEventSchemaMigrationAuditAcceptanceConsumerContractValidationIssueType
                  .resultValidityMismatch,
          code:
              AppEventSchemaMigrationAuditAcceptanceConsumerContractValidationCode
                  .resultValidityMismatch,
          description:
              'The snapshot reports a valid result but its status is not valid.',
        ),
      );
    }

    if (!snapshot.isResultValid && snapshot.resultStatus != 'invalid') {
      issues.add(
        _issue(
          type:
              AppEventSchemaMigrationAuditAcceptanceConsumerContractValidationIssueType
                  .resultValidityMismatch,
          code:
              AppEventSchemaMigrationAuditAcceptanceConsumerContractValidationCode
                  .resultValidityMismatch,
          description:
              'The snapshot reports an invalid result but its status is not invalid.',
        ),
      );
    }
  }

  void _validateNoIssuesState(
    AppEventSchemaMigrationAuditAcceptanceConsumerSnapshot snapshot,
    List<
            AppEventSchemaMigrationAuditAcceptanceConsumerContractValidationIssue>
        issues,
  ) {
    if (snapshot.hasNoIssues == snapshot.hasIssues) {
      issues.add(
        _issue(
          type:
              AppEventSchemaMigrationAuditAcceptanceConsumerContractValidationIssueType
                  .noIssuesStateMismatch,
          code:
              AppEventSchemaMigrationAuditAcceptanceConsumerContractValidationCode
                  .noIssuesStateMismatch,
          description:
              'The snapshot no-issues flag does not agree with its issue presence flag.',
        ),
      );
    }
  }

  void _validateDuplicates<T>({
    required List<T> values,
    required AppEventSchemaMigrationAuditAcceptanceConsumerContractValidationIssueType
        type,
    required AppEventSchemaMigrationAuditAcceptanceConsumerContractValidationCode
        code,
    required String description,
    required List<
            AppEventSchemaMigrationAuditAcceptanceConsumerContractValidationIssue>
        issues,
  }) {
    final uniqueValues = values.toSet();

    if (uniqueValues.length != values.length) {
      issues.add(
        _issue(
          type: type,
          code: code,
          description: description,
        ),
      );
    }
  }

  void _validateNonEmptyValues({
    required List<String> values,
    required AppEventSchemaMigrationAuditAcceptanceConsumerContractValidationIssueType
        type,
    required AppEventSchemaMigrationAuditAcceptanceConsumerContractValidationCode
        code,
    required String description,
    required List<
            AppEventSchemaMigrationAuditAcceptanceConsumerContractValidationIssue>
        issues,
  }) {
    for (final value in values) {
      if (value.trim().isEmpty) {
        issues.add(
          _issue(
            type: type,
            code: code,
            description: description,
          ),
        );
      }
    }
  }

  AppEventSchemaMigrationAuditAcceptanceConsumerContractValidationIssue
      _issue({
    required AppEventSchemaMigrationAuditAcceptanceConsumerContractValidationIssueType
        type,
    required AppEventSchemaMigrationAuditAcceptanceConsumerContractValidationCode
        code,
    required String description,
  }) {
    return AppEventSchemaMigrationAuditAcceptanceConsumerContractValidationIssue(
      type: type,
      code: code,
      description: description,
    );
  }
}

/// Centralized expected declarations for this validator.
///
/// This class contains static contract expectations only.
/// It does not perform validation, policy evaluation, or execution.
abstract final class AppEventSchemaMigrationAuditConsumerExpectedValues {
  static const List<
      AppEventSchemaMigrationAuditAcceptanceConsumerReadableField>
      readableFields = [
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

  static const resourceReadinessCode =
      AppEventSchemaMigrationAuditAcceptanceConsumerContractValidationCode
          .resourceReadinessEstablished;
}
