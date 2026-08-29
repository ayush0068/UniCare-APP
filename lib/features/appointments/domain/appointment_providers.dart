import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/appointment_api.dart';
import '../data/appointment_model.dart';

final appointmentListApiProvider = Provider((ref) => AppointmentListApi());

/// Matches the website's tab->status-filter mapping exactly:
///   upcoming -> Scheduled, In Progress
///   past     -> Completed, Cancelled
enum AppointmentTab { upcoming, past }

List<String> _statusesFor(AppointmentTab tab) =>
    tab == AppointmentTab.upcoming ? ['Scheduled', 'In Progress'] : ['Completed', 'Cancelled'];

final patientAppointmentsProvider =
FutureProvider.autoDispose.family<List<AppointmentModel>, AppointmentTab>((ref, tab) async {
  final api = ref.read(appointmentListApiProvider);
  return api.getPatientAppointments(statuses: _statusesFor(tab));
});

final doctorAppointmentsProvider =
FutureProvider.autoDispose.family<List<AppointmentModel>, AppointmentTab>((ref, tab) async {
  final api = ref.read(appointmentListApiProvider);
  return api.getDoctorAppointments(statuses: _statusesFor(tab));
});