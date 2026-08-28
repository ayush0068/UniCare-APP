import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/domain/auth_provider.dart';
import '../data/mock_home_data.dart';
import 'widgets/doctor_card.dart';
import 'widgets/quick_action_card.dart';
import 'widgets/section_header.dart';
import 'widgets/specialty_chip.dart';

/// The app's default landing screen. Opens directly on app start —
/// no forced login. Guests see a "Login to book" prompt; logged-in
/// users see their name. Every action that actually needs an account
/// (booking, video call, prescriptions) should route through
/// `_requireLogin()` below before navigating further.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _requireLogin(BuildContext context, WidgetRef ref, VoidCallback onAuthed) {
    final isLoggedIn = ref.read(authStateProvider).status == AuthStatus.authenticated;
    if (isLoggedIn) {
      onAuthed();
    } else {
      context.push('/login');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final isLoggedIn = authState.status == AuthStatus.authenticated;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            // TODO: refresh doctor list / notifications once wired to backend
            await Future.delayed(const Duration(milliseconds: 600));
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              _TopBar(isLoggedIn: isLoggedIn, ref: ref),
              const SizedBox(height: 20),
              _SearchBar(
                onTap: () => _requireLogin(context, ref, () => context.push('/doctors')),
              ),
              const SizedBox(height: 20),
              if (!isLoggedIn) ...[
                _GuestBanner(onLoginTap: () => context.push('/login')),
                const SizedBox(height: 20),
              ],
              _HeroBanner(
                onBookTap: () => _requireLogin(context, ref, () => context.push('/doctors')),
              ),
              const SizedBox(height: 24),
              Text('Quick actions', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              _QuickActionsGrid(
                onAction: (route) => _requireLogin(context, ref, () => context.push(route)),
              ),
              const SizedBox(height: 26),
              SectionHeader(
                title: 'Browse by specialty',
                onSeeAll: () => _requireLogin(context, ref, () => context.push('/doctors')),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 92,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: mockSpecialties.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, i) {
                    final s = mockSpecialties[i];
                    return SpecialtyChip(
                      emoji: s.emoji,
                      label: s.label,
                      onTap: () => _requireLogin(context, ref, () => context.push('/doctors')),
                    );
                  },
                ),
              ),
              const SizedBox(height: 26),
              SectionHeader(
                title: 'Top doctors',
                onSeeAll: () => _requireLogin(context, ref, () => context.push('/doctors')),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 168,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: mockDoctors.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, i) {
                    final doc = mockDoctors[i];
                    return DoctorCard(
                      doctor: doc,
                      onTap: () => _requireLogin(context, ref, () => context.push('/doctors')),
                    );
                  },
                ),
              ),
              const SizedBox(height: 26),
              _EmergencyCard(
                onTap: () => _requireLogin(context, ref, () => context.push('/consultation')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final bool isLoggedIn;
  final WidgetRef ref;
  const _TopBar({required this.isLoggedIn, required this.ref});

  void _showAccountSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.person_outline_rounded, color: AppColors.textPrimary),
                title: const Text('My Profile'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.push('/profile');
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_month_rounded, color: AppColors.textPrimary),
                title: const Text('My Appointments'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.push('/appointments');
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout_rounded, color: AppColors.danger),
                title: const Text('Log Out', style: TextStyle(color: AppColors.danger)),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await ref.read(authStateProvider.notifier).logout();
                  if (context.mounted) context.go('/role-selection');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isLoggedIn ? 'Hi there 👋' : 'Welcome to',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 2),
              Text(
                isLoggedIn ? 'How are you feeling today?' : 'UniCare+',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ),
        ),
        _IconBadge(
          icon: Icons.notifications_none_rounded,
          onTap: () {
            if (isLoggedIn) {
              context.push('/notifications');
            } else {
              context.push('/login');
            }
          },
        ),
        const SizedBox(width: 10),
        _IconBadge(
          icon: isLoggedIn ? Icons.person_outline_rounded : Icons.login_rounded,
          onTap: () {
            if (isLoggedIn) {
              _showAccountSheet(context, ref);
            } else {
              context.push('/login');
            }
          },
        ),
      ],
    );
  }
}

class _IconBadge extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBadge({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 20, color: AppColors.textPrimary),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final VoidCallback onTap;
  const _SearchBar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(Icons.search_rounded, color: AppColors.textMuted),
            const SizedBox(width: 10),
            Text(
              'Search doctors, symptoms...',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuestBanner extends StatelessWidget {
  final VoidCallback onLoginTap;
  const _GuestBanner({required this.onLoginTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.primaryDark),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Log in to book appointments, chat with the AI assistant, and view prescriptions.',
              style: TextStyle(fontSize: 12.5, color: AppColors.primaryDark, height: 1.3),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onLoginTap,
            style: TextButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Login', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  final VoidCallback onBookTap;
  const _HeroBanner({required this.onBookTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Consult a doctor\nfrom home',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: onBookTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primaryDark,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Book Now', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          const Icon(Icons.health_and_safety_rounded, color: Colors.white24, size: 72),
        ],
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  final void Function(String route) onAction;
  const _QuickActionsGrid({required this.onAction});

  @override
  Widget build(BuildContext context) {
    final actions = [
      (Icons.medical_services_rounded, 'Find Doctor', AppColors.tintTeal, '/doctors'),
      (Icons.videocam_rounded, 'Video Consult', AppColors.tintBlue, '/consultation'),
      (Icons.smart_toy_rounded, 'AI Assistant', AppColors.tintPurple, '/ai-assistant'),
      (Icons.description_rounded, 'Prescriptions', AppColors.tintOrange, '/prescriptions'),
      (Icons.calendar_month_rounded, 'Appointments', AppColors.tintPink, '/appointments'),
      (Icons.favorite_rounded, 'Aftercare', AppColors.tintRed, '/aftercare'),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.92,
      ),
      itemBuilder: (context, i) {
        final a = actions[i];
        return QuickActionCard(
          icon: a.$1,
          label: a.$2,
          tint: a.$3,
          onTap: () => onAction(a.$4),
        );
      },
    );
  }
}

class _EmergencyCard extends StatelessWidget {
  final VoidCallback onTap;
  const _EmergencyCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.tintRed,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.emergency_rounded, color: AppColors.danger),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Need urgent help? Start an instant consultation.',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
          ),
          IconButton(
            onPressed: onTap,
            icon: const Icon(Icons.arrow_forward_rounded, color: AppColors.danger),
          ),
        ],
      ),
    );
  }
}