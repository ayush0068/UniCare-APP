import '../../../core/network/dio_client.dart';

/// Maps to backend/routes/appointment.js
class PrescriptionApi {
  final _dioClient = DioClient();

  /// GET /api/appointment/:id
  /// Full populated appointment — patient (name,email,phone,dob,age,
  /// profileImage) + doctor (name,fees,phone,specialization,hospitalInfo,
  /// profileImage). Used to render the complete Rx document.
  Future<Map<String, dynamic>> getAppointmentDetail(String appointmentId) async {
    final response = await _dioClient.safeRequest(
          () => _dioClient.dio.get('/appointment/$appointmentId'),
    );
    return (response.data['data'] as Map<String, dynamic>)['appointment'] as Map<String, dynamic>;
  }

  /// PUT /api/appointment/end/:id — same endpoint used to end a
  /// consultation; saving a prescription here also marks the appointment
  /// Completed, matching the website's handleSavePrescription() exactly.
  Future<void> savePrescription(String appointmentId, {required String prescription, required String notes}) async {
    await _dioClient.safeRequest(
          () => _dioClient.dio.put('/appointment/end/$appointmentId', data: {
        'prescription': prescription,
        'notes': notes,
      }),
    );
  }
}