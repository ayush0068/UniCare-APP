import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

/// First screen a logged-out user sees. Matches the website's separate
/// patient vs doctor portals — everything downstream (auth, home,
/// dashboard) branches from this choice.
class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              const Icon(Icons.health_and_safety_rounded, color: AppColors.primary, size: 56),
              const SizedBox(height: 14),
              Text('UniCare+', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 6),
              const Text(
                'Continue as',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 28),
              _RoleCard(
                icon: Icons.person_rounded,
                title: 'Patient',
                subtitle: 'Book consultations, manage prescriptions, and more',
                tint: AppColors.tintTeal,
                onTap: () => context.push('/login'),
              ),
              const SizedBox(height: 16),
              _RoleCard(
                icon: Icons.medical_services_rounded,
                title: 'Doctor',
                subtitle: 'Manage appointments, patients, and your practice',
                tint: AppColors.tintBlue,
                onTap: () => context.push('/doctor-login'),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.go('/home'),
                child: const Text('Just browsing? Continue as Guest'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color tint;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
              child: Icon(icon, color: AppColors.textPrimary, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}