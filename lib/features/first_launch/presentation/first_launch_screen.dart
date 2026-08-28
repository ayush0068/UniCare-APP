import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/theme/app_colors.dart';

/// Shown exactly once per install, before anything else in the app —
/// required for Galaxy Store / Play Store listings that involve health
/// data, camera/mic (video consultations), and file access (document
/// uploads): a clear notice, Terms & Privacy acceptance, and a rundown
/// of what permissions the app will ask for and why.
class FirstLaunchScreen extends StatefulWidget {
  const FirstLaunchScreen({super.key});

  @override
  State<FirstLaunchScreen> createState() => _FirstLaunchScreenState();
}

class _FirstLaunchScreenState extends State<FirstLaunchScreen> {
  bool _agreed = false;
  bool _continuing = false;

  Future<void> _continue() async {
    setState(() => _continuing = true);

    // Request the permissions the app actually uses up front, so the
    // person sees one clear batch of system prompts here rather than
    // being surprised mid-flow (e.g. right as a video call is starting).
    // Any denied here can still be granted later from Android Settings
    // when the person actually tries that feature — nothing here blocks
    // app usage, it's just requesting them proactively and transparently.
    await [
      Permission.camera,
      Permission.microphone,
      Permission.photos,
      Permission.notification,
    ].request();

    await SecureStorage.setAcceptedTerms();
    if (!mounted) return;
    context.go('/');
  }

  void _showPolicyDialog(String title, String body) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Text(body, style: const TextStyle(fontSize: 13, height: 1.5)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                children: [
                  const Icon(Icons.health_and_safety_rounded, color: AppColors.primary, size: 48),
                  const SizedBox(height: 14),
                  Text('Welcome to UniCare+', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  const Text(
                    'Before you get started, please review a few important things.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 24),
                  _NoticeCard(
                    icon: Icons.info_outline_rounded,
                    tint: AppColors.tintBlue,
                    title: 'Health information notice',
                    body:
                    'UniCare+ helps connect you with licensed doctors for consultations. It does not replace emergency medical care — if you\'re experiencing a medical emergency, please call your local emergency number immediately.',
                  ),
                  const SizedBox(height: 14),
                  _NoticeCard(
                    icon: Icons.shield_outlined,
                    tint: AppColors.tintTeal,
                    title: 'Your data',
                    body:
                    'Information you provide (profile, medical history, appointment details) is used to provide the service and is shared only with the doctors you consult. See our full Privacy Policy for details.',
                  ),
                  const SizedBox(height: 24),
                  Text('Permissions we\'ll ask for', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  const _PermissionRow(
                    icon: Icons.videocam_outlined,
                    title: 'Camera',
                    reason: 'For video consultations with doctors',
                  ),
                  const _PermissionRow(
                    icon: Icons.mic_none_rounded,
                    title: 'Microphone',
                    reason: 'For voice and video consultations',
                  ),
                  const _PermissionRow(
                    icon: Icons.photo_outlined,
                    title: 'Photos / Files',
                    reason: 'To upload verification documents or prescriptions',
                  ),
                  const _PermissionRow(
                    icon: Icons.notifications_none_rounded,
                    title: 'Notifications',
                    reason: 'To alert you about appointments and messages',
                  ),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _agreed,
                        onChanged: (v) => setState(() => _agreed = v ?? false),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary, height: 1.4),
                              children: [
                                const TextSpan(text: 'I agree to the '),
                                TextSpan(
                                  text: 'Terms of Service',
                                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                                ),
                                const TextSpan(text: ' and '),
                                TextSpan(
                                  text: 'Privacy Policy',
                                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => _showPolicyDialog('Terms of Service', _termsText),
                        child: const Text('Read Terms', style: TextStyle(fontSize: 12)),
                      ),
                      TextButton(
                        onPressed: () => _showPolicyDialog('Privacy Policy', _privacyText),
                        child: const Text('Read Privacy Policy', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_agreed && !_continuing) ? _continue : null,
                  child: _continuing
                      ? const SizedBox(
                    height: 20, width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                      : const Text('Continue'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  final IconData icon;
  final Color tint;
  final String title;
  final String body;
  const _NoticeCard({required this.icon, required this.tint, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(14)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.textPrimary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 4),
                Text(body, style: const TextStyle(fontSize: 12, height: 1.4, color: AppColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String reason;
  const _PermissionRow({required this.icon, required this.title, required this.reason});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: const BoxDecoration(color: AppColors.surfaceMuted, shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                Text(reason, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Placeholder legal text — replace with your actual Terms of Service /
// Privacy Policy before publishing to the Galaxy Store. If you'd rather
// link to hosted pages instead of showing text in-app, swap this dialog
// for a url_launcher call to your website's /terms and /privacy pages.
const _termsText = '''
These are placeholder Terms of Service for UniCare+.

By using this app, you agree to use it only for lawful purposes and to provide accurate information when booking consultations or creating an account.

UniCare+ is a platform connecting patients with licensed healthcare providers. It is not a substitute for emergency medical services.

Replace this text with your actual Terms of Service before publishing.
''';

const _privacyText = '''
These are placeholder Privacy Policy details for UniCare+.

We collect information you provide (name, contact details, medical history) to deliver the consultation service. This information is shared only with the doctors you consult and is not sold to third parties.

Payment information is processed securely by Razorpay and is not stored on our servers.

Replace this text with your actual Privacy Policy before publishing.
''';