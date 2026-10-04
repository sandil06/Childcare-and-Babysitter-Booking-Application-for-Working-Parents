import 'package:flutter/material.dart';

import '../../../config/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/local_storage.dart';
import '../../babysitter/providers/babysitter_provider.dart';
import '../../babysitter/services/babysitter_service.dart';

class ParentProfileScreen extends StatefulWidget {
  const ParentProfileScreen({super.key});

  @override
  State<ParentProfileScreen> createState() => _ParentProfileScreenState();
}

class _ParentProfileScreenState extends State<ParentProfileScreen> {
  // Retain data during refresh - do not clear to null
  final Map<String, dynamic> _parentProfile = {
    'name': 'Parent',
    'email': '',
    'phone': '+94 77 987 6543',
    'address': 'No. 28, Alfred Place, Colombo 03',
    'childrenCount': 2,
    'emergencyContact': '+94 71 234 5678',
    'isNicVerified': true,
  };

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final name = await LocalStorage.instance.read('user_name');
    final email = await LocalStorage.instance.read('user_email');
    if (mounted && (name != null || email != null)) {
      setState(() {
        if (name != null && name.toString().isNotEmpty) {
          _parentProfile['name'] = name.toString();
        }
        if (email != null && email.toString().isNotEmpty) {
          _parentProfile['email'] = email.toString();
        }
      });
    }
  }

  Future<void> _handleRefresh() async {
    // Keep existing data visible, do not clear to null, do not show full-screen loader
    await Future.delayed(const Duration(milliseconds: 600));
    await _loadProfile();
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Log Out',
          style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700),
        ),
        content: const Text('Are you sure you want to log out of LittleHands?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.muted)),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await LocalStorage.instance.remove('auth_token');
              await LocalStorage.instance.remove('user_name');
              await LocalStorage.instance.remove('user_email');
              await LocalStorage.instance.remove('user_id');
              await LocalStorage.instance.remove('user_role');
              ApiClient.authToken = null;
              BabysitterService.clearCurrentProfile();
              BabysitterProvider.instance.reset();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.login,
                  (_) => false,
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.coral,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: const Text(
          'Family Profile',
          style: TextStyle(
            color: AppColors.ink,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.coral),
            tooltip: 'Log Out',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(overscroll: false),
        child: RefreshIndicator(
          displacement: 20,
          edgeOffset: 0,
          onRefresh: _handleRefresh,
          color: AppColors.teal,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: ClampingScrollPhysics(),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.pagePadding,
              vertical: 16,
            ),
            children: [
              // Profile Header Card
              _buildHeaderCard(),
              const SizedBox(height: 16),

              // Verification Badge Card
              _buildVerificationCard(),
              const SizedBox(height: 16),

              // Children Section
              _buildChildrenCard(),
              const SizedBox(height: 16),

              // Contact & Address Card
              _buildContactCard(),
              const SizedBox(height: 24),

              // Sitter Mode Switcher
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.sitterDashboard),
                  icon: const Icon(Icons.swap_horiz_rounded, color: AppColors.teal),
                  label: const Text(
                    'Switch to Sitter Mode',
                    style: TextStyle(color: AppColors.teal, fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.teal),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: AppColors.mint,
            child: const Icon(
              Icons.family_restroom_rounded,
              size: 34,
              color: AppColors.teal,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _parentProfile['name'] as String,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _parentProfile['email'] as String,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F5F2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Verified Parent • Sri Lanka',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF005B60),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.security_rounded, size: 20, color: AppColors.teal),
              SizedBox(width: 8),
              Text(
                'Trust & Verification',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: AppColors.sand),
          _buildStatusRow('National Identity Card (NIC)', 'Verified'),
          const SizedBox(height: 10),
          _buildStatusRow('Sri Lanka Phone Number', 'Verified'),
          const SizedBox(height: 10),
          _buildStatusRow('Emergency Contact Linked', 'Verified'),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String status) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.ink)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFE6F5F2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            status,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF005B60),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChildrenCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Children Information',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              Text(
                '2 registered',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.teal,
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: AppColors.sand),
          _buildChildTile('Nethmi Silva', '3 years old · Needs afternoon supervision'),
          const SizedBox(height: 12),
          _buildChildTile('Senuka Silva', '6 years old · School pickup & homework help'),
        ],
      ),
    );
  }

  Widget _buildChildTile(String name, String sub) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.mint,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.child_care_rounded, size: 20, color: AppColors.teal),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sub,
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Contact Details',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const Divider(height: 24, color: AppColors.sand),
          _buildDetailRow(Icons.phone_outlined, 'Phone', _parentProfile['phone'] as String),
          const SizedBox(height: 14),
          _buildDetailRow(Icons.location_on_outlined, 'Home Address', _parentProfile['address'] as String),
          const SizedBox(height: 14),
          _buildDetailRow(Icons.contact_phone_outlined, 'Emergency Contact', _parentProfile['emergencyContact'] as String),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.teal),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11.5, color: AppColors.muted),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
