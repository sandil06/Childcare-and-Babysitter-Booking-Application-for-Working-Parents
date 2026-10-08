
import 'package:flutter/material.dart';

import '../../../config/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../babysitter/models/babysitter_model.dart';
import '../../bookings/providers/booking_provider.dart';
import '../providers/parent_provider.dart';

class BabysitterProfileScreen extends StatelessWidget {
  const BabysitterProfileScreen({super.key});

  @override
  Widget build(BuildContext context) => const _BabysitterProfileView();
}

class _BabysitterProfileView extends StatefulWidget {
  const _BabysitterProfileView();

  @override
  State<_BabysitterProfileView> createState() => _BabysitterProfileViewState();
}

class _BabysitterProfileViewState extends State<_BabysitterProfileView>
    with SingleTickerProviderStateMixin {
  final _provider = ParentProvider.instance;

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _provider.addListener(_refresh);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _provider.removeListener(_refresh);
    _animationController.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _startBooking(BabysitterModel sitter) {
    BookingProvider.instance.reset();

    Navigator.pushNamed(
      context,
      AppRoutes.bookingDate,
    );
  }

  @override
  Widget build(BuildContext context) {
    final sitter = _provider.selectedBabysitter;

    if (sitter == null) {
      return Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(
          backgroundColor: AppColors.cream,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(
            color: AppColors.teal,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.pagePadding,
                8,
                AppSizes.pagePadding,
                120,
              ),
              children: [
                _buildHero(sitter),
                const SizedBox(height: 18),
                _buildTrustSummary(sitter),
                const SizedBox(height: 16),
                _buildQuickStats(sitter),
                const SizedBox(height: 16),
                _buildRateCard(sitter),
                const SizedBox(height: 16),
                _buildAbout(sitter),
                const SizedBox(height: 16),
                if (sitter.skills.isNotEmpty) ...[
                  _buildSkills(sitter),
                  const SizedBox(height: 16),
                ],
                if (sitter.languages.isNotEmpty) ...[
                  _buildLanguages(sitter),
                  const SizedBox(height: 16),
                ],
                if (sitter.qualifications.isNotEmpty) ...[
                  _buildCredentials(sitter),
                  const SizedBox(height: 16),
                ],
                _buildAvailability(sitter),
                const SizedBox(height: 16),
                _buildLocation(sitter),
                const SizedBox(height: 16),
                _buildTrustAndSafety(sitter),
              ],
            ),

            _buildBottomAction(sitter),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFF6F8FA),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Material(
          color: Colors.white,
          shape: const CircleBorder(),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            color: AppColors.ink,
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      title: const Text(
        'Babysitter profile',
        style: TextStyle(
          color: AppColors.ink,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildHero(BabysitterModel sitter) {
    final initials = _initials(sitter.name);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0B3C5D),
            Color(0xFF145B7D),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.45),
                    width: 3,
                  ),
                ),
                child: ClipOval(
                  child: sitter.profileImage != null &&
                          sitter.profileImage!.trim().isNotEmpty
                      ? Image.network(
                          sitter.profileImage!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _avatarInitials(initials),
                        )
                      : _avatarInitials(initials),
                ),
              ),
              if (sitter.isVerified)
                Positioned(
                  right: -3,
                  bottom: 2,
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: const BoxDecoration(
                      color: AppColors.teal,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.verified_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            sitter.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 7),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                sitter.isVerified
                    ? Icons.verified_rounded
                    : Icons.pending_rounded,
                color: sitter.isVerified
                    ? const Color(0xFF7CE8D7)
                    : Colors.white70,
                size: 17,
              ),
              const SizedBox(width: 6),
              Text(
                sitter.isVerified ? 'Verified babysitter' : 'Verification pending',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.88),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _heroPill(
                Icons.star_rounded,
                sitter.totalReviews > 0
                    ? sitter.averageRating.toStringAsFixed(1)
                    : 'New',
              ),
              _heroPill(
                Icons.rate_review_outlined,
                '${sitter.totalReviews} reviews',
              ),
              _heroPill(
                Icons.work_history_outlined,
                '${sitter.experienceYears} yrs experience',
              ),
            ],
          ),
          if (sitter.address.trim().isNotEmpty) ...[
            const SizedBox(height: 13),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  color: Colors.white70,
                  size: 17,
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    sitter.address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _avatarInitials(String initials) {
    return Container(
      color: const Color(0xFFE3F6F3),
      alignment: Alignment.center,
      child: Text(
        initials.isEmpty ? 'S' : initials,
        style: const TextStyle(
          color: AppColors.teal,
          fontSize: 30,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _heroPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: Colors.white,
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustSummary(BabysitterModel sitter) {
    final verified = sitter.isVerified;

    return _card(
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: verified
                  ? const Color(0xFFE5F8F4)
                  : const Color(0xFFFFF4DF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              verified
                  ? Icons.shield_rounded
                  : Icons.shield_outlined,
              color: verified
                  ? AppColors.teal
                  : const Color(0xFFC48A22),
              size: 24,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  verified
                      ? 'Verified profile'
                      : 'Verification in progress',
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  verified
                      ? 'Profile information has been verified by the platform.'
                      : 'Some profile information is still awaiting verification.',
                  style: const TextStyle(
                    color: AppColors.muted,
                    height: 1.35,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            verified
                ? Icons.check_circle_rounded
                : Icons.info_outline_rounded,
            color: verified
                ? AppColors.teal
                : AppColors.muted,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BabysitterModel sitter) {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            icon: Icons.workspace_premium_outlined,
            value: '${sitter.experienceYears}',
            label: 'Years experience',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            icon: Icons.star_outline_rounded,
            value: sitter.totalReviews > 0
                ? sitter.averageRating.toStringAsFixed(1)
                : 'New',
            label: 'Rating',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            icon: Icons.task_alt_rounded,
            value: '${sitter.totalCompletedBookings}',
            label: 'Completed',
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 15,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE9EEF1),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: AppColors.teal,
            size: 21,
          ),
          const SizedBox(height: 7),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRateCard(BabysitterModel sitter) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _sectionTitle(
                  'Hourly rate',
                  Icons.payments_outlined,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF8F5),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Text(
                  'STANDARD',
                  style: TextStyle(
                    color: AppColors.teal,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Rs. ${sitter.hourlyRate.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(
                  left: 5,
                  bottom: 5,
                ),
                child: Text(
                  '/ hour',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Final booking details are selected in the next step.',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAbout(BabysitterModel sitter) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            'About ${sitter.name}',
            Icons.person_outline_rounded,
          ),
          const SizedBox(height: 11),
          Text(
            sitter.bio.trim().isEmpty
                ? 'No biography has been provided by this babysitter yet.'
                : sitter.bio,
            style: const TextStyle(
              color: AppColors.muted,
              height: 1.55,
              fontSize: 13.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkills(BabysitterModel sitter) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            'Skills & specialties',
            Icons.auto_awesome_outlined,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: sitter.skills
                .map(
                  (skill) => _pill(
                    skill,
                    Icons.check_circle_outline_rounded,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguages(BabysitterModel sitter) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            'Languages',
            Icons.language_rounded,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: sitter.languages
                .map(
                  (language) => _pill(
                    language,
                    Icons.translate_rounded,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCredentials(BabysitterModel sitter) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _sectionTitle(
                  'Credentials & qualifications',
                  Icons.workspace_premium_outlined,
                ),
              ),
              if (sitter.isVerified)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF8F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'VERIFIED',
                    style: TextStyle(
                      color: AppColors.teal,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 13),
          if (sitter.qualificationItems.isNotEmpty)
            ...sitter.qualificationItems.map(
              (q) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      q.isVerified
                          ? Icons.check_circle_rounded
                          : Icons.school_outlined,
                      color: q.isVerified ? AppColors.teal : AppColors.muted,
                      size: 19,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  q.title,
                                  style: const TextStyle(
                                    color: AppColors.ink,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                              if (q.isVerified)
                                Container(
                                  margin: const EdgeInsets.only(left: 6),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEAF8F5),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Verified',
                                    style: TextStyle(
                                      color: AppColors.teal,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          if (q.institution != null &&
                              q.institution!.trim().isNotEmpty)
                            Text(
                              q.institution!,
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 11.5,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...sitter.qualifications.map(
              (qualification) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      sitter.isVerified
                          ? Icons.check_circle_rounded
                          : Icons.school_outlined,
                      color:
                          sitter.isVerified ? AppColors.teal : AppColors.muted,
                      size: 19,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        qualification,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvailability(BabysitterModel sitter) {
    final available = sitter.isAvailable;

    return _card(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: available
                  ? const Color(0xFFE7F8F3)
                  : const Color(0xFFF1F3F5),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              available
                  ? Icons.event_available_rounded
                  : Icons.event_busy_rounded,
              color: available
                  ? AppColors.teal
                  : AppColors.muted,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  available
                      ? 'Available for bookings'
                      : 'Currently unavailable',
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  available
                      ? 'You can continue to select a booking date.'
                      : 'This babysitter is not currently accepting bookings.',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: available
                  ? AppColors.teal
                  : AppColors.muted,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocation(BabysitterModel sitter) {
    if (sitter.address.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            'Location',
            Icons.location_on_outlined,
          ),
          const SizedBox(height: 11),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF8F5),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.place_outlined,
                  color: AppColors.teal,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  sitter.address,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrustAndSafety(BabysitterModel sitter) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF5F8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFD5E9EF),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Safety & trust',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  sitter.isVerified
                      ? 'This profile has a verified status on the platform. Always review the babysitter details before confirming a booking.'
                      : 'Review the babysitter information carefully before confirming a booking.',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction(BabysitterModel sitter) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            16,
            12,
            16,
            12,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.96),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 22,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF8F5),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: AppColors.teal,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: sitter.isAvailable
                      ? () => _startBooking(sitter)
                      : null,
                  icon: const Icon(
                    Icons.calendar_month_rounded,
                    size: 20,
                  ),
                  label: Text(
                    sitter.isAvailable
                        ? 'Book ${sitter.name}'
                        : 'Currently unavailable',
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.ink,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    disabledForegroundColor: Colors.grey.shade600,
                    padding: const EdgeInsets.symmetric(
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE8EDF0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF8F5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 18,
            color: AppColors.teal,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  Widget _pill(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF8F5),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: const Color(0xFFD6EEE9),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: AppColors.teal,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    return name
        .trim()
        .split(' ')
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0])
        .join()
        .toUpperCase();
  }
}

