import 'package:flutter/material.dart';

import '../../../config/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../models/babysitter_model.dart';
import '../models/booking_request_model.dart';
import '../providers/babysitter_provider.dart';
import '../widgets/dashboard_stat_card.dart';

class SitterDashboardScreen extends StatefulWidget {
  const SitterDashboardScreen({super.key});

  @override
  State<SitterDashboardScreen> createState() => _SitterDashboardScreenState();
}

class _SitterDashboardScreenState extends State<SitterDashboardScreen> {
  final BabysitterProvider _provider = BabysitterProvider.instance;

  @override
  void initState() {
    super.initState();
    _provider.addListener(_onStateChanged);
    _provider.fetchDashboard();
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
    await _provider.refreshDashboard();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  void _handleQuickAccept(BookingRequestModel booking) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Accept Booking Request?',
          style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to accept the booking for ${booking.parentName} on ${booking.timeFormatted}?',
          style: const TextStyle(color: AppColors.muted, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.muted),
            ),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await _provider.acceptBooking(booking.id);
              if (mounted && ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Booking accepted! Moved to Upcoming Bookings.',
                    ),
                    backgroundColor: AppColors.teal,
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.teal,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Accept Booking'),
          ),
        ],
      ),
    );
  }

  void _handleQuickReject(BookingRequestModel booking) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Decline Booking Request?',
          style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'This request will be declined and the parent will be notified to find another sitter.',
          style: TextStyle(color: AppColors.muted, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.muted),
            ),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await _provider.rejectBooking(booking.id);
              if (mounted && ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Booking request declined.'),
                    backgroundColor: AppColors.ink,
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.coral,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Decline'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile =
        _provider.profile ??
        const BabysitterModel(
          id: 'temp',
          userId: 'u-temp',
          name: 'Maya Johnson',
          email: 'maya.johnson@example.com',
        );

    final upcoming = _provider.upcomingBookings;
    final upcomingBooking = upcoming.isNotEmpty ? upcoming.first : null;
    final newRequests = _provider.newRequests;
    final unreadNotifs = _provider.unreadNotificationCount;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: AppColors.teal,
          child: ListView(
            key: const PageStorageKey<String>('sitter_dashboard_scroll'),
            padding: const EdgeInsets.fromLTRB(
              AppSizes.pagePadding,
              16,
              AppSizes.pagePadding,
              32,
            ),
            children: [
              if (_provider.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDE8E8),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.coral.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: AppColors.coral,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _provider.errorMessage!,
                          style: const TextStyle(
                            color: AppColors.coral,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.refresh_rounded,
                          size: 18,
                          color: AppColors.coral,
                        ),
                        onPressed: _handleRefresh,
                        tooltip: 'Retry',
                      ),
                    ],
                  ),
                ),
              ],
              // Header
              _buildHeader(profile, unreadNotifs),
              const SizedBox(height: 20),

              // Availability Toggle Card
              _buildAvailabilityCard(profile),
              const SizedBox(height: 20),

              // Summary Stats Cards
              _buildSummaryStats(profile),
              const SizedBox(height: 24),

              // Quick Actions
              _buildQuickActions(),
              const SizedBox(height: 28),

              // Upcoming Booking Card
              _buildUpcomingSection(upcomingBooking),
              const SizedBox(height: 28),

              // New Booking Requests Section
              _buildNewRequestsSection(newRequests),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        backgroundColor: Colors.white,
        elevation: 4,
        indicatorColor: AppColors.mint,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              break; // already on dashboard
            case 1:
              Navigator.pushNamed(context, AppRoutes.sitterBookingRequests);
              break;
            case 2:
              Navigator.pushNamed(context, AppRoutes.sitterAvailability);
              break;
            case 3:
              Navigator.pushNamed(context, AppRoutes.sitterEarnings);
              break;
            case 4:
              Navigator.pushNamed(context, AppRoutes.sitterProfile);
              break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded, color: AppColors.teal),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(
              Icons.calendar_today_rounded,
              color: AppColors.teal,
            ),
            label: 'Bookings',
          ),
          NavigationDestination(
            icon: Icon(Icons.access_time_rounded),
            selectedIcon: Icon(
              Icons.access_time_filled_rounded,
              color: AppColors.teal,
            ),
            label: 'Availability',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(
              Icons.account_balance_wallet_rounded,
              color: AppColors.teal,
            ),
            label: 'Earnings',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded, color: AppColors.teal),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BabysitterModel profile, int unreadCount) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, AppRoutes.sitterProfile),
          child: CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.mint,
            child: Text(
              profile.name.isNotEmpty
                  ? profile.name
                        .split(' ')
                        .map((e) => e.isNotEmpty ? e[0] : '')
                        .take(2)
                        .join()
                  : 'MJ',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.teal,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_getGreeting()},',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Row(
                children: [
                  Text(
                    profile.name,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.verified_rounded,
                    size: 16,
                    color: AppColors.teal,
                  ),
                ],
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(
            Icons.swap_horiz_rounded,
            color: AppColors.ink,
            size: 24,
          ),
          tooltip: 'Switch to Parent Mode',
          onPressed: () => Navigator.pushNamed(context, AppRoutes.home),
        ),
        // Notifications Icon
        Stack(
          children: [
            IconButton(
              icon: const Icon(
                Icons.notifications_none_rounded,
                color: AppColors.ink,
                size: 26,
              ),
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.sitterNotifications),
            ),
            if (unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.coral,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildAvailabilityCard(BabysitterModel profile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: profile.isAvailable
              ? AppColors.teal.withValues(alpha: 0.3)
              : AppColors.sand,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: profile.isAvailable ? AppColors.teal : AppColors.muted,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.isAvailable
                      ? 'Available for Bookings'
                      : 'Unavailable for New Requests',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  profile.isAvailable
                      ? 'You are active and visible to local families.'
                      : 'Toggle on when you are ready to accept jobs.',
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
          Switch(
            value: profile.isAvailable,
            activeTrackColor: AppColors.teal,
            onChanged: (val) => _provider.toggleAvailability(val),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStats(BabysitterModel profile) {
    final earnings =
        (_provider.dashboardData?['stats']?['totalEarnings'] as num?)
            ?.toDouble() ??
        0.0;
    return Row(
      children: [
        Expanded(
          child: DashboardStatCard(
            title: 'Earnings',
            value: '\$${earnings.toInt()}',
            subtitle: 'Lifetime gross',
            icon: Icons.account_balance_wallet_outlined,
            accentColor: AppColors.teal,
            onTap: () => Navigator.pushNamed(context, AppRoutes.sitterEarnings),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: DashboardStatCard(
            title: 'Rating',
            value: '★ ${profile.averageRating}',
            subtitle: '${profile.totalReviews} reviews',
            icon: Icons.star_rounded,
            accentColor: AppColors.coral,
            onTap: () => Navigator.pushNamed(context, AppRoutes.sitterProfile),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: DashboardStatCard(
            title: 'Jobs Done',
            value: '${profile.totalCompletedBookings}',
            subtitle: 'Completed',
            icon: Icons.task_alt_rounded,
            accentColor: AppColors.ink,
            onTap: () =>
                Navigator.pushNamed(context, AppRoutes.sitterBookingHistory),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildActionItem(
              icon: Icons.inbox_outlined,
              label: 'Requests',
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.sitterBookingRequests),
            ),
            _buildActionItem(
              icon: Icons.calendar_month_outlined,
              label: 'Availability',
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.sitterAvailability),
            ),
            _buildActionItem(
              icon: Icons.trending_up_rounded,
              label: 'Earnings',
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.sitterEarnings),
            ),
            _buildActionItem(
              icon: Icons.chat_bubble_outline_rounded,
              label: 'Messages',
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.sitterMessages),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 76,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.sand.withValues(alpha: 0.8)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.cream,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.teal, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingSection(BookingRequestModel? booking) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Upcoming Booking',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(
                context,
                AppRoutes.sitterUpcomingBookings,
              ),
              child: const Text(
                'View all',
                style: TextStyle(color: AppColors.teal),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (booking == null)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  color: AppColors.teal,
                  size: 28,
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'No bookings scheduled for today. You are all caught up!',
                    style: TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.mint, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.sand,
                          child: Text(
                            booking.parentName.isNotEmpty
                                ? booking.parentName[0]
                                : 'P',
                            style: const TextStyle(
                              color: AppColors.ink,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              booking.parentName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                            Text(
                              '${booking.childCount} Child (${booking.childrenDetails.isNotEmpty ? booking.childrenDetails.first.name : 'Toddler'})',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.mint,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        booking.status.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.teal,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 22, color: AppColors.sand),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 16,
                      color: AppColors.teal,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      booking.timeFormatted,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '\$${booking.totalAmount.toInt()}.00',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: AppColors.muted,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        booking.location,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          _provider.selectBooking(booking);
                          Navigator.pushNamed(
                            context,
                            AppRoutes.sitterBookingRequestDetails,
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.ink,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('View Booking Details'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildNewRequestsSection(List<BookingRequestModel> requests) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  'New Requests',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                if (requests.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.coral,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      requests.length.toString(),
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
            TextButton(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.sitterBookingRequests),
              child: const Text(
                'View all',
                style: TextStyle(color: AppColors.teal),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (requests.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              children: [
                Icon(Icons.inbox_rounded, color: AppColors.muted, size: 26),
                SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'No pending booking requests right now.',
                    style: TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                ),
              ],
            ),
          )
        else
          ...requests.map((req) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        req.parentName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        '\$${req.totalAmount.toInt()}.00',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.teal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${req.timeFormatted} (${req.durationHours.toInt()} hrs) · ${req.location}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (req.specialNotes != null &&
                      req.specialNotes!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      '"${req.specialNotes}"',
                      style: const TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: AppColors.ink,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _handleQuickReject(req),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.coral,
                            side: const BorderSide(color: AppColors.coral),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Decline'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => _handleQuickAccept(req),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.teal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Accept'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}
