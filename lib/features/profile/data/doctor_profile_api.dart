import '../../../core/network/dio_client.dart';

/// Maps to backend/routes/doctor.js -> GET /api/doctor/me
class DoctorProfileApi {
  final _dioClient = DioClient();

  Future<Map<String, dynamic>> getProfile() async {
    final response = await _dioClient.safeRequest(
          () => _dioClient.dio.get('/doctor/me'),
    );
    return response.data['data'] as Map<String, dynamic>;
  }
}