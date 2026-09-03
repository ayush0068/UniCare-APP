import '../../../core/network/dio_client.dart';

/// Maps to backend/routes/appointment.js
class ConsultationApi {
  final _dioClient = DioClient();

  /// GET /api/appointment/join/:id
  /// Marks the appointment "In Progress" and returns the ZegoCloud
  /// room ID + the full populated appointment (patient/doctor names).
  Future<Map<String, dynamic>> joinConsultation(String appointmentId) async {
    final response = await _dioClient.safeRequest(
          () => _dioClient.dio.get('/appointment/join/$appointmentId'),
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  /// PUT /api/appointment/end/:id
  /// Marks the appointment "Completed". prescription/notes optional —
  /// leaving them blank still ends/completes the appointment; a doctor
  /// can fill prescription details in from the Appointments page later.
  Future<void> endConsultation(String appointmentId, {String? prescription, String? notes}) async {
    await _dioClient.safeRequest(
          () => _dioClient.dio.put('/appointment/end/$appointmentId', data: {
        if (prescription != null) 'prescription': prescription,
        if (notes != null) 'notes': notes,
      }),
    );
  }
}