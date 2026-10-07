import 'dart:async';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/storage/local_storage.dart';
import '../models/message_model.dart';
import '../services/chat_service.dart';
import '../services/chat_socket_service.dart';

class ChatScreen extends StatefulWidget {
  final ConversationModel? conversation;
  final String? conversationId;
  final String? otherUserId;
  final String? otherUserName;

  const ChatScreen({
    super.key,
    this.conversation,
    this.conversationId,
    this.otherUserId,
    this.otherUserName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  final ChatSocketService _socketService = ChatSocketService();

  List<MessageModel> _messages = [];
  bool _isLoading = true;
  String _currentUserId = 'me';
  late String _convId;
  late String _otherId;
  late String _otherName;

  bool _isOtherTyping = false;
  String _typingUserName = '';
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _convId = widget.conversation?.id ?? widget.conversationId ?? 'conv-1';
    _otherId = widget.conversation?.otherUserId ?? widget.otherUserId ?? 'sitter-1';
    _otherName = widget.conversation?.otherUserName ?? widget.otherUserName ?? 'Caregiver';

    _initChat();
    _textController.addListener(_onTextChanged);
  }

  Future<void> _initChat() async {
    final storedUserId = await LocalStorage.instance.read('user_id');
    if (storedUserId != null) {
      _currentUserId = storedUserId.toString();
    }

    // 1. Fetch initial message history
    try {
      final history = await _chatService.getMessages(_convId);
      if (mounted) {
        setState(() {
          _messages = history;
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }

    // 2. Connect to Socket.IO real-time stream
    _socketService.joinConversation(
      conversationId: _convId,
      onNewMessage: (newMsg) {
        if (!mounted) return;
        setState(() {
          // Avoid duplicate insertion
          if (!_messages.any((m) => m.id == newMsg.id)) {
            _messages.add(newMsg);
          }
        });
        _scrollToBottom();
        _socketService.sendReadReceipt(_convId, newMsg.id);
      },
      onTyping: (userName, isTyping) {
        if (!mounted) return;
        setState(() {
          _isOtherTyping = isTyping;
          _typingUserName = userName;
        });
      },
    );

    // 3. Mark conversation read
    _chatService.markAsRead(_convId);
  }

  void _onTextChanged() {
    if (_textController.text.trim().isNotEmpty) {
      _socketService.sendTypingStart(_convId, 'Parent');
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(seconds: 2), () {
        _socketService.sendTypingStop(_convId);
      });
    } else {
      _socketService.sendTypingStop(_convId);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    _socketService.sendTypingStop(_convId);

    final localMsg = MessageModel(
      id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
      conversationId: _convId,
      senderId: _currentUserId,
      receiverId: _otherId,
      text: text,
      status: 'sent',
      createdAt: DateTime.now(),
    );

    setState(() {
      _messages.add(localMsg);
    });
    _scrollToBottom();

    // Send via Socket with REST fallback
    _socketService.sendMessage(
      conversationId: _convId,
      text: text,
      recipientId: _otherId,
      onAck: (savedMsg) {
        if (!mounted) return;
        setState(() {
          final idx = _messages.indexWhere((m) => m.id == localMsg.id);
          if (idx != -1) {
            _messages[idx] = savedMsg;
          }
        });
      },
    );

    // Fallback REST call to ensure persistence
    _chatService.sendMessage(
      conversationId: _convId,
      text: text,
      recipientId: _otherId,
    );
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _scrollController.dispose();
    _socketService.leaveConversation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Check if arguments passed via Navigator
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      if (args['conversationId'] != null) _convId = args['conversationId'].toString();
      if (args['otherUserId'] != null) _otherId = args['otherUserId'].toString();
      if (args['otherUserName'] != null) _otherName = args['otherUserName'].toString();
    }

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.ink, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 19,
                  backgroundColor: const Color(0xFFE6F5F2),
                  child: Text(
                    _otherName.isNotEmpty ? _otherName[0].toUpperCase() : 'C',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF005B60),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          _otherName,
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.verified, size: 14, color: AppColors.teal),
                    ],
                  ),
                  Text(
                    _isOtherTyping
                        ? '${_typingUserName.isNotEmpty ? _typingUserName : _otherName} is typing...'
                        : 'Active now',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: _isOtherTyping ? AppColors.teal : AppColors.muted,
                      fontWeight: _isOtherTyping ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone_outlined, color: AppColors.ink, size: 22),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Calling $_otherName...'),
                  backgroundColor: AppColors.teal,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Messages list
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.teal),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        final isMe = msg.isMe(_currentUserId);
                        return _buildMessageBubble(msg, isMe);
                      },
                    ),
            ),

            // Typing indicator banner (if typing)
            if (_isOtherTyping)
              Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 20, bottom: 8),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.teal),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$_otherName is typing...',
                      style: const TextStyle(fontSize: 12, color: AppColors.muted, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),

            // Composer bar
            _buildComposerBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.76,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF005B60) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              msg.text,
              style: TextStyle(
                color: isMe ? Colors.white : AppColors.ink,
                fontSize: 14.5,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  msg.formattedTime,
                  style: TextStyle(
                    color: isMe ? Colors.white70 : AppColors.muted,
                    fontSize: 10.5,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.done_all_rounded,
                    size: 14,
                    color: Colors.white70,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComposerBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            offset: const Offset(0, -3),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: AppColors.cream,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.add_photo_alternate_outlined, color: AppColors.teal, size: 21),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Photo attachments available'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _textController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Write a message...',
                hintStyle: const TextStyle(color: AppColors.muted, fontSize: 14),
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF005B60),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 19),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}
