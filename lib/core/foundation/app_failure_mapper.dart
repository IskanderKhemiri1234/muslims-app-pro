
import 'app_exception.dart';

/// Converts external errors and exceptions into classified
/// application exceptions.
///
/// This class deliberately has no dependency on Flutter, UI,
/// persistence packages, networking packages, or logging systems.
abstract final class AppFailureMapper {
  AppFailureMapper._();

  /// Maps an arbitrary object into an application exception.
  ///
  /// Existing AppException instances are returned unchanged unless
  /// [overrideExisting] is true.
  static AppException map(
    Object error, {
    StackTrace? stackTrace,
    String? code,
    String? message,
    AppExceptionCategory? category,
    bool overrideExisting = false,
  }) {
    if (error is AppException && !overrideExisting) {
      return error;
    }

    final resolvedStackTrace = stackTrace ??
        (error is AppException ? error.stackTrace : null);

    final resolvedCause =
        error is AppException ? error.cause ?? error : error;

    final resolvedMessage =
        message ?? _defaultMessageFor(category);

    final resolvedCategory =
        category ?? _inferCategory(error);

    final resolvedCode =
        code ?? _defaultCodeFor(resolvedCategory);

    return _createException(
      category: resolvedCategory,
      code: resolvedCode,
      message: resolvedMessage,
      cause: resolvedCause,
      stackTrace: resolvedStackTrace,
    );
  }

  /// Maps an error known to originate from a location operation.
  static AppLocationException location(
    Object error, {
    StackTrace? stackTrace,
    String code = 'location.operation_failed',
    String message = 'The location operation failed.',
  }) {
    return AppLocationException(
      code: code,
      message: message,
      cause: error,
      stackTrace: stackTrace,
    );
  }

  /// Maps an error known to originate from a storage operation.
  static AppStorageException storage(
    Object error, {
    StackTrace? stackTrace,
    String code = 'storage.operation_failed',
    String message = 'The local storage operation failed.',
  }) {
    return AppStorageException(
      code: code,
      message: message,
      cause: error,
      stackTrace: stackTrace,
    );
  }

  /// Maps an error known to originate from a network operation.
  static AppNetworkException network(
    Object error, {
    StackTrace? stackTrace,
    String code = 'network.request_failed',
    String message = 'The network operation failed.',
  }) {
    return AppNetworkException(
      code: code,
      message: message,
      cause: error,
      stackTrace: stackTrace,
    );
  }

  /// Maps an error known to originate from a data operation.
  static AppDataException data(
    Object error, {
    StackTrace? stackTrace,
    String code = 'data.operation_failed',
    String message = 'The data operation failed.',
  }) {
    return AppDataException(
      code: code,
      message: message,
      cause: error,
      stackTrace: stackTrace,
    );
  }

  /// Maps an error known to originate from a calculation.
  static AppCalculationException calculation(
    Object error, {
    StackTrace? stackTrace,
    String code = 'calculation.failed',
    String message = 'The calculation could not be completed.',
  }) {
    return AppCalculationException(
      code: code,
      message: message,
      cause: error,
      stackTrace: stackTrace,
    );
  }

  /// Maps an error known to originate from a platform operation.
  static AppPlatformException platform(
    Object error, {
    StackTrace? stackTrace,
    String code = 'platform.operation_failed',
    String message = 'The platform operation failed.',
  }) {
    return AppPlatformException(
      code: code,
      message: message,
      cause: error,
      stackTrace: stackTrace,
    );
  }

  /// Maps an error known to originate from a permission operation.
  static AppPermissionException permission(
    Object error, {
    StackTrace? stackTrace,
    String code = 'permission.denied',
    String message = 'The required permission is unavailable.',
  }) {
    return AppPermissionException(
      code: code,
      message: message,
      cause: error,
      stackTrace: stackTrace,
    );
  }

  /// Creates an application exception from a known category.
  static AppException _createException({
    required AppExceptionCategory category,
    required String code,
    required String message,
    required Object cause,
    StackTrace? stackTrace,
  }) {
    return switch (category) {
      AppExceptionCategory.configuration =>
        AppConfigurationException(
          code: code,
          message: message,
          cause: cause,
          stackTrace: stackTrace,
        ),
      AppExceptionCategory.validation => AppValidationException(
          code: code,
          message: message,
          cause: cause,
          stackTrace: stackTrace,
        ),
      AppExceptionCategory.permission => AppPermissionException(
          code: code,
          message: message,
          cause: cause,
          stackTrace: stackTrace,
        ),
      AppExceptionCategory.location => AppLocationException(
          code: code,
          message: message,
          cause: cause,
          stackTrace: stackTrace,
        ),
      AppExceptionCategory.calculation => AppCalculationException(
          code: code,
          message: message,
          cause: cause,
          stackTrace: stackTrace,
        ),
      AppExceptionCategory.storage => AppStorageException(
          code: code,
          message: message,
          cause: cause,
          stackTrace: stackTrace,
        ),
      AppExceptionCategory.network => AppNetworkException(
          code: code,
          message: message,
          cause: cause,
          stackTrace: stackTrace,
        ),
      AppExceptionCategory.data => AppDataException(
          code: code,
          message: message,
          cause: cause,
          stackTrace: stackTrace,
        ),
      AppExceptionCategory.platform => AppPlatformException(
          code: code,
          message: message,
          cause: cause,
          stackTrace: stackTrace,
        ),
      AppExceptionCategory.state => AppStateException(
          code: code,
          message: message,
          cause: cause,
          stackTrace: stackTrace,
        ),
      AppExceptionCategory.unknown => AppUnknownException(
          code: code,
          message: message,
          cause: cause,
          stackTrace: stackTrace,
        ),
    };
  }

  /// Infers a category from known application exception types.
  ///
  /// Unknown external errors are classified as unknown rather than
  /// being guessed from their string representation.
  static AppExceptionCategory _inferCategory(Object error) {
    if (error is AppException) {
      return error.category;
    }

    return AppExceptionCategory.unknown;
  }

  static String _defaultCodeFor(AppExceptionCategory category) {
    return switch (category) {
      AppExceptionCategory.configuration => 'configuration.invalid',
      AppExceptionCategory.validation => 'validation.failed',
      AppExceptionCategory.permission => 'permission.denied',
      AppExceptionCategory.location => 'location.operation_failed',
      AppExceptionCategory.calculation => 'calculation.failed',
      AppExceptionCategory.storage => 'storage.operation_failed',
      AppExceptionCategory.network => 'network.request_failed',
      AppExceptionCategory.data => 'data.invalid',
      AppExceptionCategory.platform => 'platform.operation_failed',
      AppExceptionCategory.state => 'state.invalid',
      AppExceptionCategory.unknown => 'application.unknown_error',
    };
  }

  static String _defaultMessageFor(AppExceptionCategory? category) {
    return switch (category) {
      AppExceptionCategory.configuration =>
        'The application configuration is invalid.',
      AppExceptionCategory.validation =>
        'The supplied data failed validation.',
      AppExceptionCategory.permission =>
        'The required permission is unavailable.',
      AppExceptionCategory.location =>
        'The location operation failed.',
      AppExceptionCategory.calculation =>
        'The calculation could not be completed.',
      AppExceptionCategory.storage =>
        'The local storage operation failed.',
      AppExceptionCategory.network =>
        'The network operation failed.',
      AppExceptionCategory.data =>
        'The application data is invalid or unavailable.',
      AppExceptionCategory.platform =>
        'The platform operation failed.',
      AppExceptionCategory.state =>
        'The application is in an invalid state.',
      AppExceptionCategory.unknown || null =>
        'An unexpected application error occurred.',
    };
  }
}
