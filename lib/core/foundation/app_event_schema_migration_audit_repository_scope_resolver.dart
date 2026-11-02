
import 'app_event_schema_migration_audit_repository.dart';
import 'app_event_schema_migration_audit_repository_scope.dart';
import 'app_event_schema_migration_audit_repository_scope_registry.dart';

/// Identifies scope resolution failures.
enum AppEventSchemaMigrationAuditRepositoryScopeResolutionErrorCode {
  invalidScopeId,
  scopeNotFound,
  scopeDisposed,
  repositoryUnavailable,
  scopeIdentityMismatch,
  registryUnavailable,
}

/// Represents a scope resolution failure.
final class AppEventSchemaMigrationAuditRepositoryScopeResolutionException
    implements Exception {
  const AppEventSchemaMigrationAuditRepositoryScopeResolutionException({
    required this.code,
    required this.message,
  });

  final AppEventSchemaMigrationAuditRepositoryScopeResolutionErrorCode code;
  final String message;

  @override
  String toString() {
    return 'AppEventSchemaMigrationAuditRepositoryScopeResolutionException'
        '(code: ${code.name}, message: $message)';
  }
}

/// Contains the validated result of resolving an audit repository scope.
///
/// The resolved repository is obtained from an active scope registered
/// under the requested identifier.
final class AppEventSchemaMigrationAuditRepositoryScopeResolution {
  const AppEventSchemaMigrationAuditRepositoryScopeResolution._({
    required this.scopeId,
    required this.scope,
    required this.repository,
  });

  final String scopeId;

  final AppEventSchemaMigrationAuditRepositoryScope scope;

  final AppEventSchemaMigrationAuditRepository repository;

  /// Indicates whether the resolved scope remains active.
  bool get isActive => scope.isActive;

  /// Verifies that the resolved scope remains usable.
  ///
  /// Call this before beginning an operation that requires an active scope.
  void verifyActive() {
    if (!scope.isActive) {
      throw const AppEventSchemaMigrationAuditRepositoryScopeResolutionException(
        code: AppEventSchemaMigrationAuditRepositoryScopeResolutionErrorCode
            .scopeDisposed,
        message: 'The resolved audit repository scope is no longer active.',
      );
    }

    if (scope.scopeId != scopeId) {
      throw const AppEventSchemaMigrationAuditRepositoryScopeResolutionException(
        code: AppEventSchemaMigrationAuditRepositoryScopeResolutionErrorCode
            .scopeIdentityMismatch,
        message: 'The resolved scope identifier has changed.',
      );
    }
  }
}

/// Resolves audit repository scopes through an injected registry.
///
/// The resolver does not create, register, unregister, or dispose scopes.
/// It only provides validated access to scopes managed by the registry.
final class AppEventSchemaMigrationAuditRepositoryScopeResolver {
  const AppEventSchemaMigrationAuditRepositoryScopeResolver({
    required AppEventSchemaMigrationAuditRepositoryScopeRegistry registry,
  }) : _registry = registry;

  final AppEventSchemaMigrationAuditRepositoryScopeRegistry _registry;

  /// Resolves a scope by its identifier.
  ///
  /// The returned result contains the scope and its repository after
  /// successful identity and lifecycle validation.
  AppEventSchemaMigrationAuditRepositoryScopeResolution resolve(
    String scopeId,
  ) {
    final normalizedId = _normalizeScopeId(scopeId);

    try {
      final scope = _registry.get(normalizedId);

      if (scope.scopeId != normalizedId) {
        throw const AppEventSchemaMigrationAuditRepositoryScopeResolutionException(
          code: AppEventSchemaMigrationAuditRepositoryScopeResolutionErrorCode
              .scopeIdentityMismatch,
          message: 'The registered scope does not match the requested ID.',
        );
      }

      if (!scope.isActive) {
        throw const AppEventSchemaMigrationAuditRepositoryScopeResolutionException(
          code: AppEventSchemaMigrationAuditRepositoryScopeResolutionErrorCode
              .scopeDisposed,
          message: 'The requested scope has been disposed.',
        );
      }

      final repository = scope.repository;

      final result =
          AppEventSchemaMigrationAuditRepositoryScopeResolution._(
        scopeId: normalizedId,
        scope: scope,
        repository: repository,
      );

      result.verifyActive();

      return result;
    } on AppEventSchemaMigrationAuditRepositoryScopeRegistryException catch (
        error) {
      throw _mapRegistryError(error);
    } on AppEventSchemaMigrationAuditRepositoryScopeException catch (error) {
      throw _mapScopeError(error);
    }
  }

  /// Resolves a scope and returns its repository directly.
  ///
  /// This is a convenience operation for consumers that do not need
  /// to retain the scope resolution metadata.
  AppEventSchemaMigrationAuditRepository resolveRepository(
    String scopeId,
  ) {
    final resolution = resolve(scopeId);
    resolution.verifyActive();
    return resolution.repository;
  }

  /// Checks whether an active scope can be resolved.
  ///
  /// Invalid identifiers and disposed registries are reported as errors.
  /// A missing or disposed scope returns false.
  bool canResolve(String scopeId) {
    try {
      resolve(scopeId);
      return true;
    } on AppEventSchemaMigrationAuditRepositoryScopeResolutionException catch (
        error) {
      if (error.code ==
              AppEventSchemaMigrationAuditRepositoryScopeResolutionErrorCode
                  .scopeNotFound ||
          error.code ==
              AppEventSchemaMigrationAuditRepositoryScopeResolutionErrorCode
                  .scopeDisposed) {
        return false;
      }

      rethrow;
    }
  }

  String _normalizeScopeId(String value) {
    final normalized = value.trim();

    if (normalized.isEmpty || normalized.length > 128) {
      throw const AppEventSchemaMigrationAuditRepositoryScopeResolutionException(
        code: AppEventSchemaMigrationAuditRepositoryScopeResolutionErrorCode
            .invalidScopeId,
        message: 'A scope identifier must contain 1 to 128 characters.',
      );
    }

    return normalized;
  }

  AppEventSchemaMigrationAuditRepositoryScopeResolutionException
      _mapRegistryError(
    AppEventSchemaMigrationAuditRepositoryScopeRegistryException error,
  ) {
    final code =
        switch (error.code) {
          AppEventSchemaMigrationAuditRepositoryScopeRegistryErrorCode
                .invalidScopeId =>
            AppEventSchemaMigrationAuditRepositoryScopeResolutionErrorCode
                .invalidScopeId,
          AppEventSchemaMigrationAuditRepositoryScopeRegistryErrorCode
                .scopeNotFound =>
            AppEventSchemaMigrationAuditRepositoryScopeResolutionErrorCode
                .scopeNotFound,
          AppEventSchemaMigrationAuditRepositoryScopeRegistryErrorCode
                .scopeDisposed =>
            AppEventSchemaMigrationAuditRepositoryScopeResolutionErrorCode
                .scopeDisposed,
          AppEventSchemaMigrationAuditRepositoryScopeRegistryErrorCode
                .registryDisposed =>
            AppEventSchemaMigrationAuditRepositoryScopeResolutionErrorCode
                .registryUnavailable,
          AppEventSchemaMigrationAuditRepositoryScopeRegistryErrorCode
                .duplicateScopeId =>
            AppEventSchemaMigrationAuditRepositoryScopeResolutionErrorCode
                .scopeIdentityMismatch,
          AppEventSchemaMigrationAuditRepositoryScopeRegistryErrorCode
                .scopeIdentityMismatch =>
            AppEventSchemaMigrationAuditRepositoryScopeResolutionErrorCode
                .scopeIdentityMismatch,
        };

    return AppEventSchemaMigrationAuditRepositoryScopeResolutionException(
      code: code,
      message: error.message,
    );
  }

  AppEventSchemaMigrationAuditRepositoryScopeResolutionException
      _mapScopeError(
    AppEventSchemaMigrationAuditRepositoryScopeException error,
  ) {
    final code =
        switch (error.code) {
          AppEventSchemaMigrationAuditRepositoryScopeErrorCode.invalidIdentifier =>
            AppEventSchemaMigrationAuditRepositoryScopeResolutionErrorCode
                .invalidScopeId,
          AppEventSchemaMigrationAuditRepositoryScopeErrorCode.disposed =>
            AppEventSchemaMigrationAuditRepositoryScopeResolutionErrorCode
                .scopeDisposed,
          AppEventSchemaMigrationAuditRepositoryScopeErrorCode.scopeMismatch =>
            AppEventSchemaMigrationAuditRepositoryScopeResolutionErrorCode
                .scopeIdentityMismatch,
          AppEventSchemaMigrationAuditRepositoryScopeErrorCode.duplicateRegistration =>
            AppEventSchemaMigrationAuditRepositoryScopeResolutionErrorCode
                .scopeIdentityMismatch,
        };

    return AppEventSchemaMigrationAuditRepositoryScopeResolutionException(
      code: code,
      message: error.message,
    );
  }
}
