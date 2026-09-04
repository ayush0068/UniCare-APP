import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../data/call_signaling_service.dart';
import 'call_screen.dart';

/// Shown app-wide (over whatever screen is currently open) the moment a
/// doctor/patient call comes in, via [CallSignalingService.incomingCallStream].
/// Accepting hands off straight into [CallScreen] as the callee; rejecting
/// notifies the caller and dismisses.
class IncomingCallScreen extends StatefulWidget {
  final IncomingCallData call;
  const IncomingCallScreen({super.key, required this.call});

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> {
  bool _handled = false;

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();
  }

  Future<void> _accept() async {
    if (_handled) return;
    _handled = true;
    final role = await SecureStorage.getRole();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => CallScreen(
          role: CallRole.callee,
          appointmentId: widget.call.appointmentId,
          roomId: widget.call.roomId,
          otherUserId: widget.call.fromUserId,
          otherUserName: widget.call.fromUserName,
          isVideoCall: widget.call.isVideoCall,
          isDoctor: role == 'doctor',
          incomingOffer: widget.call.offer,
        ),
      ),
    );
  }

  void _reject() {
    if (_handled) return;
    _handled = true;
    CallSignalingService.instance.rejectCall(
      toUserId: widget.call.fromUserId,
      roomId: widget.call.roomId,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF0B1220),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
            child: Column(
              children: [
                const Spacer(),
                Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.25),
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    widget.call.fromUserName.trim().isNotEmpty
                        ? widget.call.fromUserName.trim()[0].toUpperCase()
                        : '?',
                    style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  widget.call.fromUserName,
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.call.isVideoCall ? 'Incoming video consultation…' : 'Incoming voice consultation…',
                  style: const TextStyle(color: Colors.white70, fontSize: 15),
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ActionButton(
                      icon: Icons.call_end_rounded,
                      color: AppColors.danger,
                      label: 'Decline',
                      onTap: _reject,
                    ),
                    _ActionButton(
                      icon: widget.call.isVideoCall ? Icons.videocam_rounded : Icons.call_rounded,
                      color: AppColors.success,
                      label: 'Accept',
                      onTap: _accept,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: color,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 68,
              height: 68,
              child: Icon(icon, color: Colors.white, size: 30),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
      ],
    );
  }
}