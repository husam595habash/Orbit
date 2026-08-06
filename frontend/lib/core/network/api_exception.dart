import 'package:dio/dio.dart';

class ApiException implements Exception {
  ApiException(this.message);

  final String message;

  factory ApiException.fromDioException(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] is String) {
      return ApiException(data['message'] as String);
    }
    // FastAPI's own HTTPException (raised by JWTBearer for an invalid or
    // expired token, before any of our own handlers run) uses `detail`,
    // not the `message` key our custom error responses use.
    if (data is Map && data['detail'] is String) {
      return ApiException(data['detail'] as String);
    }

    switch (e.type) {
      case DioExceptionType.connectionError:
        return ApiException("Can't reach the server. Check your connection and try again.");
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return ApiException('The server is taking too long to respond. Please try again.');
      case DioExceptionType.badResponse:
        return ApiException('Something went wrong on the server. Please try again.');
      case DioExceptionType.cancel:
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return ApiException('Something went wrong. Please try again.');
    }
  }

  @override
  String toString() => message;
}
