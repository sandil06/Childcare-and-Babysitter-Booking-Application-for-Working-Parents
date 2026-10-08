import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../network/api_client.dart';
import '../storage/local_storage.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  io.Socket? _socket;
  final ValueNotifier<bool> isConnectedNotifier = ValueNotifier<bool>(false);
  final Set<String> _activeRooms = <String>{};
  final Map<String, List<void Function(dynamic)>> _registeredHandlers = {};

  bool get isConnected => isConnectedNotifier.value;
  io.Socket? get socket => _socket;

  static String get socketUrl {
    final base = ApiClient.defaultBaseUrl;
    return base.replaceAll('/api/v1', '');
  }

  /// Initialize and connect socket with reconnect and deduplication guards
  Future<void> connect() async {
    if (_socket != null && isConnectedNotifier.value) return;

    final token = await LocalStorage.instance.read('auth_token');

    try {
      if (_socket == null) {
        _socket = io.io(
          socketUrl,
          io.OptionBuilder()
              .setTransports(['websocket', 'polling'])
              .enableAutoConnect()
              .enableReconnection()
              .setReconnectionDelay(1000)
              .setReconnectionDelayMax(5000)
              .setReconnectionAttempts(10)
              .setAuth({'token': token?.toString() ?? ''})
              .setQuery({'token': token?.toString() ?? ''})
              .build(),
        );

        _socket!.onConnect((_) {
          isConnectedNotifier.value = true;
          debugPrint('[SocketService] Connected to $socketUrl. Rejoining ${_activeRooms.length} rooms.');
          // Ensure all registered handlers are bound to the live socket connection
          _registeredHandlers.forEach((event, handlers) {
            _socket?.off(event);
            for (final handler in handlers) {
              _socket?.on(event, handler);
            }
          });
          // Automatically re-join previously active rooms upon reconnect
          for (final room in _activeRooms) {
            if (room.startsWith('conv:')) {
              _socket?.emit('join_conversation', room.replaceFirst('conv:', ''));
            } else if (room.startsWith('track:')) {
              _socket?.emit('tracking:join', room.replaceFirst('track:', ''));
            }
          }
        });

        _socket!.onDisconnect((_) {
          isConnectedNotifier.value = false;
          debugPrint('[SocketService] Disconnected from server');
        });

        _socket!.onConnectError((err) {
          isConnectedNotifier.value = false;
          debugPrint('[SocketService] Connection error: $err');
        });
      } else if (!_socket!.connected) {
        _socket!.connect();
      }
    } catch (e) {
      debugPrint('[SocketService] Initialization error: $e');
    }
  }

  /// Disconnect socket cleanly
  void disconnect() {
    _socket?.disconnect();
    _socket = null;
    isConnectedNotifier.value = false;
    _activeRooms.clear();
    _registeredHandlers.clear();
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

  /// Register event listener, safely removing old instance to avoid duplicate subscriptions
  void on(String event, void Function(dynamic) handler) {
    if (_socket != null) {
      // Remove any existing handler first to prevent duplicate callbacks
      _socket!.off(event);
      _socket!.on(event, handler);
    }
    _registeredHandlers[event] = [handler];
  }

  /// Remove event listener
  void off(String event, [void Function(dynamic)? handler]) {
    if (_socket != null) {
      if (handler != null) {
        _socket!.off(event, handler);
      } else {
        _socket!.off(event);
      }
    }
    _registeredHandlers.remove(event);
  }

  /// Helper to join a conversation room with auto-rejoin tracking
  void joinConversation(String conversationId) {
    _activeRooms.add('conv:$conversationId');
    emit('join_conversation', conversationId);
  }

  /// Helper to leave a conversation room
  void leaveConversation(String conversationId) {
    _activeRooms.remove('conv:$conversationId');
    emit('leave_conversation', conversationId);
  }

  /// Helper to join tracking room with auto-rejoin tracking
  void joinTracking(String bookingId) {
    _activeRooms.add('track:$bookingId');
    emit('tracking:join', bookingId);
  }

  /// Helper to leave tracking room
  void leaveTracking(String bookingId) {
    _activeRooms.remove('track:$bookingId');
    emit('tracking:leave', bookingId);
  }
}
