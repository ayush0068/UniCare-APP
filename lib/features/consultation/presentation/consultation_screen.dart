import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import '../../../core/config/app_config.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../data/consultation_api.dart';

/// Video/voice consultation call screen. Mirrors the website's
/// AppointmentCall.tsx exactly:
///   1. GET /appointment/join/:id -> marks appointment "In Progress",
///      returns the ZegoCloud room ID + populated patient/doctor names.
///   2. Join the ZegoCloud room using the same App ID / Server Secret
///      pair the website uses (test-mode token generation).
///   3. Video vs Voice call config is driven by the appointment's
///      consultationType, same as the website switching camera-on/off.
/// Ending the call just returns to the previous screen — actually
/// completing the appointment (with prescription) stays a separate
/// doctor action from the Appointments page, same as on the website.
class ConsultationScreen extends StatefulWidget {
  final String appointmentId;
  const ConsultationScreen({super.key, required this.appointmentId});

  @override
  State<ConsultationScreen> createState() => _ConsultationScreenState();
}

class _ConsultationScreenState extends State<ConsultationScreen> {
  final _api = ConsultationApi();
  bool _loading = true;
  String? _error;

  String? _roomId;
  String? _selfId;
  String? _selfName;
  bool _isVideoCall = true;
  bool _isDoctor = false;
  String _counterpartName = '';

  @override
  void initState() {
    super.initState();
    _joinCall();
  }

  Future<void> _joinCall() async {
    setState(() => _loading = true);
    try {
      if (AppConfig.zegoAppId == 0 || AppConfig.zegoAppSign.isEmpty) {
        throw Exception('ZegoCloud is not configured — add ZEGOCLOUD_APP_ID and ZEGOCLOUD_APP_SIGN to .env');
      }

      final data = await _api.joinConsultation(widget.appointmentId);
      final appointment = data['appointment'] as Map<String, dynamic>;
      final role = await SecureStorage.getRole();
      final userId = await SecureStorage.getUserId();

      final patient = appointment['patientId'] as Map<String, dynamic>?;
      final doctor = appointment['doctorId'] as Map<String, dynamic>?;
      final isDoctor = role == 'doctor';

      setState(() {
        _roomId = data['roomId'] as String?;
        _selfId = userId;
        _selfName = isDoctor ? (doctor?['name'] as String? ?? 'Doctor') : (patient?['name'] as String? ?? 'Patient');
        _isVideoCall = appointment['consultationType'] == 'Video Consultation';
        _isDoctor = isDoctor;
        _counterpartName = isDoctor ? (patient?['name'] as String? ?? 'Patient') : (doctor?['name'] as String? ?? 'Doctor');
        _loading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(backgroundColor: Colors.black, body: LoadingIndicator());
    }

    if (_error != null || _roomId == null || _selfId == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Consultation')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, size: 40, color: AppColors.danger),
                const SizedBox(height: 12),
                Text(_error ?? 'Could not join the call', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                OutlinedButton(onPressed: _joinCall, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: ZegoUIKitPrebuiltCall(
        appID: AppConfig.zegoAppId,
        appSign: AppConfig.zegoAppSign,
        userID: _selfId!,
        userName: _selfName!,
        callID: _roomId!,
        // Default hang-up behavior already pops back to the previous
        // screen when the user taps end-call — no custom callback wiring
        // needed. Keeping this config minimal avoids depending on setter
        // names that shift between SDK versions.
        config: _isVideoCall
            ? ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
            : ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall(),
        events: ZegoUIKitPrebuiltCallEvents(
          onCallEnd: (event, defaultAction) {
            if (_isDoctor) {
              // Matches the website: ending the call redirects the doctor
              // straight into the prescription form (which marks the
              // appointment Completed on save) instead of just going back.
              context.pushReplacement(
                '/prescription/new/${widget.appointmentId}',
                extra: {'patientName': _counterpartName},
              );
            } else {
              defaultAction.call();
            }
          },
        ),
      ),
    );
  }
}