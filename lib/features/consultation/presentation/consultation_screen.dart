import 'package:flutter/material.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../data/call_signaling_service.dart';
import '../data/consultation_api.dart';
import 'call_screen.dart';

/// Entry point reached from the appointments list's "Join Call" button
/// (route: /consultation/:appointmentId). Loads the appointment + room
/// info from the existing backend, makes sure call signaling is
/// connected, then hands off into [CallScreen] as the caller.
///
///   1. GET /appointment/join/:id -> marks the appointment "In
///      Progress", returns the room ID + populated patient/doctor info.
///   2. Calls the other party over WebRTC using that room ID as the
///      signaling room (see WEBRTC_SIGNALING.md for the required
///      backend Socket.IO events).
///   3. Video vs voice is driven by the appointment's consultationType,
///      same as before.
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
  String? _otherUserId;
  String _otherUserName = '';
  bool _isVideoCall = true;
  bool _isDoctor = false;

  @override
  void initState() {
    super.initState();
    _prepareCall();
  }

  String? _extractId(Map<String, dynamic>? user) {
    if (user == null) return null;
    return (user['_id'] ?? user['id'])?.toString();
  }

  Future<void> _prepareCall() async {
    setState(() => _loading = true);
    try {
      // Signaling must be connected before we ring the other party.
      await CallSignalingService.instance.connect();

      final data = await _api.joinConsultation(widget.appointmentId);
      final appointment = data['appointment'] as Map<String, dynamic>;
      final role = await SecureStorage.getRole();

      final patient = appointment['patientId'] as Map<String, dynamic>?;
      final doctor = appointment['doctorId'] as Map<String, dynamic>?;
      final isDoctor = role == 'doctor';

      final roomId = data['roomId'] as String? ?? widget.appointmentId;
      final otherUserId = isDoctor ? _extractId(patient) : _extractId(doctor);

      if (otherUserId == null) {
        throw Exception('Could not determine who to call for this appointment.');
      }

      setState(() {
        _roomId = roomId;
        _otherUserId = otherUserId;
        _otherUserName = isDoctor
            ? (patient?['name'] as String? ?? 'Patient')
            : (doctor?['name'] as String? ?? 'Doctor');
        _isVideoCall = appointment['consultationType'] == 'Video Consultation';
        _isDoctor = isDoctor;
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

    if (_error != null || _roomId == null || _otherUserId == null) {
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
                OutlinedButton(onPressed: _prepareCall, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      );
    }

    return CallScreen(
      role: CallRole.caller,
      appointmentId: widget.appointmentId,
      roomId: _roomId!,
      otherUserId: _otherUserId!,
      otherUserName: _otherUserName,
      isVideoCall: _isVideoCall,
      isDoctor: _isDoctor,
    );
  }
}