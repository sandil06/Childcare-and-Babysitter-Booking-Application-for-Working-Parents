import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../network/api_client.dart';
import '../storage/local_storage.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  io.Socket? _socket;
  bool _isConnected = false;

  bool get isConnected => _isConnected;
  io.Socket? get socket => _socket;

  static String get socketUrl {
    final base = ApiClient.defaultBaseUrl;
    return base.replaceAll('/api/v1', '');
  }

  /// Initialize and connect socket
  Future<void> connect() async {
    if (_socket != null && _isConnected) return;

    final token = await LocalStorage.instance.read('auth_token');

    try {
      _socket = io.io(
        socketUrl,
        io.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionDelay(1000)
            .setReconnectionDelayMax(5000)
            .setReconnectionAttempts(5)
            .setAuth({'token': token?.toString() ?? ''})
            .setQuery({'token': token?.toString() ?? ''})
            .build(),
      );

      _socket!.onConnect((_) {
        _isConnected = true;
        debugPrint('[SocketService] Connected to $socketUrl');
      });

      _socket!.onDisconnect((_) {
        _isConnected = false;
        debugPrint('[SocketService] Disconnected');
      });

      _socket!.onConnectError((err) {
        _isConnected = false;
        debugPrint('[SocketService] Connect error: $err');
      });
    } catch (e) {
      debugPrint('[SocketService] Initialization error: $e');
    }
  }

  /// Disconnect socket
  void disconnect() {
    _socket?.disconnect();
    _socket = null;
    _isConnected = false;
  }

  /// Emit event to server with optional ack callback
  void emit(String event, dynamic data, [dynamic Function(dynamic)? ack]) {
    if (_socket == null) {
      connect().then((_) {
        if (ack != null) {
          _socket?.emitWithAck(event, data, ack: ack);
        } else {
          _socket?.emit(event, data);
        }
      });
      return;
    }

    if (ack != null) {
      _socket?.emitWithAck(event, data, ack: ack);
    } else {
      _socket?.emit(event, data);
    }
  }

  /// Register event listener
  void on(String event, void Function(dynamic) handler) {
    _socket?.on(event, handler);
  }

  /// Remove event listener
  void off(String event, [void Function(dynamic)? handler]) {
    if (handler != null) {
      _socket?.off(event, handler);
    } else {
      _socket?.off(event);
    }
  }

  /// Helper to join a conversation room
  void joinConversation(String conversationId) {
    emit('join_conversation', conversationId);
  }

  /// Helper to leave a conversation room
  void leaveConversation(String conversationId) {
    emit('leave_conversation', conversationId);
  }
}
