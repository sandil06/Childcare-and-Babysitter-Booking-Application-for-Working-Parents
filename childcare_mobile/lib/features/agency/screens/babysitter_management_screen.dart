import 'dart:async';
import 'package:flutter/material.dart';
import '../../../config/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../models/admin_user_model.dart';
import '../providers/agency_provider.dart';
import '../widgets/admin_action_dialog.dart';
import '../widgets/verification_status_chip.dart';

class BabysitterManagementScreen extends StatefulWidget {
  const BabysitterManagementScreen({super.key});

  @override
  State<BabysitterManagementScreen> createState() => _BabysitterManagementScreenState();
}

class _BabysitterManagementScreenState extends State<BabysitterManagementScreen> {
  late final AgencyProvider _provider;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _provider = AgencyProvider.instance;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _provider.setUserRoleFilter('babysitter');
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

  void _showSitterDetails(AdminUserModel sitter) {
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
                    backgroundColor: AppColors.mint,
                    backgroundImage: sitter.avatar.isNotEmpty
                        ? NetworkImage(sitter.avatar)
                        : null,
                    child: sitter.avatar.isEmpty
                        ? Text(
                            sitter.name.isNotEmpty ? sitter.name[0].toUpperCase() : 'B',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.teal,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sitter.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(sitter.email, style: const TextStyle(fontSize: 13, color: AppColors.muted)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF59E0B)),
                            const SizedBox(width: 4),
                            Text(
                              '${sitter.averageRating.toStringAsFixed(1)} (Rated)',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink),
                            ),
                            const SizedBox(width: 8),
                            const VerificationStatusChip(status: 'verified'),
                          ],
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
                    child: _buildInfoItem('Phone', sitter.phone.isNotEmpty ? sitter.phone : '+94 77 123 4567'),
                  ),
                  Expanded(
                    child: _buildInfoItem('Completed Bookings', '${sitter.totalBookings} Jobs'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem('Hourly Rate', 'LKR 1,500 / hr'),
                  ),
                  Expanded(
                    child: _buildInfoItem('Experience', '4 Years Caregiving'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Caregiver Skills Card
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
                        Icon(Icons.verified_outlined, size: 18, color: AppColors.teal),
                        SizedBox(width: 8),
                        Text(
                          'Verified Credentials & Skills',
                          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.ink),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• First Aid & Infant CPR Certified\n• Early Childhood Education Diploma\n• Clean Police Clearance Background Check',
                      style: TextStyle(fontSize: 12.5, color: Color(0xFF475569), height: 1.5),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              // View Verification Documents button
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(
                    context,
                    AppRoutes.agencyVerificationRequests,
                  );
                },
                icon: const Icon(Icons.document_scanner_outlined, size: 18),
                label: const Text('Review Verification Documents'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.teal,
                  side: const BorderSide(color: AppColors.teal),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 10),

              // Suspend / Reactivate
              if (sitter.isSuspended) ...[
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _provider.reactivateUser(sitter.id);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Reactivate Babysitter Account', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ] else ...[
                OutlinedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final reason = await AdminActionDialog.show(
                      context,
                      title: 'Suspend Babysitter',
                      message: 'Are you sure you want to suspend ${sitter.name}?',
                      confirmText: 'Suspend Sitter',
                      confirmColor: const Color(0xFFDC2626),
                      requireReason: true,
                      reasonLabel: 'Suspension Reason *',
                    );
                    if (reason != null && reason.isNotEmpty) {
                      _provider.suspendUser(sitter.id, reason: reason);
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                    side: const BorderSide(color: Color(0xFFFCA5A5)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Suspend Babysitter Account', style: TextStyle(fontWeight: FontWeight.w700)),
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
        final sitters = _provider.users.where((u) => u.isBabysitter).toList();
        final isLoading = _provider.isInitialLoading;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: const Text(
              'Babysitter Management',
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
                    hintText: 'Search sitters by name or skill...',
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
                      '${sitters.length} Registered Babysitters',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                    ),
                    const Text('Caregiver Directory', style: TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8))),
                  ],
                ),
              ),

              // Sitters List
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: sitters.length,
                        itemBuilder: (context, index) {
                          final sitter = sitters[index];
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
                              onTap: () => _showSitterDetails(sitter),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: AppColors.mint,
                                    backgroundImage: sitter.avatar.isNotEmpty
                                        ? NetworkImage(sitter.avatar)
                                        : null,
                                    child: sitter.avatar.isEmpty
                                        ? Text(
                                            sitter.name.isNotEmpty ? sitter.name[0].toUpperCase() : 'B',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.teal,
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              sitter.name,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.ink,
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
                                                const SizedBox(width: 2),
                                                Text(
                                                  sitter.averageRating.toStringAsFixed(1),
                                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(sitter.email, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Text(
                                              '${sitter.totalBookings} Jobs completed',
                                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                                            ),
                                            const SizedBox(width: 8),
                                            const VerificationStatusChip(status: 'verified'),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
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
