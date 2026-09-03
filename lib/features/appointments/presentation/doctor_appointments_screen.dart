import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../data/appointment_api.dart';
import '../domain/appointment_providers.dart';
import 'widgets/appointment_card.dart';
import 'widgets/appointments_empty_state.dart';

class DoctorAppointmentsScreen extends ConsumerStatefulWidget {
  const DoctorAppointmentsScreen({super.key});

  @override
  ConsumerState<DoctorAppointmentsScreen> createState() => _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState extends ConsumerState<DoctorAppointmentsScreen> {
  AppointmentTab _activeTab = AppointmentTab.upcoming;
  final _api = AppointmentListApi();
  bool _updating = false;

  Future<void> _updateStatus(String appointmentId, String status) async {
    setState(() => _updating = true);
    try {
      await _api.updateStatus(appointmentId, status);
      ref.invalidate(doctorAppointmentsProvider(AppointmentTab.upcoming));
      ref.invalidate(doctorAppointmentsProvider(AppointmentTab.past));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  void _confirmCancel(BuildContext context, String appointmentId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel Appointment?'),
        content: const Text('This will mark the appointment as cancelled. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Go Back')),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _updateStatus(appointmentId, 'Cancelled');
            },
            child: const Text('Yes, Cancel', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }

  void _showPrescription(BuildContext context, String appointmentId) {
    context.push('/prescription/view/$appointmentId');
  }

  @override
  Widget build(BuildContext context) {
    final upcomingAsync = ref.watch(doctorAppointmentsProvider(AppointmentTab.upcoming));
    final pastAsync = ref.watch(doctorAppointmentsProvider(AppointmentTab.past));
    final activeAsync = ref.watch(doctorAppointmentsProvider(_activeTab));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Appointments')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: _TabButton(
                      label: 'Upcoming',
                      count: upcomingAsync.value?.length ?? 0,
                      isActive: _activeTab == AppointmentTab.upcoming,
                      onTap: () => setState(() => _activeTab = AppointmentTab.upcoming),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _TabButton(
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
                          onPressed: () => ref.invalidate(doctorAppointmentsProvider(_activeTab)),
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
                      ),
                    );
                  }
                  return RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () async => ref.invalidate(doctorAppointmentsProvider(_activeTab)),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                      itemCount: appointments.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final appt = appointments[i];
                        return AppointmentCard(
                          appointment: appt,
                          isDoctorView: true,
                          onJoinCall: _updating ? null : () => context.push('/consultation/${appt.id}'),
                          onMarkCancelled: _updating ? null : () => _confirmCancel(context, appt.id),
                          onViewPrescription: () => _showPrescription(context, appt.id),
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
  final String label;
  final int count;
  final bool isActive;
  final VoidCallback onTap;

  const _TabButton({required this.label, required this.count, required this.isActive, required this.onTap});

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