import 'package:flutter/material.dart';

import '../../../config/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/local_storage.dart';
import '../models/babysitter_model.dart';
import '../providers/babysitter_provider.dart';
import '../services/babysitter_service.dart';
import '../widgets/verification_badge.dart';
import 'edit_sitter_profile_screen.dart';

class SitterProfileScreen extends StatefulWidget {
  const SitterProfileScreen({super.key});

  @override
  State<SitterProfileScreen> createState() => _SitterProfileScreenState();
}

class _SitterProfileScreenState extends State<SitterProfileScreen> {
  final BabysitterProvider _provider = BabysitterProvider.instance;
  String _userName = '';
  String _userEmail = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _provider.addListener(_onStateChanged);
    if (_provider.profile == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _provider.fetchProfile();
      });
    }
  }

  Future<void> _loadUserData() async {
    final name = await LocalStorage.instance.read('user_name');
    final email = await LocalStorage.instance.read('user_email');
    if (mounted && (name != null || email != null)) {
      setState(() {
        if (name != null && name.toString().isNotEmpty) {
          _userName = name.toString();
        }
        if (email != null && email.toString().isNotEmpty) {
          _userEmail = email.toString();
        }
      });
    }
  }

  @override
  void dispose() {
    _provider.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _handleRefresh() async {
    await _provider.fetchProfile(showLoading: false);
  }

  void _navigateToEdit(BabysitterModel profile) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditSitterProfileScreen(profile: profile),
      ),
    );
    if (updated == true && mounted) {
      _provider.fetchProfile();
    }
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
        content: const Text(
          'Are you sure you want to log out of your sitter account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.muted),
            ),
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
    final profile =
        _provider.profile ??
        BabysitterModel(
          id: 'temp',
          userId: 'u-temp',
          name: _userName.isNotEmpty ? _userName : 'Caregiver',
          email: _userEmail,
          averageRating: 0.0,
          totalReviews: 0,
          totalCompletedBookings: 0,
        );

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.ink,
                ),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: const Text(
          'Babysitter Profile',
          style: TextStyle(
            color: AppColors.ink,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.ink),
            tooltip: 'Edit Profile',
            onPressed: () => _navigateToEdit(profile),
          ),
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
            // Profile Card Header
            _buildProfileHeaderCard(profile),
            const SizedBox(height: 16),

            // Availability Status Toggle Card
            _buildAvailabilityToggleCard(profile),
            const SizedBox(height: 16),

            // Statistics Highlights
            _buildStatsRow(profile),
            const SizedBox(height: 16),

            // Biography
            _buildSectionCard(
              title: 'Biography / About Me',
              icon: Icons.person_outline_rounded,
              child: Text(
                profile.bio.isNotEmpty
                    ? profile.bio
                    : 'No biography added yet.',
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Skills
            _buildSectionCard(
              title: 'Skills & Capabilities',
              icon: Icons.verified_user_outlined,
              child: profile.skills.isNotEmpty
                  ? Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: profile.skills.map((skill) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.mint,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.teal.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            skill,
                            style: const TextStyle(
                              color: AppColors.teal,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                    )
                  : const Text(
                      'No skills listed',
                      style: TextStyle(color: AppColors.muted),
                    ),
            ),
            const SizedBox(height: 16),

            // Languages
            _buildSectionCard(
              title: 'Languages Spoken',
              icon: Icons.translate_rounded,
              child: profile.languages.isNotEmpty
                  ? Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: profile.languages.map((lang) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.sand,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            lang,
                            style: const TextStyle(
                              color: AppColors.ink,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                    )
                  : const Text(
                      'No languages listed',
                      style: TextStyle(color: AppColors.muted),
                    ),
            ),
            const SizedBox(height: 16),

            // Qualifications & Certifications
            _buildSectionCard(
              title: 'Qualifications & Certificates',
              icon: Icons.school_outlined,
              child: profile.qualifications.isNotEmpty
                  ? Column(
                      children: profile.qualifications.map((q) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.teal,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  q,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    )
                  : const Text(
                      'No qualifications listed',
                      style: TextStyle(color: AppColors.muted),
                    ),
            ),
            const SizedBox(height: 16),

            // Verification Documents
            _buildSectionCard(
              title: 'Verification Documents',
              icon: Icons.security_rounded,
              child: profile.documents.isNotEmpty
                  ? Column(
                      children: profile.documents
                          .map((doc) => _buildDocStatusRow(doc.name, doc.status))
                          .toList(),
                    )
                  : const Text(
                      'No verification documents uploaded yet',
                      style: TextStyle(color: AppColors.muted, fontSize: 13),
                    ),
            ),
            const SizedBox(height: 16),

            // Contact & Location Card
            _buildSectionCard(
              title: 'Contact & Location',
              icon: Icons.location_on_outlined,
              child: Column(
                children: [
                  _buildContactItem(
                    Icons.email_outlined,
                    'Email',
                    profile.email.isNotEmpty ? profile.email : 'Not provided',
                  ),
                  const Divider(height: 16, color: AppColors.sand),
                  _buildContactItem(
                    Icons.phone_outlined,
                    'Phone',
                    profile.phone.isNotEmpty
                        ? profile.phone
                        : 'Not provided',
                  ),
                  const Divider(height: 16, color: AppColors.sand),
                  _buildContactItem(
                    Icons.home_outlined,
                    'Address',
                    profile.address.isNotEmpty
                        ? profile.address
                        : 'Not provided',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Prominent Edit Profile Button
            FilledButton.icon(
              onPressed: () => _navigateToEdit(profile),
              icon: const Icon(Icons.edit_rounded, size: 18),
              label: const Text('Edit My Profile'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.ink,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
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

  Widget _buildProfileHeaderCard(BabysitterModel profile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: AppColors.mint,
                child: Text(
                  profile.name.trim().isNotEmpty
                      ? profile.name
                            .trim()
                            .split(' ')
                            .where((e) => e.isNotEmpty)
                            .map((e) => e[0].toUpperCase())
                            .take(2)
                            .join()
                      : 'CG',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.teal,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${profile.experienceYears} Years Experience',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    VerificationBadge(
                      status: profile.verificationStatus,
                      compact: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityToggleCard(BabysitterModel profile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: profile.isAvailable
              ? AppColors.teal.withValues(alpha: 0.3)
              : AppColors.sand,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: profile.isAvailable ? AppColors.teal : AppColors.muted,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.isAvailable
                      ? 'Available for Bookings'
                      : 'Unavailable / Off Duty',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  profile.isAvailable
                      ? 'Parents can discover you and send booking requests.'
                      : 'You are hidden from new parent requests.',
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
          Switch(
            value: profile.isAvailable,
            activeTrackColor: AppColors.teal,
            onChanged: (val) => _provider.toggleAvailability(val),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BabysitterModel profile) {
    return Row(
      children: [
        Expanded(
          child: _buildStatPill(
            label: 'Rating',
            value: profile.totalReviews > 0
                ? '★ ${profile.averageRating.toStringAsFixed(1)}'
                : '★ 0.0',
            sub: profile.totalReviews > 0
                ? '(${profile.totalReviews} reviews)'
                : 'No reviews',
            valueColor: AppColors.coral,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatPill(
            label: 'Hourly Rate',
            value: 'Rs. ${profile.hourlyRate.toInt()}',
            sub: 'per hour',
            valueColor: AppColors.teal,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatPill(
            label: 'Jobs Done',
            value: '${profile.totalCompletedBookings}',
            sub: 'completed',
            valueColor: AppColors.ink,
          ),
        ),
      ],
    );
  }

  Widget _buildStatPill({
    required String label,
    required String value,
    required String sub,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.muted),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: const TextStyle(fontSize: 10, color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.teal, size: 20),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildDocStatusRow(String docName, String status) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(
            Icons.file_present_rounded,
            color: AppColors.teal,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              docName,
              style: const TextStyle(fontSize: 13, color: AppColors.ink),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.mint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Verified',
              style: TextStyle(
                color: AppColors.teal,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.muted, size: 18),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppColors.muted),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
