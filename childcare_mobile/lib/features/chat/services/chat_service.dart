import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/local_storage.dart';
import '../models/message_model.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final ApiClient _client = ApiClient();

  Future<void> _ensureAuthToken() async {
    final token = await LocalStorage.instance.read('auth_token');
    if (token != null && token.toString().isNotEmpty) {
      ApiClient.authToken = token.toString();
    }
  }

  /// Retrieves all conversations for current user
  Future<List<ConversationModel>> getConversations() async {
    await _ensureAuthToken();

    try {
      dynamic res;
      try {
        res = await _client.get('conversations');
      } catch (_) {
        res = await _client.get('messages/conversations');
      }

      if (res is Map && res['data'] is List) {
        return (res['data'] as List)
            .map((item) => ConversationModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      } else if (res is List) {
        return res
            .map((item) => ConversationModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }
    } catch (e) {
      debugPrint('[ChatService] getConversations error: $e');
    }

    // Default mock list for offline mode
    return [
      ConversationModel(
        id: 'conv-1',
        otherUserId: 'sitter-1',
        otherUserName: 'Amaya Fernando',
        otherUserAvatar: null,
        otherUserRole: 'babysitter',
        lastMessage: 'Hello! I will be arriving 10 minutes early.',
        lastMessageAt: DateTime.now().subtract(const Duration(minutes: 15)),
        unreadCount: 1,
      ),
      ConversationModel(
        id: 'conv-2',
        otherUserId: 'sitter-2',
        otherUserName: 'Dilani Perera',
        otherUserAvatar: null,
        otherUserRole: 'babysitter',
        lastMessage: 'Thank you for the wonderful booking review!',
        lastMessageAt: DateTime.now().subtract(const Duration(hours: 3)),
        unreadCount: 0,
      ),
    ];
  }

  /// Initiates or retrieves an existing conversation with a babysitter / parent
  Future<ConversationModel> getOrCreateConversation({
    required String recipientId,
    String? bookingId,
  }) async {
    await _ensureAuthToken();

    try {
      final res = await _client.post('conversations', body: {
        'recipientId': recipientId,
        'bookingId': ?bookingId,
      });

      if (res is Map && res['data'] != null) {
        return ConversationModel.fromJson(Map<String, dynamic>.from(res['data'] as Map));
      }
    } catch (e) {
      debugPrint('[ChatService] getOrCreateConversation error: $e');
    }

    return ConversationModel(
      id: 'conv-${DateTime.now().millisecondsSinceEpoch}',
      otherUserId: recipientId,
      otherUserName: 'Caregiver',
      lastMessage: '',
      lastMessageAt: DateTime.now(),
      bookingId: bookingId,
    );
  }

  /// Retrieves messages inside a conversation
  Future<List<MessageModel>> getMessages(
    String conversationId, {
    int page = 1,
    int limit = 40,
  }) async {
    await _ensureAuthToken();

    try {
      dynamic res;
      try {
        res = await _client.get('conversations/$conversationId/messages', queryParams: {
          'page': page,
          'limit': limit,
        });
      } catch (_) {
        res = await _client.get('messages/$conversationId');
      }

      if (res is Map && res['data'] is List) {
        return (res['data'] as List)
            .map((item) => MessageModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      } else if (res is List) {
        return res
            .map((item) => MessageModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }
    } catch (e) {
      debugPrint('[ChatService] getMessages error: $e');
    }

    return [];
  }

  /// Sends a new message in the conversation
  Future<MessageModel?> sendMessage({
    required String conversationId,
    required String text,
    String? recipientId,
  }) async {
    await _ensureAuthToken();

    try {
      dynamic res;
      try {
        res = await _client.post('conversations/$conversationId/messages', body: {
          'text': text,
          'recipientId': ?recipientId,
        });
      } catch (_) {
        res = await _client.post('messages', body: {
          'conversationId': conversationId,
          'text': text,
          'recipientId': ?recipientId,
        });
      }

      if (res is Map && res['data'] != null) {
        return MessageModel.fromJson(Map<String, dynamic>.from(res['data'] as Map));
      }
    } catch (e) {
      debugPrint('[ChatService] sendMessage error: $e');
    }

    return MessageModel(
      id: 'm-${DateTime.now().millisecondsSinceEpoch}',
      conversationId: conversationId,
      senderId: 'me',
      text: text,
      createdAt: DateTime.now(),
    );
  }

  /// Marks conversation as read
  Future<void> markAsRead(String conversationId) async {
    await _ensureAuthToken();

    try {
      await _client.patch('conversations/$conversationId/read');
    } catch (_) {
      try {
        await _client.patch('messages/$conversationId/read');
      } catch (e) {
        debugPrint('[ChatService] markAsRead error: $e');
      }
    }
  }
}
