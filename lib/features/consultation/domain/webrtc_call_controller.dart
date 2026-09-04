import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

enum CallConnectionStatus { connecting, ringing, active, ended, failed }

/// Wraps a single [RTCPeerConnection] for a one-to-one doctor/patient
/// call: local/remote media, offer/answer creation, ICE handling, and
/// the in-call controls (mute, camera on/off, switch camera).
///
/// This class is transport-agnostic — it doesn't know about sockets or
/// rooms. [CallScreen] wires its `onIceCandidate` output to
/// [CallSignalingService], and feeds remote SDP/ICE back in.
class WebRtcCallController extends ChangeNotifier {
  final bool isVideoCall;

  /// Fired for every local ICE candidate that needs to be sent to the
  /// other party over signaling.
  final void Function(Map<String, dynamic> candidate) onIceCandidate;

  WebRtcCallController({required this.isVideoCall, required this.onIceCandidate});

  RTCPeerConnection? _pc;
  MediaStream? localStream;
  MediaStream? remoteStream;

  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  CallConnectionStatus status = CallConnectionStatus.connecting;
  bool isMuted = false;
  bool isCameraOff = false;
  bool _usingFrontCamera = true;

  // Buffers remote ICE candidates that arrive before the peer connection
  // has a remote description set yet (can happen with fast trickle ICE).
  final List<RTCIceCandidate> _pendingRemoteCandidates = [];

  static const Map<String, dynamic> _iceServers = {
    'iceServers': [
      {
        'urls': [
          'stun:stun.l.google.com:19302',
          'stun:stun1.l.google.com:19302',
        ],
      },
      // For reliable connectivity across mobile networks / strict NATs,
      // add a TURN server here, e.g.:
      // {
      //   'urls': 'turn:your.turn.server:3478',
      //   'username': 'turn_user',
      //   'credential': 'turn_password',
      // },
    ],
  };

  Future<void> _initRenderers() async {
    await localRenderer.initialize();
    await remoteRenderer.initialize();
  }

  Future<MediaStream> _openLocalMedia() async {
    final constraints = <String, dynamic>{
      'audio': true,
      'video': isVideoCall
          ? {
        'facingMode': 'user',
        'width': {'ideal': 640},
        'height': {'ideal': 480},
      }
          : false,
    };
    final stream = await navigator.mediaDevices.getUserMedia(constraints);
    localStream = stream;
    localRenderer.srcObject = stream;
    return stream;
  }

  Future<RTCPeerConnection> _createPeerConnection(MediaStream stream) async {
    final pc = await createPeerConnection(_iceServers);

    for (final track in stream.getTracks()) {
      await pc.addTrack(track, stream);
    }

    pc.onIceCandidate = (candidate) {
      if (candidate.candidate == null) return;
      onIceCandidate({
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
      });
    };

    pc.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        remoteStream = event.streams.first;
        remoteRenderer.srcObject = remoteStream;
        notifyListeners();
      }
    };

    pc.onConnectionState = (state) {
      switch (state) {
        case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
          status = CallConnectionStatus.active;
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
        case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
          status = CallConnectionStatus.failed;
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
        // Transient — WebRTC often recovers on its own; only surface
        // a hard failure via RTCPeerConnectionStateFailed above.
          break;
        default:
          break;
      }
      notifyListeners();
    };

    return pc;
  }

  /// Caller side: opens local media, creates the peer connection, and
  /// returns the SDP offer to send over signaling.
  Future<Map<String, dynamic>> createOffer() async {
    await _initRenderers();
    final stream = await _openLocalMedia();
    _pc = await _createPeerConnection(stream);

    final offer = await _pc!.createOffer();
    await _pc!.setLocalDescription(offer);
    status = CallConnectionStatus.ringing;
    notifyListeners();
    return {'sdp': offer.sdp, 'type': offer.type};
  }

  /// Callee side: opens local media, creates the peer connection with
  /// the caller's offer as the remote description, and returns the SDP
  /// answer to send back over signaling.
  Future<Map<String, dynamic>> createAnswer(Map<String, dynamic> offer) async {
    await _initRenderers();
    final stream = await _openLocalMedia();
    _pc = await _createPeerConnection(stream);

    await _pc!.setRemoteDescription(
      RTCSessionDescription(offer['sdp'] as String, offer['type'] as String),
    );
    await _drainPendingCandidates();

    final answer = await _pc!.createAnswer();
    await _pc!.setLocalDescription(answer);
    notifyListeners();
    return {'sdp': answer.sdp, 'type': answer.type};
  }

  /// Caller side: applies the callee's SDP answer once it arrives.
  Future<void> setRemoteAnswer(Map<String, dynamic> answer) async {
    if (_pc == null) return;
    await _pc!.setRemoteDescription(
      RTCSessionDescription(answer['sdp'] as String, answer['type'] as String),
    );
    await _drainPendingCandidates();
  }

  Future<void> addRemoteIceCandidate(Map<String, dynamic> data) async {
    final candidate = RTCIceCandidate(
      data['candidate'] as String?,
      data['sdpMid'] as String?,
      data['sdpMLineIndex'] as int?,
    );
    if (_pc == null || (await _pc!.getRemoteDescription()) == null) {
      _pendingRemoteCandidates.add(candidate);
      return;
    }
    await _pc!.addCandidate(candidate);
  }

  Future<void> _drainPendingCandidates() async {
    for (final candidate in _pendingRemoteCandidates) {
      await _pc?.addCandidate(candidate);
    }
    _pendingRemoteCandidates.clear();
  }

  void toggleMute() {
    isMuted = !isMuted;
    for (final track in localStream?.getAudioTracks() ?? <MediaStreamTrack>[]) {
      track.enabled = !isMuted;
    }
    notifyListeners();
  }

  void toggleCamera() {
    if (!isVideoCall) return;
    isCameraOff = !isCameraOff;
    for (final track in localStream?.getVideoTracks() ?? <MediaStreamTrack>[]) {
      track.enabled = !isCameraOff;
    }
    notifyListeners();
  }

  Future<void> switchCamera() async {
    if (!isVideoCall) return;
    final videoTracks = localStream?.getVideoTracks() ?? <MediaStreamTrack>[];
    if (videoTracks.isEmpty) return;
    await Helper.switchCamera(videoTracks.first);
    _usingFrontCamera = !_usingFrontCamera;
    notifyListeners();
  }

  bool get isFrontCamera => _usingFrontCamera;

  Future<void> hangUp() async {
    status = CallConnectionStatus.ended;
    for (final track in localStream?.getTracks() ?? <MediaStreamTrack>[]) {
      await track.stop();
    }
    await _pc?.close();
    await localRenderer.dispose();
    await remoteRenderer.dispose();
    notifyListeners();
  }
}