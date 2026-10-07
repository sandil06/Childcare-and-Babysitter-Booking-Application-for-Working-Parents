import 'package:flutter/material.dart';

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
                        onTap: () => _showReportDetailsModal(report),
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

  void _showReportDetailsModal(ReportModel report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ReportQuickModal(
        report: report,
        onStatusUpdated: () {
          Navigator.pop(ctx);
          _provider.loadReports(refresh: true);
        },
      ),
    );
  }
}

class _ReportQuickModal extends StatefulWidget {
  final ReportModel report;
  final VoidCallback onStatusUpdated;

  const _ReportQuickModal({
    required this.report,
    required this.onStatusUpdated,
  });

  @override
  State<_ReportQuickModal> createState() => _ReportQuickModalState();
}

class _ReportQuickModalState extends State<_ReportQuickModal> {
  final TextEditingController _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _updateStatus(String status) async {
    setState(() => _isLoading = true);
    final ok = await AgencyProvider.instance.updateReportStatus(
      widget.report.id,
      status: status,
      resolutionNotes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
    );
    setState(() => _isLoading = false);

    if (mounted) {
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report marked as ${status.replaceAll('_', ' ').toUpperCase()}'),
            backgroundColor: const Color(0xFF16A34A),
          ),
        );
        widget.onStatusUpdated();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update report status'),
            backgroundColor: Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.report;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.category,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Report ID: #${r.id}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.muted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Incident Description
            const Text(
              'Incident Details',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                r.description,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF334155),
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Parties involved
            Row(
              children: [
                Expanded(
                  child: _partyBox(
                    label: 'Reporter',
                    name: r.reporterName,
                    role: r.reporterRole,
                    email: r.reporterEmail,
                    isAccused: false,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _partyBox(
                    label: 'Reported User',
                    name: r.reportedUserName,
                    role: r.reportedUserRole,
                    email: r.reportedUserEmail,
                    isAccused: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Resolution Notes input
            const Text(
              'Administrative Resolution Notes',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: r.resolutionNotes.isNotEmpty
                    ? r.resolutionNotes
                    : 'Enter investigation findings, corrective actions, or decision rationale...',
                hintStyle: const TextStyle(fontSize: 12.5, color: AppColors.muted),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Action Buttons
            if (_isLoading)
              const Center(child: CircularProgressIndicator(color: AppColors.teal))
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _updateStatus('dismissed'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF64748B),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Dismiss', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateStatus('under_review'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD97706),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Investigate', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateStatus('resolved'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Resolve', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _partyBox({
    required String label,
    required String name,
    required String role,
    required String email,
    required bool isAccused,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isAccused ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isAccused ? const Color(0xFFFCA5A5) : const Color(0xFFBBF7D0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: isAccused ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          Text(
            role.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.muted,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (email.isNotEmpty)
            Text(
              email,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.muted,
              ),
            ),
        ],
      ),
    );
  }
}
