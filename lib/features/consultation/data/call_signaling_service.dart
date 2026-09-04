import 'dart:async';
import '../../../core/network/socket_service.dart';
import '../../../core/storage/secure_storage.dart';

/// Event names exchanged over the Socket.IO connection for call
/// signaling. See WEBRTC_SIGNALING.md for the matching server-side
/// contract to add to the existing Express backend.
class CallEvents {
  CallEvents._();
  static const callUser = 'call-user'; // caller -> server -> callee ("incoming-call")
  static const incomingCall = 'incoming-call'; // server -> callee
  static const answerCall = 'answer-call'; // callee -> server -> caller ("call-answered")
  static const callAnswered = 'call-answered'; // server -> caller
  static const rejectCall = 'reject-call'; // callee -> server -> caller ("call-rejected")
  static const callRejected = 'call-rejected'; // server -> caller
  static const cancelCall = 'cancel-call'; // caller -> server -> callee ("call-cancelled")
  static const callCancelled = 'call-cancelled'; // server -> callee
  static const iceCandidate = 'ice-candidate'; // both ways
  static const endCall = 'end-call'; // either -> server -> other ("call-ended")
  static const callEnded = 'call-ended'; // server -> other party
}

/// Payload for a freshly-arrived incoming call, enough to render the
/// ringing screen and, if accepted, join the room.
class IncomingCallData {
  final String roomId;
  final String appointmentId;
  final String fromUserId;
  final String fromUserName;
  final bool isVideoCall;
  final Map<String, dynamic> offer;

  IncomingCallData({
    required this.roomId,
    required this.appointmentId,
    required this.fromUserId,
    required this.fromUserName,
    required this.isVideoCall,
    required this.offer,
  });

  factory IncomingCallData.fromJson(Map<String, dynamic> json) {
    return IncomingCallData(
      roomId: json['roomId'] as String,
      appointmentId: json['appointmentId'] as String? ?? '',
      fromUserId: json['fromUserId'] as String? ?? '',
      fromUserName: json['fromUserName'] as String? ?? 'Unknown',
      isVideoCall: json['isVideoCall'] as bool? ?? true,
      offer: Map<String, dynamic>.from(json['offer'] as Map),
    );
  }
}

/// Callbacks a currently-open [CallScreen] registers so this service can
/// route live signaling events straight to it while it's on screen.
class ActiveCallHandlers {
  final void Function(Map<String, dynamic> answer) onAnswered;
  final void Function() onRejected;
  final void Function() onCancelled;
  final void Function() onEnded;
  final void Function(Map<String, dynamic> candidate) onIceCandidate;

  ActiveCallHandlers({
    required this.onAnswered,
    required this.onRejected,
    required this.onCancelled,
    required this.onEnded,
    required this.onIceCandidate,
  });
}

/// App-wide call signaling coordinator.
///
/// Registers ONE persistent set of socket listeners for the lifetime of
/// the session (connected right after login / on session restore, torn
/// down on logout). Two things consume it:
///
///  1. [incomingCallStream] — a global stream that a top-level widget
///     listens to, so a ringing screen can be shown no matter which
///     screen the user is currently on (home, appointments, etc.),
///     exactly like a phone call.
///  2. Whichever [CallScreen] is currently open, via
///     [registerActiveCall]/[unregisterActiveCall] — for events that
///     belong to the call already in progress (answer, ICE candidates,
///     hang-up). Events that arrive for the active room *before* a
///     CallScreen has registered (e.g. an ICE candidate that beats the
///     callee tapping "Accept") are buffered and replayed on register.
class CallSignalingService {
  CallSignalingService._();
  static final CallSignalingService instance = CallSignalingService._();

  final _socket = SocketService.instance;
  final _incomingCallController = StreamController<IncomingCallData>.broadcast();

  Stream<IncomingCallData> get incomingCallStream => _incomingCallController.stream;

  String? _activeRoomId;
  ActiveCallHandlers? _activeHandlers;
  final Map<String, List<Map<String, dynamic>>> _pendingIceCandidates = {};

  bool _listening = false;

  Future<void> connect() async {
    await _socket.connect();
    _bindPersistentListeners();
  }

  void disconnect() {
    _socket.disconnect();
    _listening = false;
    _activeRoomId = null;
    _activeHandlers = null;
    _pendingIceCandidates.clear();
  }

  void _bindPersistentListeners() {
    if (_listening) return;
    _listening = true;

    _socket.on(CallEvents.incomingCall, (data) {
      try {
        final call = IncomingCallData.fromJson(Map<String, dynamic>.from(data as Map));
        _incomingCallController.add(call);
      } catch (_) {
        // Malformed payload — ignore rather than crash the listener.
      }
    });

    _socket.on(CallEvents.callAnswered, (data) {
      final map = Map<String, dynamic>.from(data as Map);
      final roomId = map['roomId'] as String?;
      final answer = Map<String, dynamic>.from(map['answer'] as Map);
      if (roomId != null && roomId == _activeRoomId) {
        _activeHandlers?.onAnswered(answer);
      }
    });

    _socket.on(CallEvents.callRejected, (data) {
      final map = Map<String, dynamic>.from(data as Map);
      final roomId = map['roomId'] as String?;
      if (roomId != null && roomId == _activeRoomId) {
        _activeHandlers?.onRejected();
      }
    });

    _socket.on(CallEvents.callCancelled, (data) {
      final map = Map<String, dynamic>.from(data as Map);
      final roomId = map['roomId'] as String?;
      if (roomId != null && roomId == _activeRoomId) {
        _activeHandlers?.onCancelled();
      }
    });

    _socket.on(CallEvents.callEnded, (data) {
      final map = Map<String, dynamic>.from(data as Map);
      final roomId = map['roomId'] as String?;
      if (roomId != null && roomId == _activeRoomId) {
        _activeHandlers?.onEnded();
      }
    });

    _socket.on(CallEvents.iceCandidate, (data) {
      final map = Map<String, dynamic>.from(data as Map);
      final roomId = map['roomId'] as String?;
      final candidate = Map<String, dynamic>.from(map['candidate'] as Map);
      if (roomId == null) return;
      if (roomId == _activeRoomId && _activeHandlers != null) {
        _activeHandlers!.onIceCandidate(candidate);
      } else {
        _pendingIceCandidates.putIfAbsent(roomId, () => []).add(candidate);
      }
    });
  }

  /// Called by [CallScreen] as soon as it knows its room ID, so live
  /// events route straight to it. Immediately replays any buffered ICE
  /// candidates that arrived while nothing was listening yet.
  void registerActiveCall(String roomId, ActiveCallHandlers handlers) {
    _activeRoomId = roomId;
    _activeHandlers = handlers;
    final pending = _pendingIceCandidates.remove(roomId);
    if (pending != null) {
      for (final candidate in pending) {
        handlers.onIceCandidate(candidate);
      }
    }
  }

  void unregisterActiveCall(String roomId) {
    if (_activeRoomId == roomId) {
      _activeRoomId = null;
      _activeHandlers = null;
    }
    _pendingIceCandidates.remove(roomId);
  }

  // --- Outgoing signals -----------------------------------------------

  Future<void> callUser({
    required String toUserId,
    required String roomId,
    required String appointmentId,
    required bool isVideoCall,
    required Map<String, dynamic> offer,
  }) async {
    final selfId = await SecureStorage.getUserId();
    _socket.emit(CallEvents.callUser, {
      'toUserId': toUserId,
      'roomId': roomId,
      'appointmentId': appointmentId,
      'isVideoCall': isVideoCall,
      'offer': offer,
      'fromUserId': selfId,
    });
  }

  void answerCall({
    required String toUserId,
    required String roomId,
    required Map<String, dynamic> answer,
  }) {
    _socket.emit(CallEvents.answerCall, {
      'toUserId': toUserId,
      'roomId': roomId,
      'answer': answer,
    });
  }

  void rejectCall({required String toUserId, required String roomId}) {
    _socket.emit(CallEvents.rejectCall, {'toUserId': toUserId, 'roomId': roomId});
  }

  void cancelCall({required String toUserId, required String roomId}) {
    _socket.emit(CallEvents.cancelCall, {'toUserId': toUserId, 'roomId': roomId});
  }

  void sendIceCandidate({
    required String toUserId,
    required String roomId,
    required Map<String, dynamic> candidate,
  }) {
    _socket.emit(CallEvents.iceCandidate, {
      'toUserId': toUserId,
      'roomId': roomId,
      'candidate': candidate,
    });
  }

  void endCall({required String toUserId, required String roomId}) {
    _socket.emit(CallEvents.endCall, {'toUserId': toUserId, 'roomId': roomId});
  }
}