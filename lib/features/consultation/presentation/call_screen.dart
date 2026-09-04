import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../../core/theme/app_colors.dart';
import '../../prescription/presentation/prescription_form_screen.dart';
import '../data/call_signaling_service.dart';
import '../domain/webrtc_call_controller.dart';

enum CallRole { caller, callee }

/// Local, non-WebRTC state of the call screen itself — separate from
/// [CallConnectionStatus], which only describes the peer connection.
enum _ScreenPhase { settingUp, ringing, connecting, active, endedNoPrescription, error }

/// The actual doctor/patient audio/video call UI, built on
/// flutter_webrtc + [CallSignalingService]. Handles both roles:
///
///  - [CallRole.caller]: the person who tapped "Join Call" from the
///    appointments list. Creates the offer, rings the other party, and
///    waits for them to accept.
///  - [CallRole.callee]: the person who tapped "Accept" on the
///    incoming-call screen. Already has the caller's offer and
///    immediately answers.
class CallScreen extends StatefulWidget {
  final CallRole role;
  final String appointmentId;
  final String roomId;
  final String otherUserId;
  final String otherUserName;
  final bool isVideoCall;
  final bool isDoctor;

  /// Required when [role] is [CallRole.callee].
  final Map<String, dynamic>? incomingOffer;

  const CallScreen({
    super.key,
    required this.role,
    required this.appointmentId,
    required this.roomId,
    required this.otherUserId,
    required this.otherUserName,
    required this.isVideoCall,
    required this.isDoctor,
    this.incomingOffer,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  late final WebRtcCallController _controller;
  final _signaling = CallSignalingService.instance;

  _ScreenPhase _phase = _ScreenPhase.settingUp;
  String? _statusMessage;
  Timer? _noAnswerTimer;
  Timer? _durationTimer;
  Duration _callDuration = Duration.zero;
  bool _localHasEnded = false;

  @override
  void initState() {
    super.initState();
    WakelockPlaceholder.enable();
    _controller = WebRtcCallController(
      isVideoCall: widget.isVideoCall,
      onIceCandidate: (candidate) => _signaling.sendIceCandidate(
        toUserId: widget.otherUserId,
        roomId: widget.roomId,
        candidate: candidate,
      ),
    )..addListener(_onControllerChanged);

    _signaling.registerActiveCall(
      widget.roomId,
      ActiveCallHandlers(
        onAnswered: _handleAnswered,
        onRejected: _handleRejected,
        onCancelled: _handleCancelledByCaller,
        onEnded: _handleRemoteEnded,
        onIceCandidate: _controller.addRemoteIceCandidate,
      ),
    );

    _startCall();
  }

  Future<void> _startCall() async {
    try {
      if (widget.role == CallRole.caller) {
        final offer = await _controller.createOffer();
        if (!mounted) return;
        setState(() => _phase = _ScreenPhase.ringing);
        await _signaling.callUser(
          toUserId: widget.otherUserId,
          roomId: widget.roomId,
          appointmentId: widget.appointmentId,
          isVideoCall: widget.isVideoCall,
          offer: offer,
        );
        _noAnswerTimer = Timer(const Duration(seconds: 45), () {
          if (!mounted || _phase != _ScreenPhase.ringing) return;
          _signaling.cancelCall(toUserId: widget.otherUserId, roomId: widget.roomId);
          _exitWithoutPrescription('${widget.otherUserName} didn\'t answer');
        });
      } else {
        setState(() => _phase = _ScreenPhase.connecting);
        final answer = await _controller.createAnswer(widget.incomingOffer!);
        _signaling.answerCall(
          toUserId: widget.otherUserId,
          roomId: widget.roomId,
          answer: answer,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _ScreenPhase.error;
        _statusMessage = 'Could not access camera/microphone: $e';
      });
    }
  }

  void _onControllerChanged() {
    if (!mounted) return;
    if (_controller.status == CallConnectionStatus.active && _phase != _ScreenPhase.active) {
      _noAnswerTimer?.cancel();
      setState(() => _phase = _ScreenPhase.active);
      _durationTimer ??= Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _callDuration += const Duration(seconds: 1));
      });
    } else if (_controller.status == CallConnectionStatus.failed && _phase == _ScreenPhase.active) {
      _handleRemoteEnded();
    } else {
      setState(() {});
    }
  }

  void _handleAnswered(Map<String, dynamic> answer) {
    _noAnswerTimer?.cancel();
    if (!mounted) return;
    setState(() => _phase = _ScreenPhase.connecting);
    _controller.setRemoteAnswer(answer);
  }

  void _handleRejected() {
    _noAnswerTimer?.cancel();
    _exitWithoutPrescription('${widget.otherUserName} declined the call');
  }

  void _handleCancelledByCaller() {
    _exitWithoutPrescription('Call cancelled');
  }

  void _handleRemoteEnded() {
    if (_localHasEnded) return;
    if (_phase == _ScreenPhase.active) {
      _endActiveCall(userInitiated: false);
    } else {
      _exitWithoutPrescription('Call ended');
    }
  }

  /// Ends the screen for calls that never actually connected (declined,
  /// cancelled, no answer, or a media/permission error) — just informs
  /// the user and goes back, without the "call ended -> prescription"
  /// hand-off that only makes sense for a real consultation.
  void _exitWithoutPrescription(String message) {
    if (_localHasEnded) return;
    _localHasEnded = true;
    _signaling.unregisterActiveCall(widget.roomId);
    _controller.hangUp();
    WakelockPlaceholder.disable();
    if (!mounted) return;
    setState(() {
      _phase = _ScreenPhase.endedNoPrescription;
      _statusMessage = message;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      final navigator = Navigator.of(context);
      if (navigator.canPop()) navigator.pop();
    });
  }

  /// Ends a call that was actually connected. Mirrors the previous
  /// behavior: for the doctor, hanging up moves straight into writing
  /// the prescription (which marks the appointment Completed on save);
  /// for the patient, it just returns to the previous screen.
  Future<void> _endActiveCall({required bool userInitiated}) async {
    if (_localHasEnded) return;
    _localHasEnded = true;
    _noAnswerTimer?.cancel();
    _durationTimer?.cancel();
    if (userInitiated) {
      _signaling.endCall(toUserId: widget.otherUserId, roomId: widget.roomId);
    }
    _signaling.unregisterActiveCall(widget.roomId);
    await _controller.hangUp();
    WakelockPlaceholder.disable();
    if (!mounted) return;

    final navigator = Navigator.of(context);
    if (widget.isDoctor) {
      // Matches the previous behavior: ending the call moves the doctor
      // straight into writing the prescription, which marks the
      // appointment Completed on save.
      navigator.pushReplacement(
        MaterialPageRoute(
          builder: (_) => PrescriptionFormScreen(
            appointmentId: widget.appointmentId,
            patientName: widget.otherUserName,
          ),
        ),
      );
    } else if (navigator.canPop()) {
      navigator.pop();
    }
  }

  void _onEndCallPressed() {
    HapticFeedback.mediumImpact();
    if (_phase == _ScreenPhase.active) {
      _endActiveCall(userInitiated: true);
    } else if (widget.role == CallRole.caller && _phase == _ScreenPhase.ringing) {
      _signaling.cancelCall(toUserId: widget.otherUserId, roomId: widget.roomId);
      _exitWithoutPrescription('Call cancelled');
    } else {
      _exitWithoutPrescription('Call ended');
    }
  }

  @override
  void dispose() {
    _noAnswerTimer?.cancel();
    _durationTimer?.cancel();
    _controller.removeListener(_onControllerChanged);
    if (!_localHasEnded) {
      _signaling.unregisterActiveCall(widget.roomId);
      _controller.hangUp();
      WakelockPlaceholder.disable();
    }
    super.dispose();
  }

  String get _formattedDuration {
    final m = _callDuration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = _callDuration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return _callDuration.inHours > 0
        ? '${_callDuration.inHours}:$m:$s'
        : '$m:$s';
  }

  String get _statusLabel {
    switch (_phase) {
      case _ScreenPhase.settingUp:
        return 'Setting up…';
      case _ScreenPhase.ringing:
        return 'Calling ${widget.otherUserName}…';
      case _ScreenPhase.connecting:
        return 'Connecting…';
      case _ScreenPhase.active:
        return _formattedDuration;
      case _ScreenPhase.endedNoPrescription:
        return _statusMessage ?? 'Call ended';
      case _ScreenPhase.error:
        return _statusMessage ?? 'Something went wrong';
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _onEndCallPressed();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0B1220),
        body: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(child: _buildMainArea()),
              _buildTopBar(),
              if (_phase == _ScreenPhase.error)
                _buildErrorOverlay()
              else
                _buildBottomControls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainArea() {
    final hasRemoteVideo = widget.isVideoCall &&
        _controller.remoteStream != null &&
        _controller.remoteStream!.getVideoTracks().isNotEmpty;

    if (hasRemoteVideo) {
      return Stack(
        children: [
          Positioned.fill(
            child: RTCVideoView(
              _controller.remoteRenderer,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            ),
          ),
          if (widget.isVideoCall) _buildLocalPreview(),
        ],
      );
    }

    // Voice call, or video call before the remote video track arrives:
    // a calm avatar/name layout instead of a black rectangle.
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0F2027), Color(0xFF0B1220)],
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Avatar(name: widget.otherUserName),
                const SizedBox(height: 20),
                Text(
                  widget.otherUserName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _statusLabel,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          if (widget.isVideoCall) _buildLocalPreview(),
        ],
      ),
    );
  }

  Widget _buildLocalPreview() {
    return Positioned(
      top: 16,
      right: 16,
      child: SizedBox(
        width: 108,
        height: 148,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            color: Colors.black,
            child: _controller.isCameraOff
                ? const Center(
              child: Icon(Icons.videocam_off_rounded, color: Colors.white54, size: 28),
            )
                : RTCVideoView(
              _controller.localRenderer,
              mirror: _controller.isFrontCamera,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 4,
      left: 8,
      right: 8,
      child: Row(
        children: [
          if (widget.isVideoCall && _controller.remoteStream != null)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Text(
                  '${widget.otherUserName} · $_statusLabel',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    shadows: [Shadow(blurRadius: 6, color: Colors.black54)],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
          else
            const Spacer(),
        ],
      ),
    );
  }

  Widget _buildErrorOverlay() {
    return Positioned.fill(
      child: Container(
        color: const Color(0xCC0B1220),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 40),
                const SizedBox(height: 12),
                Text(
                  _statusMessage ?? 'Something went wrong',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => _exitWithoutPrescription('Call ended'),
                  child: const Text('Go back'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 22,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_phase != _ScreenPhase.active)
            Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Text(
                _statusLabel,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ControlButton(
                icon: _controller.isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                active: _controller.isMuted,
                onTap: () {
                  HapticFeedback.selectionClick();
                  _controller.toggleMute();
                },
              ),
              const SizedBox(width: 14),
              if (widget.isVideoCall) ...[
                _ControlButton(
                  icon: _controller.isCameraOff
                      ? Icons.videocam_off_rounded
                      : Icons.videocam_rounded,
                  active: _controller.isCameraOff,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    _controller.toggleCamera();
                  },
                ),
                const SizedBox(width: 14),
                _ControlButton(
                  icon: Icons.cameraswitch_rounded,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    _controller.switchCamera();
                  },
                ),
                const SizedBox(width: 14),
              ],
              _EndCallButton(onTap: _onEndCallPressed),
            ],
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  const _Avatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary.withValues(alpha: 0.25),
        border: Border.all(color: AppColors.primary, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _ControlButton({required this.icon, required this.onTap, this.active = false});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? Colors.white : Colors.white.withValues(alpha: 0.14),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 56,
          height: 56,
          child: Icon(icon, color: active ? const Color(0xFF0B1220) : Colors.white, size: 24),
        ),
      ),
    );
  }
}

class _EndCallButton extends StatelessWidget {
  final VoidCallback onTap;
  const _EndCallButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.danger,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          width: 64,
          height: 64,
          child: Icon(Icons.call_end_rounded, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}

/// Keeping the screen awake during a call is a nice-to-have, not part
/// of the requested feature set — this no-op placeholder documents the
/// intent without adding a new dependency (e.g. `wakelock_plus`) beyond
/// what was asked for. Wire it up if you add that package later.
class WakelockPlaceholder {
  static void enable() {}
  static void disable() {}
}