import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/doctor_api.dart';
import '../data/doctor_model.dart';

final doctorApiProvider = Provider((ref) => DoctorApi());

/// Holds the current search text + specialization filter for the
/// doctor list screen. Updating this automatically re-triggers
/// doctorListProvider below (it's watched inside that FutureProvider).
class DoctorSearchState {
  final String search;
  final String? specialization;
  const DoctorSearchState({this.search = '', this.specialization});

  DoctorSearchState copyWith({String? search, String? specialization}) =>
      DoctorSearchState(
        search: search ?? this.search,
        specialization: specialization,
      );
}

class DoctorSearchNotifier extends StateNotifier<DoctorSearchState> {
  DoctorSearchNotifier() : super(const DoctorSearchState());

  void setSearch(String value) => state = state.copyWith(search: value);

  void setSpecialization(String? value) =>
      state = DoctorSearchState(search: state.search, specialization: value);
}

final doctorSearchProvider =
StateNotifierProvider<DoctorSearchNotifier, DoctorSearchState>(
      (ref) => DoctorSearchNotifier(),
);

/// Fetches the doctor list, automatically re-fetching whenever the
/// search text or specialization filter changes.
final doctorListProvider = FutureProvider.autoDispose<List<DoctorModel>>((ref) async {
  final filters = ref.watch(doctorSearchProvider);
  final api = ref.read(doctorApiProvider);
  return api.list(
    search: filters.search,
    specialization: filters.specialization,
  );
});

/// Fetches a single doctor's detail by id — used on the doctor detail screen.
final doctorDetailProvider =
FutureProvider.autoDispose.family<DoctorModel, String>((ref, doctorId) async {
  final api = ref.read(doctorApiProvider);
  return api.getById(doctorId);
});