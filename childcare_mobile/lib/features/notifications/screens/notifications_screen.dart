import 'package:flutter/material.dart';

import '../../../config/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _service = NotificationService();
  late final ScrollController _scrollController;
  List<AppNotificationModel> _notifications = [];
  bool _isInitialLoading = true;
  bool _isRefreshing = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  static const int _limit = 15;
  String _selectedCategory = 'all'; // 'all', 'bookings', 'messages'

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    _loadNotifications(isInitial: true);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 300) {
      _loadMore();
    }
  }

  Future<void> _loadNotifications({bool isInitial = false, bool isRefresh = false}) async {
    if (isInitial) {
      setState(() => _isInitialLoading = true);
    } else if (isRefresh) {
      setState(() => _isRefreshing = true);
    }

    try {
      _currentPage = 1;
      final list = await _service.getNotifications(
        category: _selectedCategory,
        page: _currentPage,
        limit: _limit,
      );
      if (mounted) {
        setState(() {
          _notifications = list;
          _hasMore = list.length >= _limit;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore || _isInitialLoading || _isRefreshing) {
      return;
    }

    setState(() => _isLoadingMore = true);
    try {
      final nextPage = _currentPage + 1;
      final list = await _service.getNotifications(
        category: _selectedCategory,
        page: nextPage,
        limit: _limit,
      );
      if (mounted) {
        setState(() {
          _currentPage = nextPage;
          _notifications.addAll(list);
          _hasMore = list.length >= _limit;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  int get _unreadCount {
    return _notifications.where((n) => !n.isRead).length;
  }

  Future<void> _handleMarkAllRead() async {
    await _service.markAllRead();
    setState(() {
      _notifications = _notifications
          .map((n) => AppNotificationModel(
                id: n.id,
                title: n.title,
                message: n.message,
                type: n.type,
                isRead: true,
                createdAt: n.createdAt,
                data: n.data,
              ))
          .toList();
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All notifications marked as read'),
          backgroundColor: AppColors.teal,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleNotificationTap(AppNotificationModel notif) async {
    if (!notif.isRead) {
      _service.markNotificationRead(notif.id);
      setState(() {
        final idx = _notifications.indexWhere((n) => n.id == notif.id);
        if (idx != -1) {
          _notifications[idx] = AppNotificationModel(
            id: notif.id,
            title: notif.title,
            message: notif.message,
            type: notif.type,
            isRead: true,
            createdAt: notif.createdAt,
            data: notif.data,
          );
        }
      });
    }

    if (notif.category == 'bookings') {
      Navigator.pushNamed(context, AppRoutes.parentUpcomingBookings);
    } else if (notif.category == 'messages') {
      Navigator.pushNamed(context, AppRoutes.parentMessages);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.ink, size: 20),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Notifications',
              style: TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            if (_unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF005B60),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$_unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (_notifications.any((n) => !n.isRead))
            TextButton(
              onPressed: _handleMarkAllRead,
              child: const Text(
                'Mark all read',
                style: TextStyle(
                  color: Color(0xFF005B60),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs (All, Bookings, Messages)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Row(
              children: [
                _buildFilterChip('all', 'All'),
                const SizedBox(width: 8),
                _buildFilterChip('bookings', 'Bookings'),
                const SizedBox(width: 8),
                _buildFilterChip('messages', 'Messages'),
              ],
            ),
          ),

          // Notifications List
          Expanded(
            child: _isInitialLoading && _notifications.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.teal),
                  )
                : RefreshIndicator(
                    onRefresh: () => _loadNotifications(isRefresh: true),
                    color: AppColors.teal,
                    child: _notifications.isEmpty
                        ? _buildEmptyState()
                        : ListView.separated(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: ClampingScrollPhysics(),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            itemCount: _notifications.length + (_isLoadingMore ? 1 : 0),
                            separatorBuilder: (_, index) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              if (index == _notifications.length) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.teal,
                                      ),
                                    ),
                                  ),
                                );
                              }
                              final notif = _notifications[index];
                              return _buildNotificationCard(notif);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String category, String label) {
    final isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () {
        if (_selectedCategory != category) {
          setState(() => _selectedCategory = category);
          _loadNotifications();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF005B60) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.muted,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(AppNotificationModel notif) {
    return GestureDetector(
      onTap: () => _handleNotificationTap(notif),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: notif.isRead ? Colors.white : const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(AppSizes.radius),
          border: Border.all(
            color: notif.isRead ? const Color(0xFFE2E8F0) : const Color(0xFF86EFAC),
            width: notif.isRead ? 1 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon Container
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: notif.iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(notif.iconData, color: notif.iconColor, size: 22),
          ),
          const SizedBox(width: 14),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        notif.title,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.w800,
                          color: AppColors.ink,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      notif.relativeTime,
                      style: const TextStyle(fontSize: 11, color: AppColors.muted),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  notif.message,
                  style: TextStyle(
                    fontSize: 13,
                    color: notif.isRead ? AppColors.muted : const Color(0xFF1E293B),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),

          // Unread Indicator Dot
          if (!notif.isRead) ...[
            const SizedBox(width: 8),
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF005B60),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

  Widget _buildEmptyState() {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE6F5F2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_off_outlined,
                      color: Color(0xFF005B60),
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No notifications',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'You have no notifications in this category. Important booking updates will appear here.',
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
          ),
        ),
      ),
    );
  }
}
