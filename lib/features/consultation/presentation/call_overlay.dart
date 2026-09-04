import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/router/app_router.dart';
import '../data/call_signaling_service.dart';
import 'incoming_call_screen.dart';

/// Wraps the whole app (see `builder:` in app.dart) and listens for
/// incoming calls for as long as the app is running, showing the
/// ringing screen full-screen over whatever the user is currently
/// looking at — home, appointments, profile, anything.
class CallOverlay extends StatefulWidget {
  final Widget child;
  const CallOverlay({super.key, required this.child});

  @override
  State<CallOverlay> createState() => _CallOverlayState();
}

class _CallOverlayState extends State<CallOverlay> {
  StreamSubscription<IncomingCallData>? _subscription;
  bool _showingIncomingCall = false;

  @override
  void initState() {
    super.initState();
    _subscription = CallSignalingService.instance.incomingCallStream.listen(_onIncomingCall);
  }

  void _onIncomingCall(IncomingCallData call) {
    // Already on a call / already showing a ringing screen -> treat the
    // new one as busy rather than interrupting the active call.
    if (_showingIncomingCall) {
      CallSignalingService.instance.rejectCall(toUserId: call.fromUserId, roomId: call.roomId);
      return;
    }

    final navigatorState = rootNavigatorKey.currentState;
    if (navigatorState == null) return;

    _showingIncomingCall = true;
    navigatorState
        .push(MaterialPageRoute(fullscreenDialog: true, builder: (_) => IncomingCallScreen(call: call)))
        .then((_) => _showingIncomingCall = false);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}