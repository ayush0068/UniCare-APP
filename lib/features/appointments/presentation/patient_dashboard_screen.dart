import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../domain/appointment_providers.dart';
import 'widgets/appointment_card.dart';
import 'widgets/appointments_empty_state.dart';

/// Matches website's PatientDashboardContent.tsx: two tabs (Upcoming/Past),
/// with tab counts, read-only status view (patients don't cancel from
/// here on the website either — only Join Call and Pay Now are actionable).
class PatientDashboardScreen extends ConsumerStatefulWidget {
  const PatientDashboardScreen({super.key});

  @override
  ConsumerState<PatientDashboardScreen> createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends ConsumerState<PatientDashboardScreen> {
  AppointmentTab _activeTab = AppointmentTab.upcoming;

  @override
  Widget build(BuildContext context) {
    final upcomingAsync = ref.watch(patientAppointmentsProvider(AppointmentTab.upcoming));
    final pastAsync = ref.watch(patientAppointmentsProvider(AppointmentTab.past));
    final activeAsync = ref.watch(patientAppointmentsProvider(_activeTab));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('My Appointments')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: _TabButton(
                      icon: Icons.access_time_rounded,
                      label: 'Upcoming',
                      count: upcomingAsync.value?.length ?? 0,
                      isActive: _activeTab == AppointmentTab.upcoming,
                      onTap: () => setState(() => _activeTab = AppointmentTab.upcoming),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _TabButton(
                      icon: Icons.calendar_month_rounded,
                      label: 'Past',
                      count: pastAsync.value?.length ?? 0,
                      isActive: _activeTab == AppointmentTab.past,
                      onTap: () => setState(() => _activeTab = AppointmentTab.past),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: activeAsync.when(
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
                          onPressed: () => ref.invalidate(patientAppointmentsProvider(_activeTab)),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (appointments) {
                  if (appointments.isEmpty) {
                    return SingleChildScrollView(
                      child: AppointmentsEmptyState(
                        emoji: _activeTab == AppointmentTab.upcoming ? '📅' : '📋',
                        title: _activeTab == AppointmentTab.upcoming
                            ? 'No Upcoming Appointments'
                            : 'No Past Appointments',
                        description: _activeTab == AppointmentTab.upcoming
                            ? "You don't have any scheduled consultations."
                            : 'Your completed consultations will appear here.',
                        onBook: _activeTab == AppointmentTab.upcoming
                            ? () => context.push('/doctors')
                            : null,
                      ),
                    );
                  }
                  return RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () async => ref.invalidate(patientAppointmentsProvider(_activeTab)),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                      itemCount: appointments.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final appt = appointments[i];
                        return AppointmentCard(
                          appointment: appt,
                          isDoctorView: false,
                          onJoinCall: () => context.push('/consultation/${appt.id}'),
                          onPayNow: () => context.push('/payment/${appt.id}', extra: {
                            'amount': appt.totalAmount,
                          }),
                          onViewPrescription: () => context.push('/prescription/view/${appt.id}'),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final bool isActive;
  final VoidCallback onTap;

  const _TabButton({
    required this.icon,
    required this.label,
    required this.count,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isActive ? AppColors.primary : AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isActive ? Colors.white : AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: isActive ? Colors.white : AppColors.textSecondary,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isActive ? Colors.white24 : AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: isActive ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}