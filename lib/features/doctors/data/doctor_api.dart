import '../../../core/network/dio_client.dart';
import 'doctor_model.dart';

/// Maps to backend/routes/doctor.js (public endpoints) and
/// the booked-slots endpoint in backend/routes/appointment.js
class DoctorApi {
  final _dioClient = DioClient();

  /// GET /api/doctor/list — all filters optional.
  Future<List<DoctorModel>> list({
    String? search,
    String? specialization,
    String? city,
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _dioClient.safeRequest(
          () => _dioClient.dio.get('/doctor/list', queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (specialization != null && specialization.isNotEmpty)
          'specialization': specialization,
        if (city != null && city.isNotEmpty) 'city': city,
        'sortBy': sortBy,
        'sortOrder': sortOrder,
        'page': page,
        'limit': limit,
      }),
    );
    final List data = response.data['data'] as List;
    return data.map((e) => DoctorModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// GET /api/doctor/:id
  Future<DoctorModel> getById(String doctorId) async {
    final response = await _dioClient.safeRequest(
          () => _dioClient.dio.get('/doctor/$doctorId'),
    );
    return DoctorModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// GET /api/appointment/booked-slots/:doctorId/:date
  /// date format: YYYY-MM-DD. Returns list of already-booked ISO start times.
  Future<List<String>> getBookedSlots(String doctorId, String date) async {
    final response = await _dioClient.safeRequest(
          () => _dioClient.dio.get('/appointment/booked-slots/$doctorId/$date'),
    );
    final List data = response.data['data'] as List;
    return data.map((e) => e.toString()).toList();
  }
}