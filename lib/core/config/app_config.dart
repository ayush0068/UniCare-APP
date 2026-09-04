import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Central place for environment-derived config values.
/// Reads from the .env file loaded in main.dart.
class AppConfig {
  AppConfig._();

  /// e.g. http://10.0.2.2:8000/api
  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8000/api';

  /// Backend root without the /api suffix, used for the /health check
  /// and as the Socket.IO signaling endpoint for in-app calls.
  static String get serverRootUrl =>
      apiBaseUrl.replaceAll(RegExp(r'/api/?$'), '');

  /// Socket.IO signaling server URL for doctor/patient calling. Defaults
  /// to the same host as the REST API — override with SOCKET_URL in .env
  /// if signaling is served from a different host/port.
  static String get socketUrl => dotenv.env['SOCKET_URL'] ?? serverRootUrl;
}