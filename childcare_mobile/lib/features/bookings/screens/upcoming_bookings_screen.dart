import 'package:flutter/material.dart';

import '../../../config/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../models/booking_model.dart';
import '../services/booking_service.dart';
import '../widgets/booking_card.dart';

class UpcomingBookingsScreen extends StatefulWidget {
  const UpcomingBookingsScreen({super.key});

  @override
  State<UpcomingBookingsScreen> createState() => _UpcomingBookingsScreenState();
}

class _UpcomingBookingsScreenState extends State<UpcomingBookingsScreen> {
  final BookingService _bookingService = BookingService();
  final ScrollController _scrollController = ScrollController();

  String _selectedTab = 'upcoming'; // 'upcoming', 'completed', 'cancelled'
  List<BookingModel> _bookings = [];
  bool _isInitialLoading = true;
  bool _isRefreshing = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  final int _limit = 10;

  @override
  void initState() {
    super.initState();
    _fetchBookings(isInitial: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore &&
        !_isInitialLoading &&
        !_isRefreshing) {
      _loadMore();
    }
  }

  Future<void> _fetchBookings({bool isInitial = false, bool isRefresh = false}) async {
    if (isInitial) {
      setState(() => _isInitialLoading = true);
    } else if (isRefresh) {
      setState(() => _isRefreshing = true);
    }

    try {
      _currentPage = 1;
      final results = await _bookingService.getBookings(
        status: _selectedTab,
        page: _currentPage,
        limit: _limit,
      );
      if (mounted) {
        setState(() {
          _bookings = results;
          _hasMore = results.length >= _limit;
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
    setState(() => _isLoadingMore = true);
    try {
      final nextPage = _currentPage + 1;
      final results = await _bookingService.getBookings(
        status: _selectedTab,
        page: nextPage,
        limit: _limit,
      );
      if (mounted) {
        setState(() {
          _currentPage = nextPage;
          _bookings.addAll(results);
          _hasMore = results.length >= _limit;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  void _onTabSelected(String tab) {
    if (_selectedTab == tab) return;
    setState(() {
      _selectedTab = tab;
      _bookings = [];
    });
    _fetchBookings(isInitial: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        title: const Text(
          'My Bookings',
          style: TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Segmented Tab Selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.pagePadding, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.sand),
                ),
                child: Row(
                  children: [
                    _buildTabButton('Upcoming', 'upcoming'),
                    _buildTabButton('Completed', 'completed'),
                    _buildTabButton('Cancelled', 'cancelled'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Main List Content
            Expanded(
              child: _isInitialLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
                  : RefreshIndicator(
                      color: AppColors.teal,
                      onRefresh: () => _fetchBookings(isRefresh: true),
                      child: _bookings.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              controller: _scrollController,
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSizes.pagePadding,
                                vertical: 12,
                              ),
                              itemCount: _bookings.length + (_isLoadingMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == _bookings.length) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.teal,
                                      ),
                                    ),
                                  );
                                }
                                final booking = _bookings[index];
                                return BookingCard(
                                  booking: booking,
                                  onTap: () async {
                                    await Navigator.pushNamed(
                                      context,
                                      AppRoutes.parentBookingDetails,
                                      arguments: booking,
                                    );
                                    _fetchBookings(isRefresh: true);
                                  },
                                );
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String label, String tabKey) {
    final isSelected = _selectedTab == tabKey;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabSelected(tabKey),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF005B60) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.muted,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    IconData icon;
    String message;
    switch (_selectedTab) {
      case 'completed':
        icon = Icons.task_alt_rounded;
        message = 'No completed care bookings yet.';
        break;
      case 'cancelled':
        icon = Icons.cancel_outlined;
        message = 'No cancelled bookings.';
        break;
      case 'upcoming':
      default:
        icon = Icons.calendar_month_outlined;
        message = 'No upcoming care reservations found.\nBook a trusted babysitter today!';
        break;
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.15),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.mint,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 36, color: AppColors.teal),
              ),
              const SizedBox(height: 18),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted,
                  height: 1.4,
                ),
              ),
              if (_selectedTab == 'upcoming') ...[
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.babysitterSearch);
                  },
                  icon: const Icon(Icons.search_rounded, size: 18),
                  label: const Text('Find a Babysitter'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF005B60),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
