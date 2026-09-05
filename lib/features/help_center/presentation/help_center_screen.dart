import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../home/presentation/widgets/pill_nav_overlay.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PillNavOverlay(
      currentIndex: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Help Center')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            children: [
              Text('How can we help?', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              const Text(
                "Find answers or reach out to our support team",
                style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _ContactCard(
                      icon: Icons.support_agent_rounded,
                      label: 'Live Chat',
                      tint: AppColors.tintBlue,
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ContactCard(
                      icon: Icons.call_rounded,
                      label: '24/7 Helpline',
                      tint: AppColors.tintTeal,
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ContactCard(
                      icon: Icons.mail_outline_rounded,
                      label: 'Email Us',
                      tint: AppColors.tintPurple,
                      onTap: () {},
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text('Frequently Asked Questions', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              const _FaqTile(
                icon: Icons.event_available_rounded,
                question: 'How do I book an appointment?',
                answer:
                'Go to Home, tap "Find Doctor", pick a specialty or search by name, choose a doctor, then select an available date and time slot to book.',
              ),
              const _FaqTile(
                icon: Icons.payments_outlined,
                question: 'What payment methods are accepted?',
                answer:
                'We accept cards, UPI, netbanking, and wallets via Razorpay — the same secure checkout used on the website.',
              ),
              const _FaqTile(
                icon: Icons.videocam_outlined,
                question: 'How does a video consultation work?',
                answer:
                'When it\'s time for your appointment, open "My Appointments" and tap "Join Call" on the scheduled consultation to connect with your doctor.',
              ),
              const _FaqTile(
                icon: Icons.description_outlined,
                question: 'Where can I find my prescription?',
                answer:
                'After a completed consultation, open the appointment from "My Appointments" and tap "View Report" to see your full prescription.',
              ),
              const _FaqTile(
                icon: Icons.cancel_outlined,
                question: 'Can I cancel or reschedule?',
                answer:
                'Cancellations for upcoming appointments can be managed from the appointment details. Contact support if you need help rescheduling.',
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.tintRed,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.emergency_rounded, color: AppColors.danger),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Medical emergency? Please call your local emergency number immediately — this app is not for emergency care.',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color tint;
  final VoidCallback onTap;
  const _ContactCard({required this.icon, required this.label, required this.tint, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
              child: Icon(icon, size: 18, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}

class _FaqTile extends StatefulWidget {
  final IconData icon;
  final String question;
  final String answer;
  const _FaqTile({required this.icon, required this.question, required this.answer});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: AppColors.surfaceMuted, shape: BoxShape.circle),
                    child: Icon(widget.icon, size: 16, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(widget.question, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: _expanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(50, 0, 14, 14),
              child: Text(
                widget.answer,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.5),
              ),
            ),
            secondChild: const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}