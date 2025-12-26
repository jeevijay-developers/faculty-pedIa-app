class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;
  
  const ApiException({
    required this.message,
    this.statusCode,
    this.data,
  });
  
  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

class AuthException implements Exception {
  final String message;
  
  const AuthException(this.message);
  
  @override
  String toString() => 'AuthException: $message';
}

class NetworkException implements Exception {
  final String message;
  
  const NetworkException([this.message = 'No internet connection']);
  
  @override
  String toString() => 'NetworkException: $message';
}

class CacheException implements Exception {
  final String message;
  
  const CacheException([this.message = 'Cache error']);
  
  @override
  String toString() => 'CacheException: $message';
}

class ValidationException implements Exception {
  final String message;
  final Map<String, String>? errors;
  
  const ValidationException(this.message, {this.errors});
  
  @override
  String toString() => 'ValidationException: $message';
}
