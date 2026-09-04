import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/secure_storage.dart';
import '../../consultation/data/call_signaling_service.dart';
import '../data/auth_repository.dart';

final authRepositoryProvider = Provider((ref) => AuthRepository());

/// Current session's role ('patient' | 'doctor' | 'guest' | null).
/// Used wherever pricing or navigation needs to know if the signed-in
/// user is a guest (e.g. booking's guest surcharge) vs a full patient/doctor.
final currentRoleProvider = FutureProvider.autoDispose<String?>((ref) async {
  ref.watch(authStateProvider); // re-fetch whenever auth state changes
  return SecureStorage.getRole();
});

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final String? errorMessage;

  const AuthState({required this.status, this.errorMessage});

  const AuthState.initial() : this(status: AuthStatus.initial);

  AuthState copyWith({AuthStatus? status, String? errorMessage}) => AuthState(
    status: status ?? this.status,
    errorMessage: errorMessage,
  );
}

/// Drives login/register screens + the splash screen's "am I logged in?"
/// check. Wrap widgets with `ref.watch(authStateProvider)` to react to
/// login/logout across the whole app.
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AuthState.initial());

  Future<void> checkExistingSession() async {
    final loggedIn = await _repository.isLoggedIn();
    state = state.copyWith(
      status: loggedIn ? AuthStatus.authenticated : AuthStatus.unauthenticated,
    );
    if (loggedIn) {
      // Fire-and-forget: connects the call-signaling socket so incoming
      // calls can ring even before the user opens any consultation
      // screen. Safe to call repeatedly — it reuses an open connection.
      unawaited(CallSignalingService.instance.connect());
    }
  }

  Future<void> patientLogin(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _repository.patientLogin(email: email, password: password);
      state = state.copyWith(status: AuthStatus.authenticated);
      unawaited(CallSignalingService.instance.connect());
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> patientRegister({
    required String name,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _repository.patientRegister(
        name: name,
        email: email,
        password: password,
      );
      state = state.copyWith(status: AuthStatus.authenticated);
      unawaited(CallSignalingService.instance.connect());
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> guestLogin() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _repository.guestLogin();
      state = state.copyWith(status: AuthStatus.authenticated);
      unawaited(CallSignalingService.instance.connect());
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> doctorLogin(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _repository.doctorLogin(email: email, password: password);
      state = state.copyWith(status: AuthStatus.authenticated);
      unawaited(CallSignalingService.instance.connect());
    } catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> doctorRegister(String name, String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _repository.doctorRegister(name: name, email: email, password: password);
      state = state.copyWith(status: AuthStatus.authenticated);
      unawaited(CallSignalingService.instance.connect());
    } catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    CallSignalingService.instance.disconnect();
    state = state.copyWith(status: AuthStatus.unauthenticated);
  }
}

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>(
      (ref) => AuthNotifier(ref.read(authRepositoryProvider)),
);