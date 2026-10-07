import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../models/admin_user_model.dart';
import '../providers/agency_provider.dart';
import '../widgets/admin_action_dialog.dart';

class ParentManagementScreen extends StatefulWidget {
  const ParentManagementScreen({super.key});

  @override
  State<ParentManagementScreen> createState() => _ParentManagementScreenState();
}

class _ParentManagementScreenState extends State<ParentManagementScreen> {
  late final AgencyProvider _provider;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _provider = AgencyProvider.instance;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _provider.setUserRoleFilter('parent');
      _provider.loadUsers(refresh: true);
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String q) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      _provider.loadUsers(search: q.trim());
    });
  }

  void _showParentDetails(AdminUserModel parent) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              const SizedBox(height: 18),
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFFEEF2FF),
                    child: Text(
                      parent.name.isNotEmpty ? parent.name[0].toUpperCase() : 'P',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF4338CA),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          parent.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          parent.email,
                          style: const TextStyle(fontSize: 13, color: AppColors.muted),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: parent.isSuspended ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            parent.accountStatus.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: parent.isSuspended ? const Color(0xFFB91C1C) : const Color(0xFF15803D),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(color: Color(0xFFE2E8F0)),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem('Phone', parent.phone.isNotEmpty ? parent.phone : '+94 77 445 5667'),
                  ),
                  Expanded(
                    child: _buildInfoItem('Total Bookings', '${parent.totalBookings} Completed'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem('Account Status', parent.isActive ? 'Active & In Good Standing' : 'Suspended'),
                  ),
                  Expanded(
                    child: _buildInfoItem('Email Verified', parent.isEmailVerified ? 'Verified' : 'Pending'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Registered Children Info Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.child_care_rounded, size: 18, color: AppColors.teal),
                        SizedBox(width: 8),
                        Text(
                          'Family & Children Profiles',
                          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.ink),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Dinuka (Age 4) — Mild dairy allergy\n• Senuka (Age 1) — Requires afternoon naps',
                      style: TextStyle(fontSize: 12.5, color: Color(0xFF475569), height: 1.5),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              if (parent.isSuspended) ...[
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _provider.reactivateUser(parent.id);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Reactivate Parent Account', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ] else ...[
                OutlinedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final reason = await AdminActionDialog.show(
                      context,
                      title: 'Suspend Parent',
                      message: 'Are you sure you want to suspend ${parent.name}?',
                      confirmText: 'Suspend Parent',
                      confirmColor: const Color(0xFFDC2626),
                      requireReason: true,
                      reasonLabel: 'Suspension Reason *',
                    );
                    if (reason != null && reason.isNotEmpty) {
                      _provider.suspendUser(parent.id, reason: reason);
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                    side: const BorderSide(color: Color(0xFFFCA5A5)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Suspend Parent Account', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _provider,
      builder: (context, _) {
        final parents = _provider.users.where((u) => u.isParent).toList();
        final isLoading = _provider.isInitialLoading;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: const Text(
              'Parent Management',
              style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700, fontSize: 18),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.ink),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: AppColors.teal),
                onPressed: () => _provider.loadUsers(refresh: true),
              ),
            ],
          ),
          body: Column(
            children: [
              // Search Header
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search parents by name or email...',
                    hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radius),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              // Summary Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: const Color(0xFFF1F5F9),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${parents.length} Registered Parents',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                    ),
                    const Text('Parent Directory', style: TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8))),
                  ],
                ),
              ),

              // Parent List
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: parents.length,
                        itemBuilder: (context, index) {
                          final parent = parents[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(AppSizes.radius),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: InkWell(
                              onTap: () => _showParentDetails(parent),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: const Color(0xFFEEF2FF),
                                    child: Text(
                                      parent.name.isNotEmpty ? parent.name[0].toUpperCase() : 'P',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF4338CA),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          parent.name,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.ink,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(parent.email, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Text(
                                              '${parent.totalBookings} Bookings',
                                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: parent.isSuspended ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                parent.accountStatus.toUpperCase(),
                                                style: TextStyle(
                                                  fontSize: 9.5,
                                                  fontWeight: FontWeight.w800,
                                                  color: parent.isSuspended ? const Color(0xFFB91C1C) : const Color(0xFF15803D),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
