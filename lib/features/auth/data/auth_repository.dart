import '../../../core/storage/secure_storage.dart';
import 'auth_api.dart';

/// Sits between the raw API and the UI/state layer:
/// calls AuthApi, then persists the returned token + role into
/// SecureStorage so the user stays logged in across app restarts.
class AuthRepository {
  final _authApi = AuthApi();

  Future<void> patientLogin({
    required String email,
    required String password,
  }) async {
    final data = await _authApi.patientLogin(email: email, password: password);
    await _persist(data);
  }

  Future<void> patientRegister({
    required String name,
    required String email,
    required String password,
  }) async {
    final data = await _authApi.patientRegister(
      name: name,
      email: email,
      password: password,
    );
    await _persist(data);
  }

  Future<void> doctorLogin({
    required String email,
    required String password,
  }) async {
    final data = await _authApi.doctorLogin(email: email, password: password);
    await _persist(data);
  }

  Future<void> doctorRegister({
    required String name,
    required String email,
    required String password,
  }) async {
    final data = await _authApi.doctorRegister(name: name, email: email, password: password);
    await _persist(data);
  }

  Future<void> guestLogin() async {
    final data = await _authApi.guestLogin();
    await _persist(data);
  }

  Future<void> logout() => SecureStorage.clearSession();

  Future<bool> isLoggedIn() => SecureStorage.isLoggedIn();

  Future<void> _persist(Map<String, dynamic> data) async {
    final token = data['token'] as String;
    final user = data['user'] as Map<String, dynamic>;
    await SecureStorage.saveSession(
      token: token,
      role: user['type'] as String,
      userId: user['id'] as String,
    );
  }
}