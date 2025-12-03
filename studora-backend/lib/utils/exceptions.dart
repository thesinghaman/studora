class AppError implements Exception {
  final String message;
  final int statusCode;
  final String code;

  AppError({
    required this.message,
    this.statusCode = 500,
    this.code = 'INTERNAL_ERROR',
  });

  @override
  String toString() => 'AppError(message: $message, statusCode: $statusCode, code: $code)';
}

class ValidationError extends AppError {
  ValidationError(String message)
      : super(
          message: message,
          statusCode: 400,
          code: 'VALIDATION_ERROR',
        );
}

class NotFoundError extends AppError {
  NotFoundError(String message)
      : super(
          message: message,
          statusCode: 404,
          code: 'NOT_FOUND',
        );
}

class UnauthorizedError extends AppError {
  UnauthorizedError(String message)
      : super(
          message: message,
          statusCode: 401,
          code: 'UNAUTHORIZED',
        );
}
