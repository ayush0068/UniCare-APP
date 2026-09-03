import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/appointment_model.dart';

const _statusColors = {
  'Scheduled': (bg: AppColors.tintBlue, dot: AppColors.accentBlue, text: AppColors.accentBlue),
  'In Progress': (bg: AppColors.tintTeal, dot: AppColors.primary, text: AppColors.primaryDark),
  'Completed': (bg: AppColors.tintTeal, dot: AppColors.success, text: AppColors.success),
  'Cancelled': (bg: AppColors.tintRed, dot: AppColors.danger, text: AppColors.danger),
};

class AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  final bool isDoctorView;
  final VoidCallback? onJoinCall;
  final VoidCallback? onMarkCancelled;
  final VoidCallback? onViewPrescription;
  final VoidCallback? onPayNow;

  const AppointmentCard({
    super.key,
    required this.appointment,
    required this.isDoctorView,
    this.onJoinCall,
    this.onMarkCancelled,
    this.onViewPrescription,
    this.onPayNow,
  });

  @override
  Widget build(BuildContext context) {
    final statusStyle = _statusColors[appointment.status] ??
        (bg: AppColors.surfaceMuted, dot: AppColors.textMuted, text: AppColors.textMuted);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primaryLight,
                backgroundImage: (appointment.otherPartyProfileImage?.isNotEmpty ?? false)
                    ? NetworkImage(appointment.otherPartyProfileImage!)
                    : null,
                child: (appointment.otherPartyProfileImage?.isNotEmpty ?? false)
                    ? null
                    : Text(
                  appointment.otherPartyName.isNotEmpty ? appointment.otherPartyName[0] : '?',
                  style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isDoctorView ? appointment.otherPartyName : 'Dr. ${appointment.otherPartyName}',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    if (!isDoctorView && appointment.doctorSpecialization != null)
                      Text(
                        appointment.doctorSpecialization!,
                        style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(color: statusStyle.bg, borderRadius: BorderRadius.circular(10)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6, height: 6,
                      decoration: BoxDecoration(color: statusStyle.dot, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      appointment.status,
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: statusStyle.text),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _InfoChip(icon: Icons.calendar_today_rounded, label: _formatDate(appointment.slotStart)),
              const SizedBox(width: 8),
              _InfoChip(icon: Icons.access_time_rounded, label: _formatTime(appointment.slotStart)),
              const SizedBox(width: 8),
              _InfoChip(
                icon: appointment.consultationType == 'Voice Call' ? Icons.call_rounded : Icons.videocam_rounded,
                label: appointment.consultationType == 'Voice Call' ? 'Voice' : 'Video',
              ),
            ],
          ),
          if (appointment.symptoms.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              appointment.symptoms,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
            ),
          ],
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (appointment.canJoinCall && onJoinCall != null)
                _ActionButton(
                  icon: Icons.videocam_rounded,
                  label: 'Join Call',
                  color: AppColors.primary,
                  onTap: onJoinCall!,
                ),
              if (!isDoctorView && appointment.paymentStatus == 'Pending' && onPayNow != null)
                _ActionButton(
                  icon: Icons.payments_outlined,
                  label: 'Pay Now',
                  color: AppColors.accentBlue,
                  onTap: onPayNow!,
                ),
              if (isDoctorView && appointment.canMarkCancelled && onMarkCancelled != null)
                _ActionButton(
                  icon: Icons.cancel_outlined,
                  label: 'Mark Cancelled',
                  color: AppColors.danger,
                  onTap: onMarkCancelled!,
                ),
              if (appointment.status == 'Completed' && appointment.prescription.isNotEmpty && onViewPrescription != null)
                _ActionButton(
                  icon: Icons.description_outlined,
                  label: 'View Report',
                  color: AppColors.textPrimary,
                  onTap: onViewPrescription!,
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${months[d.month - 1]}';
  }

  String _formatTime(DateTime t) {
    final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final period = t.hour < 12 ? 'AM' : 'PM';
    final minute = t.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      ),
    );
  }
}