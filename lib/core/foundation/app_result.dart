
/// A typed result for operations that may succeed or fail.
///
/// Use [AppSuccess] for successful operations and [AppError] for failures.
/// This keeps application-level failures explicit and predictable.
sealed class AppResult<T> {
  const AppResult();

  bool get isSuccess => this is AppSuccess<T>;

  bool get isFailure => this is AppError<T>;

  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(AppFailure failure) onFailure,
  }) {
    return switch (this) {
      AppSuccess<T>(:final value) => onSuccess(value),
      AppError<T>(:final failure) => onFailure(failure),
    };
  }

  AppResult<R> map<R>(R Function(T value) transform) {
    return switch (this) {
      AppSuccess<T>(:final value) => AppSuccess<R>(transform(value)),
      AppError<T>(:final failure) => AppError<R>(failure),
    };
  }

  AppResult<R> mapFailure<R>(
    AppFailure Function(AppFailure failure) transform,
  ) {
    return switch (this) {
      AppSuccess<T>(:final value) => AppSuccess<R>(value as R),
      AppError<T>(:final failure) => AppError<R>(transform(failure)),
    };
  }
}

/// Represents a successful operation.
final class AppSuccess<T> extends AppResult<T> {
  const AppSuccess(this.value);

  final T value;
}

/// Represents a failed operation.
final class AppError<T> extends AppResult<T> {
  const AppError(this.failure);

  final AppFailure failure;
}

/// A structured application failure.
///
/// [code] is stable and suitable for programmatic handling.
/// [message] is a safe descriptive message, not necessarily user-facing.
/// [cause] and [stackTrace] preserve diagnostic context when available.
final class AppFailure {
  const AppFailure({
    required this.code,
    required this.message,
    this.cause,
    this.stackTrace,
  });

  final String code;
  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() => 'AppFailure(code: $code, message: $message)';
}
