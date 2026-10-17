/// Base class for all application exceptions.
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  const AppException(this.message, {this.code, this.details});

  @override
  String toString() => code != null
      ? 'AppException [$code]: $message'
      : 'AppException: $message';
}

class NotFoundException extends AppException {
  const NotFoundException(super.message,
      {super.code = 'NOT_FOUND', super.details});
}

class UnauthorizedException extends AppException {
  const UnauthorizedException(super.message,
      {super.code = 'UNAUTHORIZED', super.details});
}

class ValidationException extends AppException {
  const ValidationException(super.message,
      {super.code = 'VALIDATION_ERROR', super.details});
}

class NetworkException extends AppException {
  const NetworkException(super.message,
      {super.code = 'NETWORK_ERROR', super.details});
}

class SimulationException extends AppException {
  const SimulationException(super.message,
      {super.code = 'SIMULATED_FAILURE', super.details});
}
