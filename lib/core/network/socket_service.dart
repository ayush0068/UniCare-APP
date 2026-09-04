import 'package:socket_io_client/socket_io_client.dart' as io;
import '../config/app_config.dart';
import '../storage/secure_storage.dart';

/// Single Socket.IO connection used for real-time doctor/patient call
/// signaling (ringing, offer/answer exchange, ICE candidates, hang-up).
///
/// This does NOT replace or change any REST call — Dio/DioClient still
/// handles auth, appointments, payments, etc. This is purely the
/// transport for the small set of WebRTC signaling events described in
/// WEBRTC_SIGNALING.md, which your existing Express server needs to
/// relay (attaching Socket.IO to the same HTTP server it already runs).
class SocketService {
  SocketService._();
  static final SocketService instance = SocketService._();

  io.Socket? _socket;

  bool get isConnected => _socket?.connected ?? false;

  /// Connects (or reuses an existing connection) authenticated as the
  /// currently logged-in user. Safe to call multiple times.
  Future<void> connect() async {
    if (_socket != null && _socket!.connected) return;

    final token = await SecureStorage.getToken();
    final userId = await SecureStorage.getUserId();
    if (token == null || userId == null) return;

    _socket?.dispose();
    _socket = io.io(
      AppConfig.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token, 'userId': userId})
          .setReconnectionAttempts(10)
          .setReconnectionDelay(2000)
          .build(),
    );
    _socket!.connect();
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  void on(String event, void Function(dynamic data) handler) {
    _socket?.on(event, handler);
  }

  void off(String event, [void Function(dynamic data)? handler]) {
    _socket?.off(event, handler);
  }

  void emit(String event, dynamic data) {
    _socket?.emit(event, data);
  }
}