import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../storage/secure_storage.dart';
import 'api_exception.dart';

/// Single Dio instance used by every feature's *_api.dart file.
/// - Automatically attaches the JWT (Authorization: Bearer <token>) that
///   your Express `authenticate` middleware expects.
/// - Normalizes errors into ApiException so UI code doesn't need to know
///   about Dio internals.
class DioClient {
  static final DioClient _instance = DioClient._internal();
  factory DioClient() => _instance;

  late final Dio dio;

  DioClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await SecureStorage.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          return handler.next(e);
        },
      ),
    );
  }

  /// Wraps a Dio call and rethrows a clean ApiException, pulling the
  /// backend's own `message` field (set by your `response` middleware)
  /// when available.
  Future<Response> safeRequest(Future<Response> Function() request) async {
    try {
      return await request();
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = (data is Map && data['message'] != null)
          ? data['message'].toString()
          : (e.message ?? 'Something went wrong. Please try again.');
      throw ApiException(message, statusCode: e.response?.statusCode);
    }
  }
}
