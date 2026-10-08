import 'package:flutter/material.dart';

import '../../../config/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../models/booking_model.dart';
import '../services/booking_service.dart';
import '../widgets/booking_card.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  final BookingService _service = BookingService();
  late final ScrollController _scrollController;
  List<BookingModel> _bookings = [];
  bool _isInitialLoading = true;
  bool _isRefreshing = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  static const int _limit = 10;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    _fetchHistory(isInitial: true);
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

  Future<void> _fetchHistory({bool isInitial = false, bool isRefresh = false}) async {
    if (isInitial) {
      setState(() => _isInitialLoading = true);
    } else if (isRefresh) {
      setState(() => _isRefreshing = true);
      _service.invalidateCache();
    }

    try {
      _currentPage = 1;
      final results = await _service.getBookings(
        status: 'completed',
        page: _currentPage,
        limit: _limit,
        forceRefresh: isRefresh,
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
    if (_isLoadingMore || !_hasMore || _isInitialLoading || _isRefreshing) {
      return;
    }

    setState(() => _isLoadingMore = true);
    try {
      final nextPage = _currentPage + 1;
      final results = await _service.getBookings(
        status: 'completed',
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

  @override
  Widget build(BuildContext context) {
    final showInitialSpinner = _isInitialLoading && _bookings.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        title: const Text(
          'Booking History',
          style: TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: showInitialSpinner
          ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
          : RefreshIndicator(
              color: AppColors.teal,
              onRefresh: () => _fetchHistory(isRefresh: true),
              child: _bookings.isEmpty
                  ? LayoutBuilder(
                      builder: (context, constraints) => SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: constraints.maxHeight),
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.history_rounded, size: 48, color: AppColors.muted),
                                SizedBox(height: 12),
                                Text(
                                  'No completed bookings found in history.',
                                  style: TextStyle(color: AppColors.muted, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: ClampingScrollPhysics(),
                      ),
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
                        final b = _bookings[index];
                        return BookingCard(
                          booking: b,
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.parentBookingDetails,
                              arguments: b,
                            );
                          },
                        );
                      },
                    ),
            ),
    );
  }
}
