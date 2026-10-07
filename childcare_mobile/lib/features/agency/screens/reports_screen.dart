import 'package:flutter/material.dart';

import '../../../config/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../models/report_model.dart';
import '../providers/agency_provider.dart';
import '../widgets/report_card.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final AgencyProvider _provider = AgencyProvider.instance;
  final TextEditingController _searchController = TextEditingController();

  String _selectedStatus = 'all';
  String _selectedPriority = 'all';
  String _searchQuery = '';

  final List<String> _statusOptions = [
    'all',
    'open',
    'under_review',
    'resolved',
    'dismissed',
  ];

  final List<String> _priorityOptions = [
    'all',
    'urgent',
    'high',
    'medium',
    'low',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadData() {
    _provider.loadReports(refresh: true);
  }

  List<ReportModel> _getFilteredReports() {
    final all = _provider.reports;
    return all.where((r) {
      // Status filter
      if (_selectedStatus != 'all' &&
          r.status.toLowerCase() != _selectedStatus.toLowerCase()) {
        return false;
      }

      // Priority filter
      if (_selectedPriority != 'all' &&
          r.priority.toLowerCase() != _selectedPriority.toLowerCase()) {
        return false;
      }

      // Search filter
      if (_searchQuery.isNotEmpty) {
        final reporter = r.reporterName.toLowerCase();
        final reported = r.reportedUserName.toLowerCase();
        final category = r.category.toLowerCase();
        final desc = r.description.toLowerCase();
        final id = r.id.toLowerCase();

        final matches = reporter.contains(_searchQuery) ||
            reported.contains(_searchQuery) ||
            category.contains(_searchQuery) ||
            desc.contains(_searchQuery) ||
            id.contains(_searchQuery);
        if (!matches) return false;
      }

      return true;
    }).toList();
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
          'Complaints & Safety Reports',
          style: TextStyle(
            color: AppColors.ink,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.teal),
            onPressed: () => _provider.loadReports(refresh: true),
            tooltip: 'Refresh Reports',
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _provider,
        builder: (context, _) {
          final isLoading = _provider.isInitialLoading;
          final reports = _getFilteredReports();
          final allReports = _provider.reports;

          final totalCount = allReports.length;
          final openCount = allReports.where((r) => r.isOpen).length;
          final reviewCount = allReports.where((r) => r.isUnderReview).length;
          final resolvedCount = allReports.where((r) => r.isResolved).length;

          return RefreshIndicator(
            color: AppColors.teal,
            onRefresh: () => _provider.loadReports(refresh: true),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              children: [
                // KPI Metric Summary Bar
                _buildMetricsBar(
                  total: totalCount,
                  open: openCount,
                  review: reviewCount,
                  resolved: resolvedCount,
                ),
                const SizedBox(height: 14),

                // Search Bar
                _buildSearchBar(),
                const SizedBox(height: 14),

                // Status Filter Chips
                _buildStatusFilters(),
                const SizedBox(height: 10),

                // Priority Filter Row
                _buildPriorityFilters(),
                const SizedBox(height: 16),

                // Section Title + Result count
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Incident Reports (${reports.length})',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    if (_selectedStatus != 'all' || _selectedPriority != 'all' || _searchQuery.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedStatus = 'all';
                            _selectedPriority = 'all';
                            _searchController.clear();
                          });
                        },
                        child: const Text(
                          'Clear Filters',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.teal,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Loading / Empty / Content List
                if (isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.teal),
                    ),
                  )
                else if (reports.isEmpty)
                  _buildEmptyState()
                else
                  ...reports.map((report) => ReportCard(
                        report: report,
                        onTap: () async {
                          await Navigator.pushNamed(
                            context,
                            AppRoutes.agencyComplaintDetails,
                            arguments: report,
                          );
                          _provider.loadReports(refresh: true);
                        },
                      )),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricsBar({
    required int total,
    required int open,
    required int review,
    required int resolved,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radius),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _metricColumn('Total', '$total', AppColors.ink),
          _metricDivider(),
          _metricColumn('Open', '$open', const Color(0xFFDC2626)),
          _metricDivider(),
          _metricColumn('Reviewing', '$review', const Color(0xFFD97706)),
          _metricDivider(),
          _metricColumn('Resolved', '$resolved', const Color(0xFF16A34A)),
        ],
      ),
    );
  }

  Widget _metricColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.muted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _metricDivider() {
    return Container(
      height: 26,
      width: 1,
      color: const Color(0xFFE2E8F0),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by reporter, accused, or category...',
          hintStyle: const TextStyle(fontSize: 13, color: AppColors.muted),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.muted, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18, color: AppColors.muted),
                  onPressed: () => _searchController.clear(),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildStatusFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _statusOptions.map((status) {
          final isSelected = _selectedStatus == status;
          final label = status == 'all'
              ? 'All'
              : status == 'under_review'
                  ? 'Under Review'
                  : status[0].toUpperCase() + status.substring(1);

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (val) {
                if (val) {
                  setState(() => _selectedStatus = status);
                }
              },
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.ink,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
              selectedColor: AppColors.teal,
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? AppColors.teal : const Color(0xFFE2E8F0),
                ),
              ),
              showCheckmark: false,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPriorityFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          const Text(
            'Priority: ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.muted,
            ),
          ),
          ..._priorityOptions.map((p) {
            final isSelected = _selectedPriority == p;
            final label = p == 'all' ? 'All' : p.toUpperCase();

            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: InkWell(
                onTap: () => setState(() => _selectedPriority = p),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.teal.withValues(alpha: 0.12) : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected ? AppColors.teal : const Color(0xFFCBD5E1),
                    ),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? AppColors.teal : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radius),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                size: 36,
                color: Color(0xFF10B981),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'No Reports Found',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'There are no safety reports or complaints matching your current filter criteria.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
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
