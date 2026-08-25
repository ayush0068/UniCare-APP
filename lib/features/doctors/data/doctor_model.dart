/// A single working-hours window for a day, e.g. {start: "09:00", end: "13:00"}
class TimeRange {
  final String start; // "HH:mm"
  final String end;   // "HH:mm"
  TimeRange({required this.start, required this.end});

  factory TimeRange.fromJson(Map<String, dynamic> json) => TimeRange(
    start: json['start'] as String? ?? '09:00',
    end: json['end'] as String? ?? '17:00',
  );
}

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
  final List<TimeRange> dailyTimeRanges;
  final DateTime? availabilityStartDate;
  final DateTime? availabilityEndDate;
  /// JS-style weekday numbers: 0 = Sunday ... 6 = Saturday (matches how
  /// the Next.js/Express backend stores them). Use isWeekdayExcluded()
  /// below to check a Dart DateTime against this safely.
  final List<int> excludedWeekdays;

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
    this.dailyTimeRanges = const [],
    this.availabilityStartDate,
    this.availabilityEndDate,
    this.excludedWeekdays = const [],
  });

  /// Dart's DateTime.weekday is 1=Monday..7=Sunday. Backend stores JS-style
  /// 0=Sunday..6=Saturday. This converts and checks in one place so no
  /// screen has to remember the conversion formula.
  bool isWeekdayExcluded(DateTime date) {
    final jsWeekday = date.weekday % 7; // Dart 7 (Sun) -> 0, Dart 1..6 unchanged
    return excludedWeekdays.contains(jsWeekday);
  }

  bool isDateInAvailabilityRange(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    if (availabilityStartDate != null && day.isBefore(availabilityStartDate!)) return false;
    if (availabilityEndDate != null && day.isAfter(availabilityEndDate!)) return false;
    return true;
  }

  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    final hospitalInfo = json['hospitalInfo'] as Map<String, dynamic>?;
    final rangesJson = json['dailyTimeRanges'] as List?;
    final availabilityRange = json['availabilityRange'] as Map<String, dynamic>?;
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
      dailyTimeRanges: rangesJson
          ?.map((e) => TimeRange.fromJson(e as Map<String, dynamic>))
          .toList() ??
          const [],
      availabilityStartDate: _tryParseDate(availabilityRange?['startDate']),
      availabilityEndDate: _tryParseDate(availabilityRange?['endDate']),
      excludedWeekdays: (availabilityRange?['excludedWeekdays'] as List?)
          ?.map((e) => (e as num).toInt())
          .toList() ??
          const [],
    );
  }

  static DateTime? _tryParseDate(dynamic value) {
    if (value == null || value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }
}