import '../../../core/network/dio_client.dart';

/// Maps to backend/routes/patient.js -> PUT /api/patient/onboarding/update
/// Same endpoint the website's PatientOnboardingForm submits to.
class PatientOnboardingApi {
  final _dioClient = DioClient();

  Future<Map<String, dynamic>> updateProfile({
    required String phone,
    required DateTime dob,
    required String gender, // 'male' | 'female' | 'other'
    String? bloodGroup,
    required Map<String, String> emergencyContact, // {name, phone, relationship}
    required Map<String, String> medicalHistory, // {allergies, currentMedications, chronicConditions}
  }) async {
    final response = await _dioClient.safeRequest(
          () => _dioClient.dio.put('/patient/onboarding/update', data: {
        'phone': phone,
        'dob': dob.toIso8601String(),
        'gender': gender,
        if (bloodGroup != null && bloodGroup.isNotEmpty) 'bloodGroup': bloodGroup,
        'emergencyContact': emergencyContact,
        'medicalHistory': medicalHistory,
      }),
    );
    return response.data['data'] as Map<String, dynamic>;
  }
}