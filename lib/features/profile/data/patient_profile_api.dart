import '../../../core/network/dio_client.dart';

/// Maps to backend/routes/patient.js
class PatientProfileApi {
  final _dioClient = DioClient();

  /// GET /api/patient/me
  Future<Map<String, dynamic>> getProfile() async {
    final response = await _dioClient.safeRequest(
          () => _dioClient.dio.get('/patient/me'),
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  /// PUT /api/patient/onboarding/update
  /// All fields optional — only what's passed gets updated, matching the
  /// backend's validator (body(...).optional()) exactly.
  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? phone,
    DateTime? dob,
    String? gender, // 'male' | 'female' | 'other'
    String? bloodGroup, // 'A+' | 'A-' | 'B+' | 'B-' | 'AB+' | 'AB-' | 'O+' | 'O-'
    Map<String, String>? emergencyContact, // {name, phone, relationship}
    Map<String, String>? medicalHistory, // {allergies, currentMedications, chronicConditions}
  }) async {
    final data = <String, dynamic>{
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (dob != null) 'dob': dob.toIso8601String(),
      if (gender != null) 'gender': gender,
      if (bloodGroup != null) 'bloodGroup': bloodGroup,
      if (emergencyContact != null) 'emergencyContact': emergencyContact,
      if (medicalHistory != null) 'medicalHistory': medicalHistory,
    };
    final response = await _dioClient.safeRequest(
          () => _dioClient.dio.put('/patient/onboarding/update', data: data),
    );
    return response.data['data'] as Map<String, dynamic>;
  }
}