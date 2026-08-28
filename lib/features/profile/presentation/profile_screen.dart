import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../auth/domain/auth_provider.dart';
import 'doctor_profile_screen.dart';
import 'patient_profile_screen.dart';

/// Single /profile route that shows the right screen for whoever is
/// signed in — avoids the home screen needing to know or care which
/// role it's linking to.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleAsync = ref.watch(currentRoleProvider);

    return roleAsync.when(
      loading: () => const Scaffold(body: LoadingIndicator()),
      error: (e, _) => Scaffold(body: Center(child: Text('Could not load profile: $e'))),
      data: (role) {
        if (role == 'doctor') return DoctorProfileScreen();
        return PatientProfileScreen();
      },
    );
  }
}