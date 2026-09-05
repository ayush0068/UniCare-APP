import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class AppointmentsEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onBook;

  const AppointmentsEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(color: AppColors.surfaceMuted, shape: BoxShape.circle),
            child: Icon(icon, size: 32, color: AppColors.textMuted),
          ),
          const SizedBox(height: 14),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.4),
            ),
          ),
          if (onBook != null) ...[
            const SizedBox(height: 18),
            OutlinedButton(onPressed: onBook, child: const Text('Find a Doctor')),
          ],
        ],
      ),
    );
  }
}