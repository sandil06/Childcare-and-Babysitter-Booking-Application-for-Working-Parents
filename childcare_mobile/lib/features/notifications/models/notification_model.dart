import 'package:flutter/material.dart';

class AppNotificationModel {
  final String id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic> data;

  const AppNotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.isRead = false,
    required this.createdAt,
    this.data = const {},
  });

  String get relativeTime {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${createdAt.day} ${months[createdAt.month - 1]}';
  }

  String get category {
    if (type == 'new_message') return 'messages';
    if ([
      'new_booking_request',
      'booking_accepted',
      'booking_rejected',
      'booking_cancelled',
      'booking_rescheduled',
      'booking_confirmed',
      'upcoming_booking_reminder',
      'payment_received',
      'travelling',
      'arrived',
      'in_progress',
      'completed',
    ].contains(type)) {
      return 'bookings';
    }
    return 'system';
  }

  IconData get iconData {
    switch (type) {
      case 'new_message':
        return Icons.chat_bubble_outline_rounded;
      case 'payment_received':
        return Icons.account_balance_wallet_outlined;
      case 'booking_accepted':
      case 'booking_confirmed':
        return Icons.check_circle_outline_rounded;
      case 'booking_cancelled':
      case 'booking_rejected':
        return Icons.cancel_outlined;
      case 'booking_rescheduled':
        return Icons.update_rounded;
      case 'travelling':
        return Icons.directions_car_outlined;
      case 'arrived':
        return Icons.home_outlined;
      case 'in_progress':
        return Icons.play_circle_outline_rounded;
      case 'completed':
        return Icons.task_alt_rounded;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  Color get iconColor {
    switch (type) {
      case 'booking_accepted':
      case 'booking_confirmed':
      case 'completed':
        return const Color(0xFF166534);
      case 'payment_received':
        return const Color(0xFF005B60);
      case 'new_message':
        return const Color(0xFF0369A1);
      case 'booking_cancelled':
      case 'booking_rejected':
        return const Color(0xFFB91C1C);
      case 'booking_rescheduled':
      case 'travelling':
        return const Color(0xFFD97706);
      default:
        return const Color(0xFF475569);
    }
  }

  Color get iconBgColor {
    switch (type) {
      case 'booking_accepted':
      case 'booking_confirmed':
      case 'completed':
        return const Color(0xFFDCFCE7);
      case 'payment_received':
        return const Color(0xFFE6F5F2);
      case 'new_message':
        return const Color(0xFFE0F2FE);
      case 'booking_cancelled':
      case 'booking_rejected':
        return const Color(0xFFFEE2E2);
      case 'booking_rescheduled':
      case 'travelling':
        return const Color(0xFFFEF3C7);
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) {
    return AppNotificationModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      title: (json['title'] ?? 'Notification').toString(),
      message: (json['message'] ?? '').toString(),
      type: (json['type'] ?? 'system').toString(),
      isRead: json['isRead'] == true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      data: json['data'] is Map ? Map<String, dynamic>.from(json['data'] as Map) : {},
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'message': message,
    'type': type,
    'isRead': isRead,
    'createdAt': createdAt.toIso8601String(),
    'data': data,
  };
}
