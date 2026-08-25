import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class BookingSuccessScreen extends StatelessWidget {
  final Map<String, dynamic>? appointment;
  const BookingSuccessScreen({super.key, this.appointment});

  @override
  Widget build(BuildContext context) {
    final consultationType = appointment?['consultationType'] as String?;
    final totalAmount = appointment?['totalAmount'];
    // Booking response includes _id (appointment id) + patientId{name,email}
    // + doctorId{name} when this screen is reached straight from booking
    // (not from the payment screen's own success redirect, which passes
    // a lighter extra map — appointmentId will be null in that case,
    // which is fine since payment is already done by then).
    final appointmentId = appointment?['_id'] as String?;
    final doctorName = (appointment?['doctorId'] is Map)
        ? (appointment!['doctorId'] as Map)['name'] as String?
        : null;
    final patientName = (appointment?['patientId'] is Map)
        ? (appointment!['patientId'] as Map)['name'] as String?
        : null;
    final patientEmail = (appointment?['patientId'] is Map)
        ? (appointment!['patientId'] as Map)['email'] as String?
        : null;
    final paymentStatus = appointment?['paymentStatus'] as String?;
    final needsPayment = appointmentId != null && paymentStatus == 'Pending';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppColors.tintTeal,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 56),
              ),
              const SizedBox(height: 24),
              Text(
                'Appointment Booked!',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Your appointment has been confirmed. A confirmation email has been sent to you.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, height: 1.4),
              ),
              if (consultationType != null || totalAmount != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      if (consultationType != null)
                        _Row('Type', consultationType),
                      if (totalAmount != null) ...[
                        const SizedBox(height: 8),
                        _Row('Amount', '₹$totalAmount'),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),
              if (needsPayment) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.push('/payment/$appointmentId', extra: {
                      'amount': totalAmount,
                      'doctorName': doctorName,
                      'patientName': patientName,
                      'patientEmail': patientEmail,
                    }),
                    child: const Text('Pay Now'),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              SizedBox(
                width: double.infinity,
                child: needsPayment
                    ? OutlinedButton(
                  onPressed: () => context.go('/appointments'),
                  child: const Text('Pay Later'),
                )
                    : ElevatedButton(
                  onPressed: () => context.go('/appointments'),
                  child: const Text('View My Appointments'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => context.go('/home'),
                  child: const Text('Back to Home'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
      ],
    );
  }
}