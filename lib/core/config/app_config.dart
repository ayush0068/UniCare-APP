import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Central place for environment-derived config values.
/// Reads from the .env file loaded in main.dart.
class AppConfig {
  AppConfig._();

  /// e.g. http://10.0.2.2:8000/api
  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8000/api';

  /// Backend root without the /api suffix, used for the /health check.
  static String get serverRootUrl =>
      apiBaseUrl.replaceAll(RegExp(r'/api/?$'), '');

  /// ZegoCloud credentials for video/voice consultations — same
  /// NEXT_PUBLIC_ZEGOCLOUD_APP_ID / SERVER_SECRET pair the website uses
  /// (test-mode token generation, matching AppointmentCall.tsx exactly).
  static int get zegoAppId => int.tryParse(dotenv.env['ZEGOCLOUD_APP_ID'] ?? '') ?? 0;
  static String get zegoAppSign => dotenv.env['ZEGOCLOUD_APP_SIGN'] ?? '';
}