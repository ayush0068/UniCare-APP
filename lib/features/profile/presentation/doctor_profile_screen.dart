import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../auth/domain/auth_provider.dart';
import '../data/doctor_profile_api.dart';

class DoctorProfileScreen extends ConsumerStatefulWidget {
  const DoctorProfileScreen({super.key});

  @override
  ConsumerState<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends ConsumerState<DoctorProfileScreen> {
  final _api = DoctorProfileApi();
  Map<String, dynamic>? _doctor;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _api.getProfile();
      setState(() {
        _doctor = data;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('My Profile')),
      body: _loading
          ? const LoadingIndicator()
          : _error != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      )
          : SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildVerificationBadge(),
            const SizedBox(height: 22),
            _sectionLabel('Professional Info'),
            const SizedBox(height: 10),
            _row('Specialization', _doctor?['specialization']),
            _row('Qualification', _doctor?['qualification']),
            _row('Experience', _doctor?['experience'] != null ? '${_doctor!['experience']} years' : null),
            _row('Consultation Fee', _doctor?['fees'] != null ? '₹${_doctor!['fees']}' : null),
            const SizedBox(height: 22),
            _sectionLabel('Hospital / Clinic'),
            const SizedBox(height: 10),
            _row('Name', (_doctor?['hospitalInfo'] as Map?)?['name']),
            _row('City', (_doctor?['hospitalInfo'] as Map?)?['city']),
            _row('Address', (_doctor?['hospitalInfo'] as Map?)?['address']),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.push('/doctor-onboarding'),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit Profile & Documents'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () async {
                  await ref.read(authStateProvider.notifier).logout();
                  if (context.mounted) context.go('/role-selection');
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
                ),
                child: const Text('Log Out'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final name = _doctor?['name'] as String? ?? 'Doctor';
    final email = _doctor?['email'] as String?;
    final ucId = _doctor?['ucId'] as String?;
    return Row(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: AppColors.primaryLight,
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : 'D',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              if (email != null) ...[
                const SizedBox(height: 2),
                Text(email, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
              if (ucId != null) ...[
                const SizedBox(height: 2),
                Text(ucId, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVerificationBadge() {
    final isVerified = _doctor?['isVerified'] == true;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isVerified ? AppColors.tintTeal : AppColors.tintOrange,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            isVerified ? Icons.verified_rounded : Icons.hourglass_top_rounded,
            color: isVerified ? AppColors.primaryDark : const Color(0xFFF59E0B),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isVerified ? 'Your account is verified' : 'Verification pending — admin review in progress',
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(text, style: Theme.of(context).textTheme.titleMedium);

  Widget _row(String label, dynamic value) {
    final display = (value == null || value.toString().isEmpty) ? '—' : value.toString();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted))),
            Flexible(
              child: Text(
                display,
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}