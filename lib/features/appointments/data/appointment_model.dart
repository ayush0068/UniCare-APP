/// Maps to backend/modal/Appointment.js, as returned (populated) by
/// GET /api/appointment/patient and GET /api/appointment/doctor
import 'package:intl/intl.dart';

class AppointmentModel {
  final String id;
  final DateTime slotStart;
  final DateTime slotEnd;
  final String consultationType; // 'Video Consultation' | 'Voice Call'
  final String status; // 'Scheduled' | 'Completed' | 'Cancelled' | 'In Progress'
  final String symptoms;
  final String prescription;
  final num consultationFees;
  final num platformFees;
  final num totalAmount;
  final String paymentStatus; // 'Pending' | 'Paid' | 'refunded'

  final String otherPartyName;
  final String? otherPartyProfileImage;
  final String? doctorSpecialization;

  const AppointmentModel({
    required this.id,
    required this.slotStart,
    required this.slotEnd,
    required this.consultationType,
    required this.status,
    required this.symptoms,
    required this.prescription,
    required this.consultationFees,
    required this.platformFees,
    required this.totalAmount,
    required this.paymentStatus,
    required this.otherPartyName,
    this.otherPartyProfileImage,
    this.doctorSpecialization,
  });

  bool get isToday {
    final now = DateTime.now();
    return slotStart.year == now.year &&
        slotStart.month == now.month &&
        slotStart.day == now.day;
  }

  bool get canJoinCall {
    final diffMinutes = slotStart.difference(DateTime.now()).inMinutes;
    return isToday &&
        diffMinutes <= 15 &&
        diffMinutes >= -120 &&
        (status == 'Scheduled' || status == 'In Progress');
  }

  bool get canMarkCancelled =>
      status == 'Scheduled' && DateTime.now().isAfter(slotStart);

  // Robustly parses slotStartIso/slotEndIso. These are stored on the
  // backend as a plain String (not a real Date), and different clients
  // have historically sent different formats:
  //   - standard ISO 8601 (what the website sends, and what this app
  //     now sends too) — e.g. "2025-09-04T06:20:00.000Z"
  //   - an older JS `Date.toString()`-style string some legacy
  //     bookings may still have — e.g. "Wed Sep 04 2025 11:50:00 GMT+0530"
  // DateTime.parse() handles the first natively; we fall back to the
  // old custom format only if that fails, so existing appointments
  // booked before this fix keep working.
  static DateTime _parseSlotDate(String value) {
    try {
      return DateTime.parse(value).toLocal();
    } catch (_) {
      return DateFormat(
        "EEE MMM dd yyyy HH:mm:ss 'GMT'Z",
        'en_US',
      ).parse(value, true).toLocal();
    }
  }

  factory AppointmentModel.fromJson(
      Map<String, dynamic> json, {
        required bool viewedByDoctor,
      }) {
    final counterpart = viewedByDoctor
        ? json['patientId'] as Map<String, dynamic>?
        : json['doctorId'] as Map<String, dynamic>?;

    return AppointmentModel(
      id: json['_id'] as String,

      slotStart: _parseSlotDate(json['slotStartIso'] as String),
      slotEnd: _parseSlotDate(json['slotEndIso'] as String),

      consultationType:
      json['consultationType'] as String? ?? 'Video Consultation',
      status: json['status'] as String? ?? 'Scheduled',
      symptoms: json['symptoms'] as String? ?? '',
      prescription: json['prescription'] as String? ?? '',
      consultationFees: json['consultationFees'] as num? ?? 0,
      platformFees: json['platformFees'] as num? ?? 0,
      totalAmount: json['totalAmount'] as num? ?? 0,
      paymentStatus: json['paymentStatus'] as String? ?? 'Pending',

      otherPartyName: counterpart?['name'] as String? ??
          (viewedByDoctor ? 'Patient' : 'Doctor'),

      otherPartyProfileImage:
      counterpart?['profileImage'] as String?,

      doctorSpecialization: !viewedByDoctor
          ? (json['doctorId'] is Map
          ? json['doctorId']['specialization'] as String?
          : null)
          : null,
    );
  }
}