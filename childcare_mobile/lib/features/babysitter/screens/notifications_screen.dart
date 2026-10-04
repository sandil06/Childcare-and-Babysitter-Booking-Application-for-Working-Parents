import 'package:flutter/material.dart';

import '../../../config/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../providers/babysitter_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final BabysitterProvider _provider = BabysitterProvider.instance;

  @override
  void initState() {
    super.initState();
    _provider.addListener(_onStateChanged);
    _provider.fetchNotifications();
  }

  @override
  void dispose() {
    _provider.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _handleRefresh() async {
    await _provider.fetchNotifications();
  }

  void _markNotificationAsRead(Map<String, dynamic> notif) async {
    final id = notif['_id']?.toString() ?? notif['id']?.toString() ?? '';
    if (id.isNotEmpty) {
      await _provider.markNotificationRead(id);
    }

    final type = notif['type']?.toString();
    if (mounted) {
      if (type == 'new_booking_request' ||
          type == 'booking_accepted' ||
          type == 'upcoming_booking_reminder') {
        Navigator.pushNamed(context, AppRoutes.sitterBookingRequests);
      } else if (type == 'payment_received') {
        Navigator.pushNamed(context, AppRoutes.sitterEarnings);
      } else if (type == 'verification_approved' ||
          type == 'verification_rejected') {
        Navigator.pushNamed(context, AppRoutes.sitterProfile);
      }
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'new_booking_request':
        return Icons.inbox_rounded;
      case 'payment_received':
        return Icons.attach_money_rounded;
      case 'verification_approved':
        return Icons.verified_rounded;
      case 'verification_rejected':
        return Icons.error_outline_rounded;
      case 'upcoming_booking_reminder':
        return Icons.alarm_rounded;
      case 'booking_cancelled':
        return Icons.cancel_outlined;
      case 'new_message':
        return Icons.chat_bubble_outline_rounded;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'payment_received':
      case 'verification_approved':
        return AppColors.teal;
      case 'upcoming_booking_reminder':
      case 'new_booking_request':
        return const Color(0xFF0284C7);
      case 'verification_rejected':
      case 'booking_cancelled':
        return AppColors.coral;
      default:
        return AppColors.ink;
    }
  }

  String _formatTime(dynamic rawDate) {
    if (rawDate == null) return 'Just now';
    final dt = DateTime.tryParse(rawDate.toString()) ?? DateTime.now();
    final diff = DateTime.now().difference(dt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.month}/${dt.day}';
  }

  @override
  Widget build(BuildContext context) {
    final notifications = _provider.notifications;
    final unreadCount = _provider.unreadNotificationCount;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const Text(
              'Notifications',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: const BoxDecoration(
                  color: AppColors.teal,
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                child: Text(
                  '$unreadCount new',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: () => _provider.markAllNotificationsRead(),
              child: const Text(
                'Mark all read',
                style: TextStyle(
                  color: AppColors.teal,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: ScrollConfiguration(
          behavior:
              ScrollConfiguration.of(context).copyWith(overscroll: false),
          child: RefreshIndicator(
            displacement: 20,
            edgeOffset: 0,
            onRefresh: _handleRefresh,
            color: AppColors.teal,
            child: notifications.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: ClampingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.all(AppSizes.pagePadding),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                    final notif = notifications[index];
                    final isRead = notif['isRead'] == true;
                    final type = notif['type']?.toString() ?? 'system';
                    final color = _getColorForType(type);
                    final icon = _getIconForType(type);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: isRead ? Colors.white : const Color(0xFFF7FAF8),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isRead
                              ? AppColors.sand.withValues(alpha: 0.6)
                              : AppColors.teal.withValues(alpha: 0.35),
                          width: isRead ? 1 : 1.3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _markNotificationAsRead(notif),
                          borderRadius: BorderRadius.circular(18),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(icon, color: color, size: 20),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              notif['title']?.toString() ?? '',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: isRead
                                                    ? FontWeight.w600
                                                    : FontWeight.w700,
                                                color: AppColors.ink,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            _formatTime(notif['createdAt']),
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.muted,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        notif['message']?.toString() ??
                                            notif['body']?.toString() ??
                                            '',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isRead
                                              ? AppColors.muted
                                              : AppColors.ink,
                                          height: 1.35,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!isRead) ...[
                                  const SizedBox(width: 10),
                                  Container(
                                    width: 8,
                                    height: 8,
                                    margin: const EdgeInsets.only(top: 6),
                                    decoration: const BoxDecoration(
                                      color: AppColors.teal,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: ClampingScrollPhysics(),
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 42,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Notifications',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'You have no new alerts. Updates regarding booking requests, messages, and payments will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.muted,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
