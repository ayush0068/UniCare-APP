/// Maps to backend/modal/Doctor.js fields returned by
/// GET /api/doctor/list and GET /api/doctor/:id
class DoctorModel {
  final String id;
  final String name;
  final String? profileImage;
  final String specialization;
  final String? qualification;
  final int? experience;
  final String? about;
  final num fees;
  final String? hospitalName;
  final String? hospitalCity;
  final String? hospitalAddress;
  final int slotDurationMinutes;

  DoctorModel({
    required this.id,
    required this.name,
    this.profileImage,
    required this.specialization,
    this.qualification,
    this.experience,
    this.about,
    required this.fees,
    this.hospitalName,
    this.hospitalCity,
    this.hospitalAddress,
    this.slotDurationMinutes = 30,
  });

  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    final hospitalInfo = json['hospitalInfo'] as Map<String, dynamic>?;
    return DoctorModel(
      id: json['_id'] as String,
      name: json['name'] as String? ?? 'Doctor',
      profileImage: json['profileImage'] as String?,
      specialization: json['specialization'] as String? ?? 'General',
      qualification: json['qualification'] as String?,
      experience: (json['experience'] as num?)?.toInt(),
      about: json['about'] as String?,
      fees: json['fees'] as num? ?? 0,
      hospitalName: hospitalInfo?['name'] as String?,
      hospitalCity: hospitalInfo?['city'] as String?,
      hospitalAddress: hospitalInfo?['address'] as String?,
      slotDurationMinutes: (json['slotDurationMinutes'] as num?)?.toInt() ?? 30,
    );
  }
}