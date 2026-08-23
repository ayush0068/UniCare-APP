/// Normalized exception thrown by DioClient so every screen can handle
/// errors the same way, regardless of what Dio/the backend throws.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}
