import 'dart:convert';
import 'dart:typed_data';
import '../../../core/network/dio_client.dart';

/// Maps to backend/routes/doctor.js -> PUT /api/doctor/onboarding/update
/// and the verification-document endpoints. Same endpoints the website's
/// DoctorOnboardingForm + ProfilePage's VerificationDocumentsPanel use.
class DoctorOnboardingApi {
  final _dioClient = DioClient();

  Future<Map<String, dynamic>> updateProfile({
    required String specialization,
    required List<String> categories,
    required String qualification,
    required String experience,
    required String about,
    required String fees,
    required Map<String, String> hospitalInfo, // {name, address, city}
    required DateTime availabilityStartDate,
    required DateTime availabilityEndDate,
    required List<int> excludedWeekdays,
    required List<Map<String, String>> dailyTimeRanges, // [{start, end}]
    required int slotDurationMinutes,
  }) async {
    final response = await _dioClient.safeRequest(
          () => _dioClient.dio.put('/doctor/onboarding/update', data: {
        'specialization': specialization,
        'category': categories,
        'qualification': qualification,
        'experience': experience,
        'about': about,
        'fees': fees,
        'hospitalInfo': hospitalInfo,
        'availabilityRange': {
          'startDate': availabilityStartDate.toIso8601String(),
          'endDate': availabilityEndDate.toIso8601String(),
          'excludedWeekdays': excludedWeekdays,
        },
        'dailyTimeRanges': dailyTimeRanges,
        'slotDurationMinutes': slotDurationMinutes,
      }),
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  /// GET /api/doctor/verification/documents
  /// Returns { documents: [{_id, type, uploadedAt, hasFile}], isVerified, isActive }
  /// Note: hasFile is a boolean flag only — the backend deliberately does
  /// NOT return the actual file bytes here (keeps the list call light).
  Future<Map<String, dynamic>> getVerificationDocuments() async {
    final response = await _dioClient.safeRequest(
          () => _dioClient.dio.get('/doctor/verification/documents'),
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  /// POST /api/doctor/verification/upload-document
  /// [fileBytes] gets base64-encoded into a data: URL client-side, exactly
  /// like the website's FileReader.readAsDataURL() does, since the backend
  /// expects fileData as a base64 data URL string (validated server-side
  /// with fileData.startsWith('data:')).
  Future<void> uploadVerificationDocument({
    required String documentType,
    required Uint8List fileBytes,
    required String fileName,
    required String mimeType, // e.g. 'image/jpeg', 'application/pdf'
  }) async {
    final base64Data = base64Encode(fileBytes);
    final dataUrl = 'data:$mimeType;base64,$base64Data';
    await _dioClient.safeRequest(
          () => _dioClient.dio.post('/doctor/verification/upload-document', data: {
        'documentType': documentType,
        'fileData': dataUrl,
        'fileName': fileName,
      }),
    );
  }

  /// DELETE /api/doctor/verification/document/:documentId
  Future<void> deleteVerificationDocument(String documentId) async {
    await _dioClient.safeRequest(
          () => _dioClient.dio.delete('/doctor/verification/document/$documentId'),
    );
  }
}