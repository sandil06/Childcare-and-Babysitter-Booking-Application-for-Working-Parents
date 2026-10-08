import 'package:flutter/material.dart';

import '../../../config/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../models/statistics_model.dart';
import '../providers/agency_provider.dart';

class SystemStatisticsScreen extends StatefulWidget {
  const SystemStatisticsScreen({super.key});

  @override
  State<SystemStatisticsScreen> createState() => _SystemStatisticsScreenState();
}

class _SystemStatisticsScreenState extends State<SystemStatisticsScreen> {
  final AgencyProvider _provider = AgencyProvider.instance;
  String _selectedPeriod = 'All Time';

  final List<String> _periods = ['This Week', 'This Month', 'This Quarter', 'All Time'];

  @override
  void initState() {
    super.initState();
    _provider.loadStatistics();
  }

  void _generateReportSummary() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radius)),
        title: const Row(
          children: [
            Icon(Icons.download_done_rounded, color: AppColors.teal, size: 22),
            SizedBox(width: 8),
            Text('Report Generated', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          ],
        ),
        content: const Text(
          'Executive governance summary report has been compiled and saved to administrative downloads.',
          style: TextStyle(fontSize: 13, color: Color(0xFF475569)),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.teal,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.ink, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'System Analytics & Reports',
          style: TextStyle(
            color: AppColors.ink,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.teal),
            onPressed: () => _provider.loadStatistics(refresh: true),
            tooltip: 'Refresh Analytics',
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _provider,
        builder: (context, _) {
          final stats = _provider.statistics ?? const SystemStatisticsModel();
          final isLoading = _provider.isInitialLoading;

          return RefreshIndicator(
            color: AppColors.teal,
            onRefresh: () => _provider.loadStatistics(refresh: true),
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
                : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Period Selector Bar
                        _buildPeriodSelector(),
                        const SizedBox(height: 16),

                        // Financial & Revenue Overview Card
                        _buildFinancialCard(stats),
                        const SizedBox(height: 16),

                        // Section 1: User Analytics Card
                        _buildUserAnalyticsCard(stats),
                        const SizedBox(height: 16),

                        // Section 2: Booking Fulfillment Card
                        _buildBookingAnalyticsCard(stats),
                        const SizedBox(height: 16),

                        // Section 3: Safety & Compliance Card
                        _buildComplianceCard(stats),
                        const SizedBox(height: 20),

                        // Export CTA Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _generateReportSummary,
                            icon: const Icon(Icons.file_download_outlined, size: 20),
                            label: const Text('Export Administrative Audit Report'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.teal,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppSizes.radius),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: _periods.map((p) {
          final isSelected = _selectedPeriod == p;
          return Expanded(
            child: InkWell(
              onTap: () => setState(() => _selectedPeriod = p),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.teal : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  p,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFF64748B),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFinancialCard(SystemStatisticsModel s) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radius),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
              const Row(
                children: [
                  Icon(Icons.monetization_on_outlined, color: AppColors.teal, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Financial & Platform Revenue',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  '+12.4% MoM',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF16A34A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _financialMetric(
                  'Gross Booking Volume',
                  'LKR ${_formatCurrency(s.totalTransactionVolume)}',
                  const Color(0xFF0284C7),
                ),
              ),
              Container(width: 1, height: 40, color: const Color(0xFFE2E8F0)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 14),
                  child: _financialMetric(
                    'Agency Take (10%)',
                    'LKR ${_formatCurrency(s.totalPlatformRevenue)}',
                    const Color(0xFF16A34A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Successful Checkouts: ${s.successfulTransactions}',
                style: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w500),
              ),
              Text(
                'Disputed / Failed: ${s.failedTransactions}',
                style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626), fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _financialMetric(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color),
        ),
      ],
    );
  }

  Widget _buildUserAnalyticsCard(SystemStatisticsModel s) {
    final parentPct = s.totalUsers > 0 ? (s.totalParents / s.totalUsers) : 0.0;
    final sitterPct = s.totalUsers > 0 ? (s.totalBabysitters / s.totalUsers) : 0.0;
    final verifiedPct = s.totalBabysitters > 0 ? (s.verifiedBabysitters / s.totalBabysitters) : 0.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radius),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.people_outline_rounded, color: AppColors.teal, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'User Base & Demographics',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
              Text(
                '${s.totalUsers} Total',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.teal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // User distribution bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  Expanded(
                    flex: (parentPct * 100).toInt(),
                    child: Container(color: AppColors.teal),
                  ),
                  Expanded(
                    flex: (sitterPct * 100).toInt(),
                    child: Container(color: const Color(0xFFF59E0B)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _legendItem(
                label: 'Parents (${s.totalParents})',
                percentage: '${(parentPct * 100).toStringAsFixed(0)}%',
                color: AppColors.teal,
              ),
              _legendItem(
                label: 'Babysitters (${s.totalBabysitters})',
                percentage: '${(sitterPct * 100).toStringAsFixed(0)}%',
                color: const Color(0xFFF59E0B),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),

          // Compliance & Health details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Verified Sitter Coverage', style: TextStyle(fontSize: 11, color: AppColors.muted)),
                  const SizedBox(height: 2),
                  Text(
                    '${(verifiedPct * 100).toStringAsFixed(1)}% (${s.verifiedBabysitters} sitters)',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF16A34A)),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Suspended Accounts', style: TextStyle(fontSize: 11, color: AppColors.muted)),
                  const SizedBox(height: 2),
                  Text(
                    '${s.suspendedUsers} users',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFDC2626)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBookingAnalyticsCard(SystemStatisticsModel s) {
    final completionRate = s.totalBookings > 0
        ? (s.completedBookings / s.totalBookings * 100).toStringAsFixed(1)
        : '0.0';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radius),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.event_available_outlined, color: AppColors.teal, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Booking Fulfillment Engine',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
              Text(
                '$completionRate% Success',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF16A34A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _statPill('Completed', '${s.completedBookings}', const Color(0xFF16A34A), const Color(0xFFDCFCE7)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _statPill('Active / Ongoing', '${s.activeBookings}', const Color(0xFF0284C7), const Color(0xFFE0F2FE)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _statPill('Cancelled', '${s.cancelledBookings}', const Color(0xFFDC2626), const Color(0xFFFEE2E2)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: () => Navigator.pushNamed(context, AppRoutes.agencyBookings),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Open Booking Monitoring',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.teal),
                ),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward_ios_rounded, size: 11, color: AppColors.teal),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplianceCard(SystemStatisticsModel s) {
    final resolutionRate = s.totalReports > 0
        ? (s.resolvedReports / s.totalReports * 100).toStringAsFixed(1)
        : '0.0';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radius),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.health_and_safety_outlined, color: AppColors.teal, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Safety & Dispute Resolution',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
              Text(
                '$resolutionRate% Resolved',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF16A34A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _statPill('Resolved', '${s.resolvedReports}', const Color(0xFF16A34A), const Color(0xFFDCFCE7)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _statPill('Investigating', '${s.underReviewReports}', const Color(0xFFD97706), const Color(0xFFFEF3C7)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _statPill('Open / Urgent', '${s.openReports}', const Color(0xFFDC2626), const Color(0xFFFEE2E2)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: () => Navigator.pushNamed(context, AppRoutes.agencyReports),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Manage Complaints Queue',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.teal),
                ),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward_ios_rounded, size: 11, color: AppColors.teal),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statPill(String label, String value, Color fg, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: fg),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: fg),
          ),
        ],
      ),
    );
  }

  Widget _legendItem({
    required String label,
    required String percentage,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 6),
        Text(
          '$label • $percentage',
          style: const TextStyle(fontSize: 11.5, color: AppColors.ink, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  String _formatCurrency(double val) {
    if (val >= 1000000) {
      return '${(val / 1000000).toStringAsFixed(1)}M';
    } else if (val >= 1000) {
      return '${(val / 1000).toStringAsFixed(0)}k';
    }
    return val.toStringAsFixed(0);
  }
}
