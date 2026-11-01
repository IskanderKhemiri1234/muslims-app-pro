
/// Base class for application-level exceptions.
///
/// Exceptions represent unexpected or exceptional execution conditions.
/// They are not intended to replace AppResult as the representation
/// of expected operation outcomes.
sealed class AppException implements Exception {
  const AppException({
    required this.code,
    required this.message,
    this.cause,
    this.stackTrace,
  });

  /// Stable identifier suitable for logging and error classification.
  final String code;

  /// Technical description of the exceptional condition.
  ///
  /// This message should not automatically be displayed to end users.
  final String message;

  /// Original error that caused this exception, if available.
  final Object? cause;

  /// Original stack trace, if available.
  final StackTrace? stackTrace;

  /// Category used by diagnostics and centralized error handling.
  AppExceptionCategory get category;

  @override
  String toString() {
    return '$runtimeType(code: $code, message: $message)';
  }
}

/// Broad categories for application exceptions.
enum AppExceptionCategory {
  configuration,
  validation,
  permission,
  location,
  calculation,
  storage,
  network,
  data,
  platform,
  state,
  unknown,
}

/// Thrown when application configuration is invalid or incomplete.
final class AppConfigurationException extends AppException {
  const AppConfigurationException({
    required super.code,
    required super.message,
    super.cause,
    super.stackTrace,
  });

  @override
  AppExceptionCategory get category =>
      AppExceptionCategory.configuration;
}

/// Thrown when an internal input violates a required constraint.
final class AppValidationException extends AppException {
  const AppValidationException({
    required super.code,
    required super.message,
    super.cause,
    super.stackTrace,
  });

  @override
  AppExceptionCategory get category =>
      AppExceptionCategory.validation;
}

/// Thrown when a required device or application permission
/// is unavailable for an operation.
final class AppPermissionException extends AppException {
  const AppPermissionException({
    required super.code,
    required super.message,
    super.cause,
    super.stackTrace,
  });

  @override
  AppExceptionCategory get category =>
      AppExceptionCategory.permission;
}

/// Thrown when location acquisition or location processing fails.
final class AppLocationException extends AppException {
  const AppLocationException({
    required super.code,
    required super.message,
    super.cause,
    super.stackTrace,
  });

  @override
  AppExceptionCategory get category =>
      AppExceptionCategory.location;
}

/// Thrown when a domain calculation cannot be completed reliably.
final class AppCalculationException extends AppException {
  const AppCalculationException({
    required super.code,
    required super.message,
    super.cause,
    super.stackTrace,
  });

  @override
  AppExceptionCategory get category =>
      AppExceptionCategory.calculation;
}

/// Thrown when local persistence operations fail.
final class AppStorageException extends AppException {
  const AppStorageException({
    required super.code,
    required super.message,
    super.cause,
    super.stackTrace,
  });

  @override
  AppExceptionCategory get category =>
      AppExceptionCategory.storage;
}

/// Thrown when a network operation fails unexpectedly.
final class AppNetworkException extends AppException {
  const AppNetworkException({
    required super.code,
    required super.message,
    super.cause,
    super.stackTrace,
  });

  @override
  AppExceptionCategory get category =>
      AppExceptionCategory.network;
}

/// Thrown when application data is missing, corrupted,
/// inconsistent, or cannot be decoded.
final class AppDataException extends AppException {
  const AppDataException({
    required super.code,
    required super.message,
    super.cause,
    super.stackTrace,
  });

  @override
  AppExceptionCategory get category =>
      AppExceptionCategory.data;
}

/// Thrown when a platform-specific operation fails.
final class AppPlatformException extends AppException {
  const AppPlatformException({
    required super.code,
    required super.message,
    super.cause,
    super.stackTrace,
  });

  @override
  AppExceptionCategory get category =>
      AppExceptionCategory.platform;
}

/// Thrown when an operation is attempted in an invalid
/// application state.
final class AppStateException extends AppException {
  const AppStateException({
    required super.code,
    required super.message,
    super.cause,
    super.stackTrace,
  });

  @override
  AppExceptionCategory get category =>
      AppExceptionCategory.state;
}

/// Thrown when an error cannot be classified more precisely.
final class AppUnknownException extends AppException {
  const AppUnknownException({
    required super.code,
    required super.message,
    super.cause,
    super.stackTrace,
  });

  @override
  AppExceptionCategory get category =>
      AppExceptionCategory.unknown;
}
