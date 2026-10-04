import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../models/earning_model.dart';
import '../providers/babysitter_provider.dart';
import '../widgets/earning_card.dart';

class SitterEarningsScreen extends StatefulWidget {
  const SitterEarningsScreen({super.key});

  @override
  State<SitterEarningsScreen> createState() => _SitterEarningsScreenState();
}

class _SitterEarningsScreenState extends State<SitterEarningsScreen> {
  final BabysitterProvider _provider = BabysitterProvider.instance;
  String _selectedRange = 'weekly'; // 'weekly' or 'monthly'
  int _selectedBarIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadEarnings();
  }

  Future<void> _loadEarnings({bool isRefresh = false}) async {
    await _provider.fetchEarnings(
      range: _selectedRange,
      showLoading: !isRefresh,
    );
  }

  void _onRangeChanged(String newRange) {
    if (_selectedRange == newRange) return;
    setState(() {
      _selectedRange = newRange;
      _selectedBarIndex = -1;
    });
    _provider.fetchEarnings(range: newRange);
  }

  void _showWithdrawModal(double availableBalance) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Request Payout',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your earnings are automatically transferred every Monday to your linked Sri Lankan bank account (CEFT / SLIPS). You can also request an instant payout.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.muted.withValues(alpha: 0.9),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.mint.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.teal.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Available for Payout',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      'Rs. ${availableBalance.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.teal,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final success = await _provider.requestPayout();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? 'Payout request submitted successfully.'
                                : (_provider.errorMessage ?? 'Payout request failed'),
                          ),
                          backgroundColor: success ? AppColors.teal : AppColors.coral,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Confirm Instant Payout',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _provider,
      builder: (context, _) {
        final earnings = _provider.earnings ?? const EarningSummaryModel();
        final isLoading = _provider.isLoading && _provider.earnings == null;

        return Scaffold(
          backgroundColor: const Color(0xFFF9FAFB),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.ink),
              onPressed: () => Navigator.maybePop(context),
            ),
            title: const Text(
              'Earnings & Payouts',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.file_download_outlined, color: AppColors.teal),
                tooltip: 'Export Statement',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Monthly earnings statement downloaded.'),
                      backgroundColor: AppColors.teal,
                    ),
                  );
                },
              ),
            ],
          ),
          body: (isLoading && earnings.totalEarnings == 0 && earnings.recentEarnings.isEmpty)
              ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
              : ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context)
                      .copyWith(overscroll: false),
                  child: RefreshIndicator(
                    displacement: 20,
                    edgeOffset: 0,
                    color: AppColors.teal,
                    onRefresh: () => _loadEarnings(isRefresh: true),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: ClampingScrollPhysics(),
                      ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Main Balance Hero Card
                        _buildHeroEarningsCard(earnings),
                        const SizedBox(height: 20),

                        // Time Range Toggle
                        _buildRangeSelector(),
                        const SizedBox(height: 20),

                        // Chart Card
                        _buildChartSection(earnings),
                        const SizedBox(height: 24),

                        // Summary Statistics Row
                        _buildSummaryMetrics(earnings),
                        const SizedBox(height: 28),

                        // Recent Transactions Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Recent Earnings',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                            Text(
                              '${earnings.recentEarnings.length} Completed',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.muted.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // List of recent earnings
                        if (earnings.recentEarnings.isEmpty)
                          _buildEmptyEarnings()
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: earnings.recentEarnings.length,
                            separatorBuilder: (_, index) => const SizedBox(height: 12),
                            itemBuilder: (ctx, index) {
                              final item = earnings.recentEarnings[index];
                              return EarningCard(
                                earning: item,
                                onTap: () {
                                  _showEarningDetailSheet(context, item);
                                },
                              );
                            },
                          ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
        );
      },
    );
  }

  Widget _buildHeroEarningsCard(EarningSummaryModel earnings) {
    final displayAmount = _selectedRange == 'weekly'
        ? earnings.weeklyEarnings
        : earnings.currentMonthEarnings;
    final rangeLabel = _selectedRange == 'weekly' ? 'This Week' : 'This Month';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.ink,
            Color(0xFF234B47),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
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
                'Total Revenue ($rangeLabel)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.teal.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified, size: 14, color: AppColors.mint),
                    const SizedBox(width: 4),
                    Text(
                      'Verified Payouts',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.95),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Rs. ${displayAmount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Colors.white12),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'All-Time Total',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Rs. ${earnings.totalEarnings.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showWithdrawModal(earnings.pendingPayout > 0 ? earnings.pendingPayout : displayAmount),
                icon: const Icon(Icons.arrow_outward_rounded, size: 16),
                label: const Text('Withdraw', style: TextStyle(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRangeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEFEFEF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _onRangeChanged('weekly'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: _selectedRange == 'weekly' ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _selectedRange == 'weekly'
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    'Weekly View',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: _selectedRange == 'weekly' ? FontWeight.w700 : FontWeight.w500,
                      color: _selectedRange == 'weekly' ? AppColors.teal : AppColors.muted,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _onRangeChanged('monthly'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: _selectedRange == 'monthly' ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _selectedRange == 'monthly'
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    'Monthly View',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: _selectedRange == 'monthly' ? FontWeight.w700 : FontWeight.w500,
                      color: _selectedRange == 'monthly' ? AppColors.teal : AppColors.muted,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection(EarningSummaryModel earnings) {
    final points = earnings.weeklyData;
    double maxAmount = 100.0;
    for (final p in points) {
      if (p.amount > maxAmount) maxAmount = p.amount;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.sand.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
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
              Text(
                _selectedRange == 'weekly' ? 'Daily Activity' : 'Monthly Breakdown',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              if (_selectedBarIndex >= 0 && _selectedBarIndex < points.length)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.mint,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${points[_selectedBarIndex].day}: Rs. ${points[_selectedBarIndex].amount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.teal,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // Custom Bar Chart
          SizedBox(
            height: 150,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(points.length, (index) {
                final point = points[index];
                final normalizedHeight = (point.amount / maxAmount) * 110.0;
                final barHeight = normalizedHeight > 6 ? normalizedHeight : 6.0;
                final isSelected = _selectedBarIndex == index;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedBarIndex = _selectedBarIndex == index ? -1 : index;
                    });
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Value indicator for active bar
                      if (point.amount > 0)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            'Rs. ${point.amount.toInt()}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? AppColors.teal : AppColors.muted.withValues(alpha: 0.7),
                            ),
                          ),
                        )
                      else
                        const SizedBox(height: 18),
                      // Bar cylinder
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 22,
                        height: barHeight,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.ink
                              : point.amount > 0
                                  ? AppColors.teal
                                  : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.teal.withValues(alpha: 0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Day label
                      Text(
                        point.day,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? AppColors.ink : AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryMetrics(EarningSummaryModel earnings) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricTile(
            label: 'Completed',
            value: '${earnings.completedBookings}',
            unit: 'bookings',
            icon: Icons.check_circle_outline,
            accentColor: AppColors.teal,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricTile(
            label: 'Avg Rate',
            value: 'Rs. ${earnings.hourlyRateAverage.toStringAsFixed(0)}',
            unit: '/ hour',
            icon: Icons.timer_outlined,
            accentColor: const Color(0xFF6366F1),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricTile(
            label: 'Pending',
            value: 'Rs. ${earnings.pendingPayout.toStringAsFixed(0)}',
            unit: 'payout',
            icon: Icons.pending_actions,
            accentColor: AppColors.coral,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required String unit,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.sand.withValues(alpha: 0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: accentColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.muted.withValues(alpha: 0.9),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          Text(
            unit,
            style: TextStyle(
              fontSize: 10,
              color: AppColors.muted.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyEarnings() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.sand.withValues(alpha: 0.8)),
      ),
      child: Column(
        children: [
          Icon(Icons.monetization_on_outlined, size: 44, color: AppColors.muted.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          const Text(
            'No Earnings Recorded Yet',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink),
          ),
          const SizedBox(height: 6),
          Text(
            'Complete accepted bookings to see your payout summary and transaction history.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.muted.withValues(alpha: 0.8), height: 1.4),
          ),
        ],
      ),
    );
  }

  void _showEarningDetailSheet(BuildContext context, EarningItemModel item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Booking Receipt',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.mint,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.status.toUpperCase(),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.teal),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildReceiptRow('Parent', item.parentName),
              _buildReceiptRow('Booking Reference', item.bookingId.isNotEmpty ? item.bookingId : item.id),
              _buildReceiptRow('Duration', '${item.durationHours.toStringAsFixed(1)} hours'),
              _buildReceiptRow('Rate', 'Rs. ${item.hourlyRate.toStringAsFixed(0)} / hour'),
              if (item.serviceFee > 0)
                _buildReceiptRow('Platform Fee', '-Rs. ${item.serviceFee.toStringAsFixed(2)}'),
              const Divider(height: 24),
              _buildReceiptRow('Net Earnings', 'Rs. ${item.netAmount.toStringAsFixed(2)}', isBold: true),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppColors.teal),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Close', style: TextStyle(color: AppColors.teal, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isBold ? AppColors.ink : AppColors.muted,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: isBold ? AppColors.teal : AppColors.ink,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
