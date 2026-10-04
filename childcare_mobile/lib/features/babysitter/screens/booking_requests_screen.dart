import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../models/booking_request_model.dart';
import '../providers/babysitter_provider.dart';
import '../widgets/booking_request_card.dart';
import 'booking_request_details_screen.dart';

class BookingRequestsScreen extends StatefulWidget {
  const BookingRequestsScreen({super.key});

  @override
  State<BookingRequestsScreen> createState() => _BookingRequestsScreenState();
}

class _BookingRequestsScreenState extends State<BookingRequestsScreen>
    with SingleTickerProviderStateMixin {
  final BabysitterProvider _provider = BabysitterProvider.instance;
  late TabController _tabController;

  final List<String> _tabs = [
    'New Requests',
    'Accepted',
    'Upcoming',
    'Completed',
    'Cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _provider.addListener(_onStateChanged);
    _provider.fetchBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _provider.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _handleRefresh() async {
    await _provider.fetchBookings();
  }

  void _openDetails(BookingRequestModel booking) {
    _provider.selectBooking(booking);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingRequestDetailsScreen(booking: booking),
      ),
    );
  }

  void _quickAccept(BookingRequestModel booking) async {
    final ok = await _provider.acceptBooking(booking.id);
    if (mounted && ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking accepted! Moved to Upcoming.'),
          backgroundColor: AppColors.teal,
        ),
      );
    }
  }

  void _quickReject(BookingRequestModel booking) async {
    final ok = await _provider.rejectBooking(booking.id);
    if (mounted && ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking declined.'),
          backgroundColor: AppColors.ink,
        ),
      );
    }
  }

  List<BookingRequestModel> _filterBookings(int tabIndex) {
    final all = _provider.bookings;
    switch (tabIndex) {
      case 0: // New Requests
        return all.where((b) => b.status == 'pending').toList();
      case 1: // Accepted
        return all.where((b) => b.status == 'accepted').toList();
      case 2: // Upcoming
        return all
            .where((b) =>
                b.status == 'accepted' ||
                b.status == 'confirmed' ||
                b.status == 'travelling' ||
                b.status == 'arrived' ||
                b.status == 'in_progress')
            .toList();
      case 3: // Completed
        return all.where((b) => b.status == 'completed').toList();
      case 4: // Cancelled
        return all
            .where((b) => b.status == 'cancelled' || b.status == 'rejected')
            .toList();
      default:
        return all;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Booking Requests',
          style: TextStyle(
            color: AppColors.ink,
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.teal,
          unselectedLabelColor: AppColors.muted,
          indicatorColor: AppColors.teal,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          unselectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
          tabs: _tabs.map((title) => Tab(text: title)).toList(),
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: List.generate(_tabs.length, (tabIndex) {
            final filtered = _filterBookings(tabIndex);

            return ScrollConfiguration(
              behavior:
                  ScrollConfiguration.of(context).copyWith(overscroll: false),
              child: RefreshIndicator(
                displacement: 20,
                edgeOffset: 0,
                onRefresh: _handleRefresh,
                color: AppColors.teal,
                child: filtered.isEmpty
                    ? _buildEmptyState(_tabs[tabIndex])
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: ClampingScrollPhysics(),
                        ),
                        padding: const EdgeInsets.all(AppSizes.pagePadding),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final booking = filtered[index];
                          return BookingRequestCard(
                            booking: booking,
                            onTap: () => _openDetails(booking),
                            onAccept: () => _quickAccept(booking),
                            onReject: () => _quickReject(booking),
                          );
                        },
                      ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String tabName) {
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
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.calendar_today_outlined,
                size: 40,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'No $tabName',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You currently do not have any bookings under the "$tabName" status.',
              textAlign: TextAlign.center,
              style: const TextStyle(
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
