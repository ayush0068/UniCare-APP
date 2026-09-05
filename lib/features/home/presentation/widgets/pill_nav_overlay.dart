import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/domain/auth_provider.dart';
import 'pill_nav_bar.dart';

const _pillNavItems = [
  PillNavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
  PillNavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile'),
  PillNavItem(icon: Icons.calendar_month_outlined, activeIcon: Icons.calendar_month_rounded, label: 'Appointments'),
  PillNavItem(icon: Icons.help_outline_rounded, activeIcon: Icons.help_rounded, label: 'Help'),
];

/// Wraps any full screen (its whole Scaffold) with the floating glass
/// pill nav bar pinned to the bottom, so Home / Profile / Appointments /
/// Help Center all share one consistent, always-visible bottom nav —
/// wherever the person is in the app, this shows up with the right tab
/// highlighted.
///
/// Usage: return PillNavOverlay(currentIndex: 1, child: Scaffold(...));
///
/// Navigation is role-aware: Home routes to the patient or doctor
/// dashboard, and Appointments routes to the patient or doctor
/// appointments screen, depending on who's signed in. Uses context.go
/// (not push) so switching tabs doesn't stack up back-history — it
/// behaves like a real tab bar rather than repeatedly pushing new pages.
class PillNavOverlay extends ConsumerWidget {
  final int currentIndex;
  final Widget child;

  const PillNavOverlay({super.key, required this.currentIndex, required this.child});

  Future<void> _onTap(BuildContext context, WidgetRef ref, int index) async {
    if (index == currentIndex) return;

    final isLoggedIn = ref.read(authStateProvider).status == AuthStatus.authenticated;

    // Help Center (3) is open to everyone. Home (0) always has a guest
    // experience. Profile (1) and Appointments (2) need an account.
    if ((index == 1 || index == 2) && !isLoggedIn) {
      context.push('/login');
      return;
    }

    String? role;
    if (isLoggedIn) {
      role = await ref.read(currentRoleProvider.future);
    }
    final isDoctor = role == 'doctor';

    switch (index) {
      case 0:
        context.go(isDoctor ? '/doctor/home' : '/home');
        break;
      case 1:
        context.go('/profile');
        break;
      case 2:
        context.go(isDoctor ? '/doctor/appointments' : '/appointments');
        break;
      case 3:
        context.go('/help-center');
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        child,
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SafeArea(
            top: false,
            minimum: const EdgeInsets.only(bottom: 12),
            child: PillNavBar(
              currentIndex: currentIndex,
              items: _pillNavItems,
              onTap: (index) => _onTap(context, ref, index),
            ),
          ),
        ),
      ],
    );
  }
}