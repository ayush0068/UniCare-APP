import '../../../core/network/dio_client.dart';

/// Maps to backend/routes/appointment.js
class AppointmentApi {
  final _dioClient = DioClient();

  /// GET /api/appointment/booked-slots/:doctorId/:date  (date = YYYY-MM-DD)
  Future<List<String>> getBookedSlots(String doctorId, String date) async {
    final response = await _dioClient.safeRequest(
          () => _dioClient.dio.get('/appointment/booked-slots/$doctorId/$date'),
    );
    final List data = response.data['data'] as List;
    return data.map((e) => e.toString()).toList();
  }

  /// POST /api/appointment/book
  /// Backend computes final pricing itself (parchi discounts, guest
  /// surcharge) — we still send the doctor's listed fee as a base figure
  /// per the required request body, but the amount actually charged is
  /// whatever the backend returns in the response.
  Future<Map<String, dynamic>> bookAppointment({
    required String doctorId,
    required DateTime slotStart,
    required DateTime slotEnd,
    required String consultationType, // 'Video Consultation' | 'Voice Call'
    required String symptoms,
    required num consultationFees,
    required num platformFees,
    required num totalAmount,
  }) async {
    final response = await _dioClient.safeRequest(
          () => _dioClient.dio.post('/appointment/book', data: {
        'doctorId': doctorId,
        'date': slotStart.toIso8601String(),
        'slotStartIso': slotStart.toIso8601String(),
        'slotEndIso': slotEnd.toIso8601String(),
        'consultationType': consultationType,
        'symptoms': symptoms,
        'consultationFees': consultationFees,
        'platformFees': platformFees,
        'totalAmount': totalAmount,
      }),
    );
    return response.data['data'] as Map<String, dynamic>;
  }
}