import '../../../core/network/dio_client.dart';

/// Maps 1:1 to backend/routes/auth.js
/// POST /api/auth/patient/register
/// POST /api/auth/patient/login
/// POST /api/auth/doctor/register
/// POST /api/auth/doctor/login
/// POST /api/auth/guest/login
class AuthApi {
  final _dioClient = DioClient();

  Future<Map<String, dynamic>> patientLogin({
    required String email,
    required String password,
  }) async {
    final response = await _dioClient.safeRequest(
          () => _dioClient.dio.post('/auth/patient/login', data: {
        'email': email,
        'password': password,
      }),
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> patientRegister({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _dioClient.safeRequest(
          () => _dioClient.dio.post('/auth/patient/register', data: {
        'name': name,
        'email': email,
        'password': password,
      }),
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> doctorLogin({
    required String email,
    required String password,
  }) async {
    final response = await _dioClient.safeRequest(
          () => _dioClient.dio.post('/auth/doctor/login', data: {
        'email': email,
        'password': password,
      }),
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  /// POST /api/auth/doctor/register
  /// Only name/email/password are required at this stage — matches the
  /// website's flow where the doctor completes specialization, fees,
  /// hospital info, and availability afterwards via the onboarding form
  /// (PUT /api/doctor/onboarding/update). The account stays isVerified:
  /// false until an admin approves it, so /api/auth/doctor/login will be
  /// blocked until then — but this register call itself already returns
  /// a usable token, which is what lets a brand-new doctor go straight
  /// into the onboarding form without logging in separately.
  Future<Map<String, dynamic>> doctorRegister({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _dioClient.safeRequest(
          () => _dioClient.dio.post('/auth/doctor/register', data: {
        'name': name,
        'email': email,
        'password': password,
      }),
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> guestLogin() async {
    final response = await _dioClient.safeRequest(
          () => _dioClient.dio.post('/auth/guest/login'),
    );
    return response.data['data'] as Map<String, dynamic>;
  }
}

/*
  CONFIRMED RESPONSE SHAPE (from backend/middleware/response.js +
  backend/routes/auth.js):
    { success: true, message: "...", data: { token, user: { id, type } } }
  `data['token']` and `data['user']['id']` / `['type']` are what
  auth_repository.dart reads below.
*/