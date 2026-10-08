import 'package:flutter/foundation.dart';

import '../../../core/services/socket_service.dart';
import '../models/message_model.dart';

class ChatSocketService {
  final SocketService _socket = SocketService();
  String? _currentConversationId;

  void Function(MessageModel message)? _messageHandler;
  void Function(String userName, bool isTyping)? _typingHandler;

  /// Connects and joins a specific conversation room
  void joinConversation({
    required String conversationId,
    required void Function(MessageModel) onNewMessage,
    void Function(String userName, bool isTyping)? onTyping,
  }) {
    _currentConversationId = conversationId;
    _messageHandler = onNewMessage;
    _typingHandler = onTyping;

    _socket.connect().then((_) {
      _socket.joinConversation(conversationId);

      _socket.on('receive_message', _handleReceiveMessage);

      _socket.on('typing_start', (data) {
        if (data is Map && data['conversationId'] == conversationId) {
          final name = data['userName']?.toString() ?? 'User';
          _typingHandler?.call(name, true);
        }
      });

      _socket.on('typing_stop', (data) {
        if (data is Map && data['conversationId'] == conversationId) {
          _typingHandler?.call('', false);
        }
      });
    });
  }

  void _handleReceiveMessage(dynamic data) {
    try {
      if (data is Map) {
        Map<String, dynamic> msgMap = {};
        if (data['message'] is Map) {
          msgMap = Map<String, dynamic>.from(data['message'] as Map);
        } else {
          msgMap = Map<String, dynamic>.from(data);
        }

        final msg = MessageModel.fromJson(msgMap);
        _messageHandler?.call(msg);
      }
    } catch (e) {
      debugPrint('[ChatSocketService] parse incoming message error: $e');
    }
  }

  /// Sends a message via Socket.IO
  void sendMessage({
    required String conversationId,
    required String text,
    String? recipientId,
    Function(MessageModel)? onAck,
  }) {
    _socket.emit('send_message', {
      'conversationId': conversationId,
      'text': text,
      'recipientId': recipientId,
    }, (response) {
      if (response is Map && response['success'] == true && response['message'] != null) {
        final saved = MessageModel.fromJson(Map<String, dynamic>.from(response['message'] as Map));
        onAck?.call(saved);
      }
    });
  }

  /// Sends typing start
  void sendTypingStart(String conversationId, String userName) {
    _socket.emit('typing_start', {
      'conversationId': conversationId,
      'userName': userName,
    });
  }

  /// Sends typing stop
  void sendTypingStop(String conversationId) {
    _socket.emit('typing_stop', {
      'conversationId': conversationId,
    });
  }

  /// Sends message read receipt
  void sendReadReceipt(String conversationId, String? messageId) {
    _socket.emit('message_read', {
      'conversationId': conversationId,
      'messageId': messageId,
    });
  }

  /// Clean up listeners and leave room
  void leaveConversation() {
    if (_currentConversationId != null) {
      _socket.leaveConversation(_currentConversationId!);
      _socket.off('receive_message');
      _socket.off('typing_start');
      _socket.off('typing_stop');
      _currentConversationId = null;
    }
    _messageHandler = null;
    _typingHandler = null;
  }
}
