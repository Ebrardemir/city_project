import 'package:dio/dio.dart';

class NetworkException implements Exception {
  final String message;
  final int? statusCode;

  NetworkException(this.message, [this.statusCode]);

  @override
  String toString() => 'NetworkException: $message (Status Code: $statusCode)';
}

class BadRequestException extends NetworkException {
  BadRequestException([String? message]) : super(message ?? 'Bad Request', 400);
}

class UnauthorizedException extends NetworkException {
  UnauthorizedException([String? message])
    : super(message ?? 'Unauthorized', 401);
}

class ForbiddenException extends NetworkException {
  ForbiddenException([String? message]) : super(message ?? 'Forbidden', 403);
}

class NotFoundException extends NetworkException {
  NotFoundException([String? message]) : super(message ?? 'Not Found', 404);
}

class InternalServerErrorException extends NetworkException {
  InternalServerErrorException([String? message])
    : super(message ?? 'Internal Server Error', 500);
}

class NetworkConnectionException extends NetworkException {
  NetworkConnectionException([String? message])
    : super(message ?? 'No Internet Connection');
}

NetworkException getNetworkException(int statusCode, [String? message]) {
  switch (statusCode) {
    case 400:
      return BadRequestException(message);
    case 401:
      return UnauthorizedException(message);
    case 403:
      return ForbiddenException(message);
    case 404:
      return NotFoundException(message);
    case 500:
      return InternalServerErrorException(message);
    default:
      return NetworkException(message ?? 'Unknown Error', statusCode);
  }
}

/// Reusable mapper for DioException to our domain NetworkException
NetworkException mapDioErrorToNetworkException(DioException e) {
  // Server responded
  if (e.response != null) {
    final statusCode = e.response?.statusCode;
    final data = e.response?.data;
    final serverMessage = data is Map<String, dynamic>
        ? data['message'] as String?
        : null;
    if (statusCode != null) {
      return getNetworkException(statusCode, serverMessage);
    }
    return NetworkException(serverMessage ?? 'Unknown server error');
  }

  // No response: classify by error type
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.sendTimeout:
      return NetworkConnectionException('Request timed out');
    case DioExceptionType.badCertificate:
      return NetworkException('Bad SSL certificate');
    case DioExceptionType.connectionError:
      return NetworkConnectionException('Connection error');
    case DioExceptionType.cancel:
      return NetworkException('Request was cancelled');
    case DioExceptionType.badResponse:
      // Should be covered by e.response != null path, fallback here
      return NetworkException('Bad response from server');
    case DioExceptionType.unknown:
      return NetworkConnectionException('Connection failed');
  }
}
