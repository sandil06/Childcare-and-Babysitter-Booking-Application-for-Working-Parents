import 'package:flutter/material.dart';

import '../../../config/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../models/agency_dashboard_model.dart';
import '../models/verification_request_model.dart';
import '../providers/agency_provider.dart';
import '../widgets/dashboard_stat_card.dart';
import '../widgets/verification_status_chip.dart';

class AgencyDashboardScreen extends StatefulWidget {
  const AgencyDashboardScreen({super.key});

  @override
  State<AgencyDashboardScreen> createState() => _AgencyDashboardScreenState();
}

class _AgencyDashboardScreenState extends State<AgencyDashboardScreen> {
  final AgencyProvider _provider = AgencyProvider.instance;

  @override
  void initState() {
    super.initState();
    _provider.loadDashboard();
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radius)),
        title: const Text('Exit Agency Portal?', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to end this administrative session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.muted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (r) => false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _provider,
      builder: (context, _) {
        final d = _provider.dashboard ?? const AgencyDashboardModel();
        final isLoading = _provider.isInitialLoading;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F5F2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings_rounded,
                    color: AppColors.teal,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Agency Console',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      'Platform Governance & Verifications',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.muted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: AppColors.ink),
                onPressed: () => Navigator.pushNamed(context, AppRoutes.parentNotifications),
                tooltip: 'System Alerts',
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444)),
                onPressed: _confirmLogout,
                tooltip: 'Log Out',
              ),
            ],
          ),
          body: isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.teal),
                )
              : RefreshIndicator(
                  color: AppColors.teal,
                  onRefresh: () => _provider.loadDashboard(refresh: true),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Quick Action Navigation Bar
                        _buildQuickActionButtons(),
                        const SizedBox(height: 20),

                        // Section 1: Verifications & Compliance
                        const Text(
                          'Verification & Compliance Overview',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 10),
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.45,
                          children: [
                            DashboardStatCard(
                              title: 'Pending Verifications',
                              value: '${d.pendingVerifications}',
                              icon: Icons.hourglass_top_rounded,
                              iconColor: const Color(0xFFD97706),
                              iconBgColor: const Color(0xFFFEF3C7),
                              subtitle: 'Needs administrative review',
                              onTap: () => Navigator.pushNamed(
                                context,
                                AppRoutes.agencyVerificationRequests,
                              ),
                            ),
                            DashboardStatCard(
                              title: 'Verified Babysitters',
                              value: '${d.verifiedBabysitters}',
                              icon: Icons.verified_user_rounded,
                              iconColor: const Color(0xFF16A34A),
                              iconBgColor: const Color(0xFFDCFCE7),
                              subtitle: 'Active in search catalog',
                            ),
                            DashboardStatCard(
                              title: 'Rejected Applications',
                              value: '${d.rejectedVerifications}',
                              icon: Icons.cancel_outlined,
                              iconColor: const Color(0xFFDC2626),
                              iconBgColor: const Color(0xFFFEE2E2),
                              subtitle: 'Failed compliance checks',
                            ),
                            DashboardStatCard(
                              title: 'Open Safety Reports',
                              value: '${d.openComplaints}',
                              icon: Icons.report_problem_rounded,
                              iconColor: const Color(0xFFEA580C),
                              iconBgColor: const Color(0xFFFFEDD5),
                              subtitle: 'High priority complaints',
                              onTap: () => Navigator.pushNamed(
                                context,
                                AppRoutes.agencyReports,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Section 2: Platform Users & Operations
                        const Text(
                          'Users & Booking Activity',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 10),
                        GridView.count(
                          crossAxisCount: 3,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1.15,
                          children: [
                            DashboardStatCard(
                              title: 'Total Users',
                              value: '${d.totalUsers}',
                              icon: Icons.people_alt_outlined,
                              iconColor: AppColors.teal,
                              iconBgColor: const Color(0xFFE6F5F2),
                            ),
                            DashboardStatCard(
                              title: 'Active Bookings',
                              value: '${d.activeBookings}',
                              icon: Icons.calendar_today_rounded,
                              iconColor: const Color(0xFF0284C7),
                              iconBgColor: const Color(0xFFE0F2FE),
                            ),
                            DashboardStatCard(
                              title: 'Completed',
                              value: '${d.completedBookings}',
                              icon: Icons.task_alt_rounded,
                              iconColor: const Color(0xFF059669),
                              iconBgColor: const Color(0xFFD1FAE5),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Section 3: Recent Verification Queue
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Recent Verification Requests',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pushNamed(
                                context,
                                AppRoutes.agencyVerificationRequests,
                              ),
                              child: const Text(
                                'View All',
                                style: TextStyle(
                                  color: AppColors.teal,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        _buildRecentVerificationsList(d.recentVerifications),
                        const SizedBox(height: 24),

                        // Section 4: Recent Safety Reports
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Recent Safety Complaints',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pushNamed(
                                context,
                                AppRoutes.agencyReports,
                              ),
                              child: const Text(
                                'Manage Reports',
                                style: TextStyle(
                                  color: AppColors.teal,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        _buildRecentComplaintsList(d.recentComplaints),
                        const SizedBox(height: 24),

                        // Section 5: Recent Platform Bookings
                        const Text(
                          'Live Booking Monitoring',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildRecentBookingsList(d.recentBookings),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildQuickActionButtons() {
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
          _actionItem(
            icon: Icons.verified_user_rounded,
            label: 'Verifications',
            color: AppColors.teal,
            onTap: () => Navigator.pushNamed(context, AppRoutes.agencyVerificationRequests),
          ),
          _actionItem(
            icon: Icons.group_outlined,
            label: 'Users',
            color: const Color(0xFF0284C7),
            onTap: () => Navigator.pushNamed(context, AppRoutes.agencyReports),
          ),
          _actionItem(
            icon: Icons.calendar_month_outlined,
            label: 'Bookings',
            color: const Color(0xFF7C3AED),
            onTap: () => Navigator.pushNamed(context, AppRoutes.agencyReports),
          ),
          _actionItem(
            icon: Icons.analytics_outlined,
            label: 'Analytics',
            color: const Color(0xFFD97706),
            onTap: () => Navigator.pushNamed(context, AppRoutes.agencyReports),
          ),
        ],
      ),
    );
  }

  Widget _actionItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentVerificationsList(List<VerificationRequestModel> items) {
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.radius),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Center(
          child: Text(
            'No pending verification requests at this time',
            style: TextStyle(color: AppColors.muted, fontSize: 13),
          ),
        ),
      );
    }

    return Column(
      children: items.map((req) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSizes.radius),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFFE6F5F2),
                child: Text(
                  req.name.isNotEmpty ? req.name[0].toUpperCase() : 'B',
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.teal),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      req.name,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${req.experienceYears} yrs experience • ${req.documents.length} docs submitted',
                      style: const TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              VerificationStatusChip(status: req.status),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecentComplaintsList(List dynamicItems) {
    if (dynamicItems.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.radius),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Center(
          child: Text(
            'All safety complaints are currently resolved',
            style: TextStyle(color: AppColors.muted, fontSize: 13),
          ),
        ),
      );
    }

    return Column(
      children: dynamicItems.take(3).map((item) {
        final category = item.category?.toString() ?? 'Safety';
        final priority = item.priority?.toString() ?? 'medium';
        final desc = item.description?.toString() ?? 'Report details';

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSizes.radius),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          category,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            priority.toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFFDC2626),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      desc,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecentBookingsList(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.radius),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Center(
          child: Text(
            'No active platform bookings at this moment',
            style: TextStyle(color: AppColors.muted, fontSize: 13),
          ),
        ),
      );
    }

    return Column(
      children: items.take(3).map((b) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSizes.radius),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.bookmark_outline_rounded, color: Color(0xFF0284C7), size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${b['parentName']} ➔ ${b['babysitterName']}',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${b['date']} • ${b['startTime']}',
                      style: const TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Text(
                'Rs. ${b['totalAmount']}',
                style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.teal, fontSize: 13),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
