class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String? receiverId;
  final String text;
  final String type; // 'text', 'image', 'system', 'location'
  final String status; // 'sent', 'delivered', 'read'
  final DateTime createdAt;
  final DateTime? readAt;

  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.senderName = '',
    this.receiverId,
    required this.text,
    this.type = 'text',
    this.status = 'sent',
    required this.createdAt,
    this.readAt,
  });

  bool isMe(String currentUserId) => senderId == currentUserId;

  String get formattedTime {
    final h = createdAt.hour.toString().padLeft(2, '0');
    final m = createdAt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    String senderIdStr = '';
    String senderNameStr = '';
    if (json['sender'] is Map) {
      senderIdStr = (json['sender']['_id'] ?? json['sender']['id'] ?? '').toString();
      senderNameStr = (json['sender']['name'] ?? '').toString();
    } else {
      senderIdStr = (json['sender'] ?? json['senderId'] ?? '').toString();
      senderNameStr = (json['senderName'] ?? '').toString();
    }

    String convIdStr = '';
    if (json['conversation'] is Map) {
      convIdStr = (json['conversation']['_id'] ?? json['conversation']['id'] ?? '').toString();
    } else {
      convIdStr = (json['conversation'] ?? json['conversationId'] ?? '').toString();
    }

    return MessageModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      conversationId: convIdStr,
      senderId: senderIdStr,
      senderName: senderNameStr,
      receiverId: json['receiver']?.toString() ?? json['receiverId']?.toString(),
      text: (json['text'] ?? '').toString(),
      type: (json['type'] ?? 'text').toString(),
      status: (json['status'] ?? 'sent').toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      readAt: json['readAt'] != null ? DateTime.tryParse(json['readAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'conversation': conversationId,
    'sender': senderId,
    'senderName': senderName,
    'receiver': receiverId,
    'text': text,
    'type': type,
    'status': status,
    'createdAt': createdAt.toIso8601String(),
    'readAt': readAt?.toIso8601String(),
  };
}

class ConversationModel {
  final String id;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserAvatar;
  final String otherUserRole;
  final String lastMessage;
  final DateTime lastMessageAt;
  final int unreadCount;
  final String? bookingId;

  const ConversationModel({
    required this.id,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatar,
    this.otherUserRole = 'babysitter',
    required this.lastMessage,
    required this.lastMessageAt,
    this.unreadCount = 0,
    this.bookingId,
  });

  String get relativeTime {
    final diff = DateTime.now().difference(lastMessageAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${lastMessageAt.day} ${months[lastMessageAt.month - 1]}';
  }

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    final idStr = (json['_id'] ?? json['id'] ?? '').toString();
    String otherId = (json['otherUserId'] ?? json['parentId'] ?? '').toString();
    String otherName = (json['otherUserName'] ?? json['parentName'] ?? 'Caregiver').toString();
    String? otherAvatar = json['otherUserAvatar'] ?? json['parentAvatar'];
    String otherRole = (json['otherUserRole'] ?? 'babysitter').toString();

    if (json['otherUser'] is Map) {
      final u = json['otherUser'] as Map;
      otherId = (u['_id'] ?? u['id'] ?? otherId).toString();
      otherName = (u['name'] ?? otherName).toString();
      otherAvatar = u['avatar']?.toString() ?? otherAvatar;
      otherRole = (u['role'] ?? otherRole).toString();
    } else if (json['parent'] is Map) {
      final p = json['parent'] as Map;
      otherId = (p['_id'] ?? p['id'] ?? otherId).toString();
      otherName = (p['name'] ?? otherName).toString();
      otherAvatar = p['avatar']?.toString() ?? otherAvatar;
    }

    final bookingIdStr = json['bookingId'] is Map
        ? json['bookingId']['_id']?.toString()
        : json['bookingId']?.toString();

    return ConversationModel(
      id: idStr,
      otherUserId: otherId,
      otherUserName: otherName,
      otherUserAvatar: otherAvatar,
      otherUserRole: otherRole,
      lastMessage: (json['lastMessage'] ?? '').toString(),
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.tryParse(json['lastMessageAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      unreadCount: (json['unreadCount'] is num) ? (json['unreadCount'] as num).toInt() : 0,
      bookingId: bookingIdStr,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'otherUserId': otherUserId,
    'otherUserName': otherUserName,
    'otherUserAvatar': otherUserAvatar,
    'otherUserRole': otherUserRole,
    'lastMessage': lastMessage,
    'lastMessageAt': lastMessageAt.toIso8601String(),
    'unreadCount': unreadCount,
    'bookingId': bookingId,
  };
}
