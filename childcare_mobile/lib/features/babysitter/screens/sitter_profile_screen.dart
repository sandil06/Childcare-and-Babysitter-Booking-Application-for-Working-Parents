import 'package:flutter/material.dart';

import '../../../config/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/profile_image_service.dart';
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
  bool _isUploadingAvatar = false;

  Future<void> _handlePickAvatar() async {
    setState(() => _isUploadingAvatar = true);
    try {
      final newUrl = await ProfileImageService.instance.showImagePickerOptions(context, role: 'babysitter');
      if (!mounted) return;
      if (newUrl != null) {
        await _provider.fetchProfile(showLoading: false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated successfully!'),
            backgroundColor: AppColors.teal,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update picture: $e'),
            backgroundColor: AppColors.coral,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _provider.addListener(_onStateChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _provider.fetchProfile(showLoading: false);
    });
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
      await _provider.fetchProfile();
      setState(() {});
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
              onEdit: () => _editBio(profile),
              child: profile.bio.isNotEmpty
                  ? Text(
                      profile.bio,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    )
                  : InkWell(
                      onTap: () => _editBio(profile),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.cream,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.sand),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.add_circle_outline_rounded,
                              color: AppColors.teal,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'No biography added yet. Tap to add your bio.',
                                style: TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 16),

            // Skills
            _buildSectionCard(
              title: 'Skills & Capabilities',
              icon: Icons.verified_user_outlined,
              onEdit: () => _editSkills(profile),
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
                  : InkWell(
                      onTap: () => _editSkills(profile),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.cream,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.sand),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.add_circle_outline_rounded,
                              color: AppColors.teal,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'No skills listed. Tap to add your childcare skills.',
                                style: TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 16),

            // Languages
            _buildSectionCard(
              title: 'Languages Spoken',
              icon: Icons.translate_rounded,
              onEdit: () => _editLanguages(profile),
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
                  : InkWell(
                      onTap: () => _editLanguages(profile),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.cream,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.sand),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.add_circle_outline_rounded,
                              color: AppColors.teal,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'No languages listed. Tap to add languages spoken.',
                                style: TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 16),

            // Qualifications & Certifications
            _buildSectionCard(
              title: 'Qualifications & Certificates',
              icon: Icons.school_outlined,
              onEdit: () => _editQualifications(profile),
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
                  : InkWell(
                      onTap: () => _editQualifications(profile),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.cream,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.sand),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.add_circle_outline_rounded,
                              color: AppColors.teal,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'No qualifications listed. Tap to add certificates.',
                                style: TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 16),

            // Verification Documents
            _buildSectionCard(
              title: 'Verification Documents',
              icon: Icons.security_rounded,
              onEdit: () => _editDocuments(profile),
              child: profile.documents.isNotEmpty
                  ? Column(
                      children: profile.documents
                          .map((doc) => _buildDocStatusRow(
                                doc.name,
                                (profile.isVerified || profile.verificationStatus == 'verified')
                                    ? 'verified'
                                    : doc.status,
                              ))
                          .toList(),
                    )
                  : InkWell(
                      onTap: () => _editDocuments(profile),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.cream,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.sand),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.upload_file_rounded,
                              color: AppColors.teal,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'No verification documents uploaded yet. Tap to upload ID or certificates.',
                                style: TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 16),

            // Contact & Location Card
            _buildSectionCard(
              title: 'Contact & Location',
              icon: Icons.location_on_outlined,
              onEdit: () => _editContact(profile),
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
                        : 'Not provided (tap Edit to set)',
                  ),
                  const Divider(height: 16, color: AppColors.sand),
                  _buildContactItem(
                    Icons.home_outlined,
                    'Address',
                    profile.address.isNotEmpty
                        ? profile.address
                        : 'Not provided (tap Edit to set)',
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
              GestureDetector(
                onTap: _isUploadingAvatar ? null : _handlePickAvatar,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: AppColors.mint,
                      backgroundImage: (profile.profileImage != null && profile.profileImage!.isNotEmpty)
                          ? NetworkImage(ProfileImageService.resolveImageUrl(profile.profileImage!))
                          : null,
                      child: _isUploadingAvatar
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.teal,
                              ),
                            )
                          : ((profile.profileImage == null || profile.profileImage!.isEmpty)
                              ? Text(
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
                                )
                              : null),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.teal,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
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
    VoidCallback? onEdit,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.teal, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
              if (onEdit != null)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onEdit,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.mint,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit_rounded, size: 14, color: AppColors.teal),
                          SizedBox(width: 4),
                          Text(
                            'Edit',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.teal,
                            ),
                          ),
                        ],
                      ),
                    ),
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
    final s = status.toLowerCase();
    final isVer = s == 'verified';
    final isRejected = s == 'rejected';
    final isChangesReq = s == 'changes_requested';
    Color badgeBg;
    Color badgeFg;
    String badgeLabel;

    if (isVer) {
      badgeBg = AppColors.mint;
      badgeFg = AppColors.teal;
      badgeLabel = 'Verified';
    } else if (isRejected) {
      badgeBg = const Color(0xFFFDE8E8);
      badgeFg = AppColors.coral;
      badgeLabel = 'Rejected';
    } else if (isChangesReq) {
      badgeBg = const Color(0xFFFEF3C7);
      badgeFg = const Color(0xFFD97706);
      badgeLabel = 'Action Required';
    } else {
      badgeBg = const Color(0xFFE8EEF5);
      badgeFg = const Color(0xFF336699);
      badgeLabel = 'Pending';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            isVer
                ? Icons.verified_user_rounded
                : isRejected
                    ? Icons.cancel_outlined
                    : isChangesReq
                        ? Icons.edit_note_rounded
                        : Icons.file_present_rounded,
            color: isVer
                ? AppColors.teal
                : isRejected
                    ? AppColors.coral
                    : isChangesReq
                        ? const Color(0xFFD97706)
                        : AppColors.muted,
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
              color: badgeBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              badgeLabel,
              style: TextStyle(
                color: badgeFg,
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

  Future<void> _editBio(BabysitterModel profile) async {
    final controller = TextEditingController(text: profile.bio);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        bool saving = false;
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
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
                        color: AppColors.sand,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Edit Biography',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Introduce yourself, share your childcare philosophy, and highlight your experience.',
                    style: TextStyle(fontSize: 13, color: AppColors.muted),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    maxLines: 4,
                    style: const TextStyle(fontSize: 14, color: AppColors.ink),
                    decoration: InputDecoration(
                      hintText: 'e.g. Caring babysitter with over 4 years of hands-on experience...',
                      filled: true,
                      fillColor: AppColors.cream,
                      contentPadding: const EdgeInsets.all(14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: saving
                          ? null
                          : () async {
                              setModalState(() => saving = true);
                              final bioText = controller.text.trim();
                              final ok = await _provider.updateProfile({'bio': bioText});
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(ok
                                        ? 'Biography updated successfully!'
                                        : (_provider.errorMessage ??
                                            'Failed to update biography')),
                                    backgroundColor:
                                        ok ? AppColors.teal : AppColors.coral,
                                  ),
                                );
                                setState(() {});
                              }
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.teal,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Save Biography', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _editSkills(BabysitterModel profile) async {
    final selected = Set<String>.from(profile.skills);
    final customCtrl = TextEditingController();
    final allStandard = [
      'Infant Care',
      'Toddler Care',
      'First Aid & CPR',
      'Meal Preparation',
      'Homework Help',
      'Special Needs Care',
      'Bedtime Routines',
      'Child Activities',
      'Creative Arts',
      'Potty Training',
    ];
    final displaySkills = {...allStandard, ...selected}.toList();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        bool saving = false;
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.sand,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Edit Skills & Capabilities',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Select skills you offer or add custom childcare capabilities.',
                      style: TextStyle(fontSize: 13, color: AppColors.muted),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: displaySkills.map((s) {
                        final isSel = selected.contains(s);
                        return FilterChip(
                          selected: isSel,
                          label: Text(s),
                          labelStyle: TextStyle(
                            color: isSel ? Colors.white : AppColors.ink,
                            fontWeight: isSel ? FontWeight.w600 : FontWeight.normal,
                            fontSize: 13,
                          ),
                          backgroundColor: AppColors.cream,
                          selectedColor: AppColors.teal,
                          checkmarkColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: isSel ? AppColors.teal : AppColors.sand,
                            ),
                          ),
                          onSelected: (val) {
                            setModalState(() {
                              if (val) {
                                selected.add(s);
                              } else {
                                selected.remove(s);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: customCtrl,
                            decoration: InputDecoration(
                              hintText: 'Add custom skill...',
                              hintStyle: const TextStyle(fontSize: 13, color: AppColors.muted),
                              filled: true,
                              fillColor: AppColors.cream,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: () {
                            final text = customCtrl.text.trim();
                            if (text.isNotEmpty) {
                              setModalState(() {
                                if (!displaySkills.contains(text)) {
                                  displaySkills.add(text);
                                }
                                selected.add(text);
                                customCtrl.clear();
                              });
                            }
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.ink,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Add'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: saving
                            ? null
                            : () async {
                                final pending = customCtrl.text.trim();
                                if (pending.isNotEmpty) {
                                  selected.add(pending);
                                  customCtrl.clear();
                                }
                                setModalState(() => saving = true);
                                final ok = await _provider.updateProfile({'skills': selected.toList()});
                                if (ctx.mounted) Navigator.pop(ctx);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(ok
                                          ? 'Skills updated successfully!'
                                          : (_provider.errorMessage ??
                                              'Failed to update skills')),
                                      backgroundColor:
                                          ok ? AppColors.teal : AppColors.coral,
                                    ),
                                  );
                                  setState(() {});
                                }
                              },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.teal,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Save Skills', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _editLanguages(BabysitterModel profile) async {
    final selected = Set<String>.from(profile.languages);
    final customCtrl = TextEditingController();
    final allStandard = [
      'Sinhala',
      'English',
      'Tamil',
      'French',
      'German',
      'Mandarin',
      'Arabic',
      'Sign Language',
    ];
    final displayLangs = {...allStandard, ...selected}.toList();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        bool saving = false;
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.sand,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Edit Languages Spoken',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Select languages you can comfortably communicate with children and parents.',
                      style: TextStyle(fontSize: 13, color: AppColors.muted),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: displayLangs.map((l) {
                        final isSel = selected.contains(l);
                        return FilterChip(
                          selected: isSel,
                          label: Text(l),
                          labelStyle: TextStyle(
                            color: isSel ? Colors.white : AppColors.ink,
                            fontWeight: isSel ? FontWeight.w600 : FontWeight.normal,
                            fontSize: 13,
                          ),
                          backgroundColor: AppColors.cream,
                          selectedColor: AppColors.ink,
                          checkmarkColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: isSel ? AppColors.ink : AppColors.sand,
                            ),
                          ),
                          onSelected: (val) {
                            setModalState(() {
                              if (val) {
                                selected.add(l);
                              } else {
                                selected.remove(l);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: customCtrl,
                            decoration: InputDecoration(
                              hintText: 'Add custom language...',
                              hintStyle: const TextStyle(fontSize: 13, color: AppColors.muted),
                              filled: true,
                              fillColor: AppColors.cream,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: () {
                            final text = customCtrl.text.trim();
                            if (text.isNotEmpty) {
                              setModalState(() {
                                if (!displayLangs.contains(text)) {
                                  displayLangs.add(text);
                                }
                                selected.add(text);
                                customCtrl.clear();
                              });
                            }
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.ink,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Add'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: saving
                            ? null
                            : () async {
                                final pending = customCtrl.text.trim();
                                if (pending.isNotEmpty) {
                                  selected.add(pending);
                                  customCtrl.clear();
                                }
                                setModalState(() => saving = true);
                                final langs = selected.isEmpty ? ['English'] : selected.toList();
                                final ok = await _provider.updateProfile({'languages': langs});
                                if (ctx.mounted) Navigator.pop(ctx);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(ok
                                          ? 'Languages updated successfully!'
                                          : (_provider.errorMessage ??
                                              'Failed to update languages')),
                                      backgroundColor:
                                          ok ? AppColors.teal : AppColors.coral,
                                    ),
                                  );
                                  setState(() {});
                                }
                              },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.teal,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Save Languages', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _editQualifications(BabysitterModel profile) async {
    final list = List<String>.from(profile.qualifications);
    final ctrl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        bool saving = false;
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
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
                        color: AppColors.sand,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Qualifications & Certificates',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Add educational certificates, diplomas, or professional qualifications.',
                    style: TextStyle(fontSize: 13, color: AppColors.muted),
                  ),
                  const SizedBox(height: 16),
                  if (list.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.cream,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'No qualifications added yet. Type a qualification title below.',
                        style: TextStyle(fontSize: 13, color: AppColors.muted),
                      ),
                    )
                  else
                    ...list.asMap().entries.map((e) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.cream,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.sand),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.school_outlined, size: 18, color: AppColors.teal),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                e.value,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.muted),
                              onPressed: () => setModalState(() => list.removeAt(e.key)),
                            ),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: ctrl,
                          decoration: InputDecoration(
                            hintText: 'e.g. Early Childhood Care Diploma (NVQ 4)',
                            hintStyle: const TextStyle(fontSize: 13, color: AppColors.muted),
                            filled: true,
                            fillColor: AppColors.cream,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () {
                          final text = ctrl.text.trim();
                          if (text.isNotEmpty) {
                            setModalState(() {
                              list.add(text);
                              ctrl.clear();
                            });
                          }
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.teal,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: saving
                          ? null
                          : () async {
                              final pending = ctrl.text.trim();
                              if (pending.isNotEmpty) {
                                list.add(pending);
                                ctrl.clear();
                              }
                              setModalState(() => saving = true);
                              final ok = await _provider.updateProfile({'qualifications': list});
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(ok
                                        ? 'Qualifications updated successfully!'
                                        : (_provider.errorMessage ??
                                            'Failed to update qualifications')),
                                    backgroundColor:
                                        ok ? AppColors.teal : AppColors.coral,
                                  ),
                                );
                                setState(() {});
                              }
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.teal,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Save Qualifications', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _editDocuments(BabysitterModel profile) async {
    final docs = List<VerificationDocumentModel>.from(profile.documents);
    final docNameCtrl = TextEditingController();
    String docType = 'id';
    final docTypeLabels = {
      'id': 'National ID / NIC',
      'police_check': 'Police Background Check',
      'qualification': 'Childcare Certificate / Degree',
      'certificate': 'First Aid / CPR Certification',
      'other': 'Other Document',
    };

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        bool saving = false;
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.sand,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Verification Documents',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Submit and verify your identity, background clearances, and certifications.',
                      style: TextStyle(fontSize: 13, color: AppColors.muted),
                    ),
                    const SizedBox(height: 16),
                    if (docs.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.cream,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'No documents uploaded yet. Choose a document type and name below.',
                          style: TextStyle(fontSize: 13, color: AppColors.muted),
                        ),
                      )
                    else
                      ...docs.asMap().entries.map((e) {
                        final d = e.value;
                        final isVer = d.status == 'verified';
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.cream,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.sand),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isVer ? Icons.verified_user_rounded : Icons.description_outlined,
                                size: 18,
                                color: isVer ? AppColors.teal : AppColors.ink,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      d.name,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                    Text(
                                      docTypeLabels[d.type] ?? d.type,
                                      style: const TextStyle(fontSize: 11, color: AppColors.muted),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                margin: const EdgeInsets.only(right: 4),
                                decoration: BoxDecoration(
                                  color: isVer ? AppColors.mint : AppColors.sand.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isVer ? 'Verified' : 'Pending',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: isVer ? AppColors.teal : AppColors.ink,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.muted),
                                onPressed: () => setModalState(() => docs.removeAt(e.key)),
                              ),
                            ],
                          ),
                        );
                      }),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.cream,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.sand),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Add New Document',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            initialValue: docType,
                            decoration: InputDecoration(
                              labelText: 'Document Type',
                              labelStyle: const TextStyle(color: AppColors.muted, fontSize: 12),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            items: docTypeLabels.entries.map((entry) {
                              return DropdownMenuItem(
                                value: entry.key,
                                child: Text(entry.value, style: const TextStyle(fontSize: 13)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setModalState(() => docType = val);
                            },
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: docNameCtrl,
                                  decoration: InputDecoration(
                                    labelText: 'Document Title',
                                    hintText: 'e.g. NIC 199012345678',
                                    labelStyle: const TextStyle(color: AppColors.muted, fontSize: 12),
                                    hintStyle: const TextStyle(color: AppColors.muted, fontSize: 12),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              FilledButton(
                                onPressed: () {
                                  final name = docNameCtrl.text.trim();
                                  if (name.isNotEmpty) {
                                    setModalState(() {
                                      docs.add(
                                        VerificationDocumentModel(
                                          type: docType,
                                          name: name,
                                          status: 'pending',
                                          uploadedAt: DateTime.now(),
                                        ),
                                      );
                                      docNameCtrl.clear();
                                    });
                                  }
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.teal,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: const Text('Add'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: saving
                            ? null
                            : () async {
                                final pendingName = docNameCtrl.text.trim();
                                if (pendingName.isNotEmpty) {
                                  docs.add(
                                    VerificationDocumentModel(
                                      type: docType,
                                      name: pendingName,
                                      status: 'pending',
                                      uploadedAt: DateTime.now(),
                                    ),
                                  );
                                  docNameCtrl.clear();
                                }
                                setModalState(() => saving = true);
                                final payload = docs.map((d) => d.toJson()).toList();
                                final ok = await _provider.updateProfile({'documents': payload});
                                if (ctx.mounted) Navigator.pop(ctx);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(ok
                                          ? 'Documents updated successfully!'
                                          : (_provider.errorMessage ??
                                              'Failed to update documents')),
                                      backgroundColor:
                                          ok ? AppColors.teal : AppColors.coral,
                                    ),
                                  );
                                  setState(() {});
                                }
                              },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.teal,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Save Documents', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _editContact(BabysitterModel profile) async {
    final phoneCtrl = TextEditingController(text: profile.phone);
    final addressCtrl = TextEditingController(text: profile.address);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        bool saving = false;
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
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
                        color: AppColors.sand,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Edit Contact & Location',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Keep your phone number and location updated for verified bookings.',
                    style: TextStyle(fontSize: 13, color: AppColors.muted),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      hintText: '+94 77 123 4567',
                      filled: true,
                      fillColor: AppColors.cream,
                      prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.teal, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: addressCtrl,
                    decoration: InputDecoration(
                      labelText: 'Street Address & City',
                      hintText: 'No. 45, Galle Road, Colombo 03',
                      filled: true,
                      fillColor: AppColors.cream,
                      prefixIcon: const Icon(Icons.home_outlined, color: AppColors.teal, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: saving
                          ? null
                          : () async {
                              setModalState(() => saving = true);
                              final ok = await _provider.updateProfile({
                                'phone': phoneCtrl.text.trim(),
                                'address': addressCtrl.text.trim(),
                              });
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(ok
                                        ? 'Contact details updated successfully!'
                                        : (_provider.errorMessage ??
                                            'Failed to update contact details')),
                                    backgroundColor:
                                        ok ? AppColors.teal : AppColors.coral,
                                  ),
                                );
                                setState(() {});
                              }
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.teal,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Save Contact Details', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
