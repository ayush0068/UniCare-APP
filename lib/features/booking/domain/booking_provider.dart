import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/appointment_api.dart';

final appointmentApiProvider = Provider((ref) => AppointmentApi());

enum BookingStatus { idle, submitting, success, error }

class BookingState {
  final BookingStatus status;
  final String? errorMessage;
  final Map<String, dynamic>? bookedAppointment;

  const BookingState({
    this.status = BookingStatus.idle,
    this.errorMessage,
    this.bookedAppointment,
  });

  BookingState copyWith({
    BookingStatus? status,
    String? errorMessage,
    Map<String, dynamic>? bookedAppointment,
  }) =>
      BookingState(
        status: status ?? this.status,
        errorMessage: errorMessage,
        bookedAppointment: bookedAppointment ?? this.bookedAppointment,
      );
}

/// Drives the booking confirmation screen. Kept separate per-booking-flow
/// (not global) — create a fresh instance each time BookingScreen opens.
class BookingNotifier extends StateNotifier<BookingState> {
  final AppointmentApi _api;
  BookingNotifier(this._api) : super(const BookingState());

  Future<void> submit({
    required String doctorId,
    required DateTime slotStart,
    required DateTime slotEnd,
    required String consultationType,
    required String symptoms,
    required num consultationFees,
    required num platformFees,
    required num totalAmount,
  }) async {
    state = state.copyWith(status: BookingStatus.submitting);
    try {
      final result = await _api.bookAppointment(
        doctorId: doctorId,
        slotStart: slotStart,
        slotEnd: slotEnd,
        consultationType: consultationType,
        symptoms: symptoms,
        consultationFees: consultationFees,
        platformFees: platformFees,
        totalAmount: totalAmount,
      );
      state = state.copyWith(status: BookingStatus.success, bookedAppointment: result);
    } catch (e) {
      state = state.copyWith(status: BookingStatus.error, errorMessage: e.toString());
    }
  }
}

final bookingProvider = StateNotifierProvider.autoDispose<BookingNotifier, BookingState>(
      (ref) => BookingNotifier(ref.read(appointmentApiProvider)),
);

/// Fetches already-booked slot start times for a doctor on a given date
/// (YYYY-MM-DD), so the slot picker can grey them out.
final bookedSlotsProvider =
FutureProvider.autoDispose.family<List<String>, ({String doctorId, String date})>(
      (ref, params) async {
    final api = ref.read(appointmentApiProvider);
    return api.getBookedSlots(params.doctorId, params.date);
  },
);