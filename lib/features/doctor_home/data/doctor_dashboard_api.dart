import '../../../core/network/dio_client.dart';

/// Maps to backend/routes/doctor.js -> GET /api/doctor/dashboard
class DoctorDashboardApi {
  final _dioClient = DioClient();

  Future<Map<String, dynamic>> getDashboard() async {
    final response = await _dioClient.safeRequest(
          () => _dioClient.dio.get('/doctor/dashboard'),
    );
    return response.data['data'] as Map<String, dynamic>;
  }
}