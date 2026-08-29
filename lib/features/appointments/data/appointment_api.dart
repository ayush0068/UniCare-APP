import '../../../core/network/dio_client.dart';
import 'appointment_model.dart';

/// Maps to backend/routes/appointment.js — the list + status-update
/// endpoints used by both the patient dashboard and doctor appointments
/// page. (Booking/slot-generation calls live separately in
/// features/booking/data/appointment_api.dart.)
class AppointmentListApi {
  final _dioClient = DioClient();

  /// GET /api/appointment/patient?status=Scheduled&status=In Progress
  Future<List<AppointmentModel>> getPatientAppointments({List<String>? statuses}) async {
    final response = await _dioClient.safeRequest(
          () => _dioClient.dio.get(
        '/appointment/patient',
        queryParameters: statuses != null ? {'status': statuses} : null,
      ),
    );
    final List data = response.data['data'] as List;
    return data
        .map((e) => AppointmentModel.fromJson(e as Map<String, dynamic>, viewedByDoctor: false))
        .toList();
  }

  /// GET /api/appointment/doctor?status=Scheduled&status=In Progress
  Future<List<AppointmentModel>> getDoctorAppointments({List<String>? statuses}) async {
    final response = await _dioClient.safeRequest(
          () => _dioClient.dio.get(
        '/appointment/doctor',
        queryParameters: statuses != null ? {'status': statuses} : null,
      ),
    );
    final List data = response.data['data'] as List;
    return data
        .map((e) => AppointmentModel.fromJson(e as Map<String, dynamic>, viewedByDoctor: true))
        .toList();
  }

  /// PUT /api/appointment/status/:id — doctor-only (mark Completed/Cancelled)
  Future<void> updateStatus(String appointmentId, String status) async {
    await _dioClient.safeRequest(
          () => _dioClient.dio.put('/appointment/status/$appointmentId', data: {'status': status}),
    );
  }
}