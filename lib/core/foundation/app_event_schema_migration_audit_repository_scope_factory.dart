
import 'app_event_schema_migration_audit_repository.dart';
import 'app_event_schema_migration_audit_repository_scope.dart';

/// Identifies errors raised while creating audit repository scopes.
enum AppEventSchemaMigrationAuditRepositoryScopeFactoryErrorCode {
  invalidScopeId,
  duplicateScopeId,
  disposedFactory,
}

/// Represents a scope factory creation error.
final class AppEventSchemaMigrationAuditRepositoryScopeFactoryException
    implements Exception {
  const AppEventSchemaMigrationAuditRepositoryScopeFactoryException({
    required this.code,
    required this.message,
  });

  final AppEventSchemaMigrationAuditRepositoryScopeFactoryErrorCode code;
  final String message;

  @override
  String toString() {
    return 'AppEventSchemaMigrationAuditRepositoryScopeFactoryException'
        '(code: ${code.name}, message: $message)';
  }
}

/// Creates isolated audit repository scopes from injected repositories.
///
/// The factory owns only the identifiers it has issued. It does not own
/// repositories, data sources, readers, or the lifecycle of created scopes.
final class AppEventSchemaMigrationAuditRepositoryScopeFactory {
  AppEventSchemaMigrationAuditRepositoryScopeFactory();

  final Set<String> _issuedScopeIds = <String>{};

  bool _disposed = false;

  /// Returns the number of identifiers issued by this factory.
  int get issuedScopeCount {
    _ensureActive();
    return _issuedScopeIds.length;
  }

  /// Indicates whether the factory has been disposed.
  bool get isDisposed => _disposed;

  /// Creates a new isolated scope.
  ///
  /// Scope identifiers are unique for the lifetime of this factory.
  /// Reusing an identifier is rejected even if a previously created scope
  /// has already been disposed or unregistered.
  AppEventSchemaMigrationAuditRepositoryScope create({
    required String scopeId,
    required AppEventSchemaMigrationAuditRepository repository,
  }) {
    _ensureActive();

    final normalizedId = _normalizeScopeId(scopeId);

    if (_issuedScopeIds.contains(normalizedId)) {
      throw AppEventSchemaMigrationAuditRepositoryScopeFactoryException(
        code: AppEventSchemaMigrationAuditRepositoryScopeFactoryErrorCode
            .duplicateScopeId,
        message: 'The scope identifier "$normalizedId" '
            'has already been issued by this factory.',
      );
    }

    final scope = AppEventSchemaMigrationAuditRepositoryScope(
      scopeId: normalizedId,
      repository: repository,
    );

    _issuedScopeIds.add(normalizedId);

    return scope;
  }

  /// Disposes the factory and prevents further scope creation.
  ///
  /// Previously created scopes remain valid and retain their own lifecycle.
  /// Disposing the factory does not dispose scopes or repositories.
  void dispose() {
    if (_disposed) {
      return;
    }

    _disposed = true;
    _issuedScopeIds.clear();
  }

  void _ensureActive() {
    if (_disposed) {
      throw const AppEventSchemaMigrationAuditRepositoryScopeFactoryException(
        code: AppEventSchemaMigrationAuditRepositoryScopeFactoryErrorCode
            .disposedFactory,
        message: 'The audit repository scope factory has been disposed.',
      );
    }
  }

  String _normalizeScopeId(String value) {
    final normalized = value.trim();

    if (normalized.isEmpty || normalized.length > 128) {
      throw const AppEventSchemaMigrationAuditRepositoryScopeFactoryException(
        code: AppEventSchemaMigrationAuditRepositoryScopeFactoryErrorCode
            .invalidScopeId,
        message: 'A scope identifier must contain 1 to 128 characters.',
      );
    }

    return normalized;
  }
}
