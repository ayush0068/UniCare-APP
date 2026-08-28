import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wraps flutter_secure_storage for storing the JWT + basic session info.
/// This is the Flutter equivalent of how the Next.js frontend keeps the
/// token in a cookie/localStorage.
class SecureStorage {
  SecureStorage._();

  static const _storage = FlutterSecureStorage();

  static const _tokenKey = 'jwt_token';
  static const _roleKey = 'user_role'; // 'patient' | 'doctor' | 'guest'
  static const _userIdKey = 'user_id';

  static Future<void> saveSession({
    required String token,
    required String role,
    required String userId,
  }) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _roleKey, value: role);
    await _storage.write(key: _userIdKey, value: userId);
  }

  static Future<String?> getToken() => _storage.read(key: _tokenKey);
  static Future<String?> getRole() => _storage.read(key: _roleKey);
  static Future<String?> getUserId() => _storage.read(key: _userIdKey);

  static Future<bool> isLoggedIn() async =>
      (await getToken()) != null;

  static Future<void> clearSession() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _roleKey);
    await _storage.delete(key: _userIdKey);
  }

  // --- First-launch consent (Terms, Privacy, permissions notice) ---
  // Intentionally NOT cleared by clearSession()/logout — this is a
  // one-time-per-install acknowledgment, not part of the user's session.
  static const _acceptedTermsKey = 'accepted_terms_v1';

  static Future<bool> hasAcceptedTerms() async =>
      (await _storage.read(key: _acceptedTermsKey)) == 'true';

  static Future<void> setAcceptedTerms() =>
      _storage.write(key: _acceptedTermsKey, value: 'true');
}