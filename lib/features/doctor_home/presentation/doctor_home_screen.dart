import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../appointments/data/appointment_model.dart';
import '../../appointments/presentation/widgets/appointment_card.dart';
import '../../auth/domain/auth_provider.dart';
import '../../home/presentation/widgets/pill_nav_overlay.dart';
import '../data/doctor_dashboard_api.dart';

final _doctorDashboardProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return DoctorDashboardApi().getDashboard();
});

/// Landing screen for verified, logged-in doctors — matches website's
/// DoctorDashboardContent.tsx: verification banner, stat cards (patients,
/// today's appointments, revenue, completed), and today's schedule.
/// The full appointment history (Upcoming/Past tabs, actions) lives on
/// the separate Appointments page, same split as the website.
class DoctorHomeScreen extends ConsumerWidget {
  const DoctorHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(_doctorDashboardProvider);

    return PillNavOverlay(
      currentIndex: 0,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Dashboard'),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.calendar_month_rounded),
              tooltip: 'Appointments',
              onPressed: () => context.push('/doctor/appointments'),
            ),
            IconButton(
              icon: const Icon(Icons.person_outline_rounded),
              onPressed: () => context.push('/profile'),
            ),
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              onPressed: () async {
                await ref.read(authStateProvider.notifier).logout();
                if (context.mounted) context.go('/');
              },
            ),
          ],
        ),
        body: dashboardAsync.when(
          loading: () => const LoadingIndicator(),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(e.toString(), textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => ref.invalidate(_doctorDashboardProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          data: (data) {
            final doctor = data['doctor'] as Map<String, dynamic>?;
            final stats = data['stats'] as Map<String, dynamic>?;
            final isVerified = doctor?['isVerified'] == true;
            final todayAppointments = (data['todayAppointments'] as List? ?? [])
                .map((e) => AppointmentModel.fromJson(e as Map<String, dynamic>, viewedByDoctor: true))
                .toList();

            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async => ref.invalidate(_doctorDashboardProvider),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
                children: [
                  if (!isVerified) ...[
                    _VerificationBanner(),
                    const SizedBox(height: 16),
                  ],
                  _DoctorHeader(doctor: doctor, rating: stats?['averageRating']),
                  const SizedBox(height: 20),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      _StatCard(
                        icon: Icons.people_alt_rounded,
                        label: 'Total Patients',
                        value: '${stats?['totalPatients'] ?? 0}',
                        tint: AppColors.tintBlue,
                      ),
                      _StatCard(
                        icon: Icons.calendar_today_rounded,
                        label: "Today's Appointments",
                        value: '${stats?['todayAppointments'] ?? 0}',
                        tint: AppColors.tintTeal,
                      ),
                      _StatCard(
                        icon: Icons.currency_rupee_rounded,
                        label: 'Total Revenue',
                        value: '₹${stats?['totalRevenue'] ?? 0}',
                        tint: AppColors.tintPurple,
                      ),
                      _StatCard(
                        icon: Icons.check_circle_outline_rounded,
                        label: 'Completed',
                        value: '${stats?['completedAppointments'] ?? 0}',
                        tint: AppColors.tintOrange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Today's Schedule", style: Theme.of(context).textTheme.titleLarge),
                      TextButton(
                        onPressed: () => context.push('/doctor/appointments'),
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (todayAppointments.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.event_available_rounded, size: 32, color: AppColors.textMuted),
                          SizedBox(height: 10),
                          Text('No appointments scheduled for today', style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                        ],
                      ),
                    )
                  else
                    ...todayAppointments.map((appt) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AppointmentCard(
                        appointment: appt,
                        isDoctorView: true,
                        onJoinCall: () => context.push('/consultation/${appt.id}'),
                      ),
                    )),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _VerificationBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.tintOrange, borderRadius: BorderRadius.circular(14)),
      child: const Row(
        children: [
          Icon(Icons.hourglass_top_rounded, color: Color(0xFFF59E0B), size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Your account is pending admin verification. Some features may be limited until approved.',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _DoctorHeader extends StatelessWidget {
  final Map<String, dynamic>? doctor;
  final dynamic rating;
  const _DoctorHeader({required this.doctor, required this.rating});

  @override
  Widget build(BuildContext context) {
    final name = doctor?['name'] as String? ?? 'Doctor';
    final specialization = doctor?['specialization'] as String?;
    final city = (doctor?['hospitalInfo'] as Map?)?['city'] as String?;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white24,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'D',
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                if (specialization != null)
                  Text(specialization, style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
                if (city != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 12, color: Colors.white60),
                      const SizedBox(width: 3),
                      Text(city, style: const TextStyle(color: Colors.white60, fontSize: 11)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (rating != null)
            Row(
              children: [
                const Icon(Icons.star_rounded, size: 16, color: Color(0xFFFBBF24)),
                const SizedBox(width: 3),
                Text('$rating', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
              ],
            ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color tint;
  const _StatCard({required this.icon, required this.label, required this.value, required this.tint});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
            child: Icon(icon, size: 16, color: AppColors.textPrimary),
          ),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}