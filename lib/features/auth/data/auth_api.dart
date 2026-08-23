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
    required String phone,
  }) async {
    final response = await _dioClient.safeRequest(
      () => _dioClient.dio.post('/auth/patient/register', data: {
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
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
