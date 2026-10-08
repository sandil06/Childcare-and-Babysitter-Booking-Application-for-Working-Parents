import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../models/verification_request_model.dart';
import '../providers/agency_provider.dart';
import '../widgets/admin_action_dialog.dart';
import '../widgets/document_preview_dialog.dart';
import '../widgets/verification_status_chip.dart';

class SitterVerificationScreen extends StatefulWidget {
  final VerificationRequestModel? request;
  final String? verificationId;

  const SitterVerificationScreen({
    super.key,
    this.request,
    this.verificationId,
  });

  @override
  State<SitterVerificationScreen> createState() => _SitterVerificationScreenState();
}

class _SitterVerificationScreenState extends State<SitterVerificationScreen>
    with SingleTickerProviderStateMixin {
  late final AgencyProvider _provider;
  late final TabController _tabController;
  VerificationRequestModel? _currentRequest;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _provider = AgencyProvider.instance;
    _tabController = TabController(length: 4, vsync: this);
    _currentRequest = widget.request ?? _provider.selectedVerification;

    if (_currentRequest == null && widget.verificationId != null) {
      _loadDetails(widget.verificationId!);
    }
  }

  Future<void> _loadDetails(String id) async {
    setState(() => _isLoading = true);
    final detail = await _provider.loadVerificationDetails(id);
    if (mounted) {
      setState(() {
        _currentRequest = detail;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleApprove() async {
    final req = _currentRequest;
    if (req == null) return;

    final notes = await AdminActionDialog.show(
      context,
      title: 'Approve Babysitter',
      message:
          'Are you sure you want to approve ${req.name}? Their profile will be marked as verified and will appear on the parent booking catalog.',
      confirmText: 'Approve & Verify',
      confirmColor: AppColors.teal,
      icon: Icons.verified_user_rounded,
      requireReason: false,
      reasonLabel: 'Approval Note (Optional)',
      reasonHint: 'e.g. All documents validated against police database.',
    );

    if (notes == null) return; // User cancelled

    final targetId = (req.id.isNotEmpty && !req.id.startsWith('req-'))
        ? req.id
        : (req.babysitterId.isNotEmpty ? req.babysitterId : req.id);
    final success = await _provider.approveVerification(targetId, notes: notes);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${req.name} has been successfully verified!'),
          backgroundColor: AppColors.teal,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_provider.errorMessage ?? 'Failed to approve verification.'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleRequestChanges() async {
    final req = _currentRequest;
    if (req == null) return;

    final notes = await AdminActionDialog.show(
      context,
      title: 'Request Changes',
      message:
          'Please specify the missing or unclear documents that ${req.name} needs to resubmit.',
      confirmText: 'Send Request',
      confirmColor: const Color(0xFFD97706),
      icon: Icons.edit_note_rounded,
      requireReason: true,
      reasonLabel: 'Instructions for Babysitter *',
      reasonHint: 'e.g. Please re-upload a clear copy of your Police Clearance Report.',
    );

    if (notes == null || notes.isEmpty) return;

    final targetId = (req.id.isNotEmpty && !req.id.startsWith('req-'))
        ? req.id
        : (req.babysitterId.isNotEmpty ? req.babysitterId : req.id);
    final success = await _provider.requestChangesVerification(targetId, notes: notes);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Change request sent to ${req.name}.'),
          backgroundColor: const Color(0xFFD97706),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_provider.errorMessage ?? 'Failed to request changes.'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleReject() async {
    final req = _currentRequest;
    if (req == null) return;

    final reason = await AdminActionDialog.show(
      context,
      title: 'Reject Application',
      message:
          'This will reject the verification request for ${req.name}. The sitter will be notified with the reason.',
      confirmText: 'Reject Application',
      confirmColor: const Color(0xFFDC2626),
      icon: Icons.gpp_bad_rounded,
      requireReason: true,
      reasonLabel: 'Reason for Rejection *',
      reasonHint: 'e.g. Identity documents could not be validated.',
    );

    if (reason == null || reason.isEmpty) return;

    final targetId = (req.id.isNotEmpty && !req.id.startsWith('req-'))
        ? req.id
        : (req.babysitterId.isNotEmpty ? req.babysitterId : req.id);
    final success = await _provider.rejectVerification(targetId, reason: reason);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Application for ${req.name} was rejected.'),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_provider.errorMessage ?? 'Failed to reject verification.'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final req = _currentRequest;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Verification Review',
          style: TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.ink),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (req != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(child: VerificationStatusChip(status: req.status)),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: false,
              labelColor: AppColors.teal,
              unselectedLabelColor: const Color(0xFF64748B),
              indicatorColor: AppColors.teal,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              tabs: const [
                Tab(text: 'Personal'),
                Tab(text: 'Professional'),
                Tab(text: 'Documents'),
                Tab(text: 'Audit'),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
          : req == null
              ? const Center(
                  child: Text(
                    'Verification request not found',
                    style: TextStyle(color: AppColors.muted),
                  ),
                )
              : Column(
                  children: [
                    // Sitter Profile Header Banner
                    _buildProfileSummary(req),

                    // Tab View
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildPersonalTab(req),
                          _buildProfessionalTab(req),
                          _buildDocumentsTab(req),
                          _buildAuditTab(req),
                        ],
                      ),
                    ),

                    // Bottom Action Toolbar
                    _buildBottomActionBar(req),
                  ],
                ),
    );
  }

  Widget _buildProfileSummary(VerificationRequestModel req) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: const Color(0xFFE6F5F2),
            backgroundImage: req.avatar.isNotEmpty ? NetworkImage(req.avatar) : null,
            child: req.avatar.isEmpty
                ? Text(
                    req.name.isNotEmpty ? req.name[0].toUpperCase() : 'B',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.teal,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  req.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: AppColors.muted),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        req.address.isNotEmpty ? req.address : 'Location provided in review',
                        style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Submitted ${req.submittedAt != null ? "${req.submittedAt!.day}/${req.submittedAt!.month}/${req.submittedAt!.year}" : "Recently"}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalTab(VerificationRequestModel req) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionCard(
          title: 'Contact Information',
          icon: Icons.contact_mail_outlined,
          children: [
            _buildDetailRow(Icons.email_outlined, 'Email Address', req.email),
            const Divider(height: 20, color: Color(0xFFF1F5F9)),
            _buildDetailRow(Icons.phone_outlined, 'Phone Number', req.phone.isNotEmpty ? req.phone : 'Not specified'),
            const Divider(height: 20, color: Color(0xFFF1F5F9)),
            _buildDetailRow(Icons.home_outlined, 'Residential Address', req.address.isNotEmpty ? req.address : 'Not specified'),
          ],
        ),
        const SizedBox(height: 14),
        _buildSectionCard(
          title: 'Identity & Bio',
          icon: Icons.person_outline_rounded,
          children: [
            _buildDetailRow(Icons.wc_outlined, 'Gender', req.gender.isNotEmpty ? req.gender : 'Female'),
            const Divider(height: 20, color: Color(0xFFF1F5F9)),
            _buildDetailRow(
              Icons.cake_outlined,
              'Date of Birth',
              req.dateOfBirth != null
                  ? '${req.dateOfBirth!.day}/${req.dateOfBirth!.month}/${req.dateOfBirth!.year}'
                  : '15/06/1996 (30 yrs)',
            ),
            const Divider(height: 20, color: Color(0xFFF1F5F9)),
            const Text(
              'Caregiver Biography',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              req.bio.isNotEmpty
                  ? req.bio
                  : 'Professional and reliable childcare provider with a passion for child development, education, and early infant care.',
              style: const TextStyle(
                fontSize: 13.5,
                color: AppColors.ink,
                height: 1.5,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProfessionalTab(VerificationRequestModel req) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Rate & Experience Highlights
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                title: 'Hourly Rate',
                value: 'LKR ${req.hourlyRate.toStringAsFixed(0)}',
                subtitle: 'Per Hour',
                icon: Icons.payments_outlined,
                color: AppColors.teal,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricTile(
                title: 'Experience',
                value: '${req.experienceYears} Years',
                subtitle: 'Active Childcare',
                icon: Icons.workspace_premium_outlined,
                color: const Color(0xFF0284C7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Age Groups Handled
        _buildSectionCard(
          title: 'Age Groups Handled',
          icon: Icons.child_care_rounded,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (req.ageGroups.isNotEmpty
                      ? req.ageGroups
                      : const ['Infants (0-1 yr)', 'Toddlers (1-3 yrs)', 'Pre-school (3-5 yrs)'])
                  .map((age) => Chip(
                        label: Text(age),
                        backgroundColor: const Color(0xFFF0FDF4),
                        labelStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF166534),
                        ),
                        avatar: const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF16A34A)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: Color(0xFFBBF7D0)),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Skills & Specializations
        _buildSectionCard(
          title: 'Skills & Capabilities',
          icon: Icons.star_outline_rounded,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (req.skills.isNotEmpty
                      ? req.skills
                      : const ['First Aid & CPR', 'Creative Play', 'Meal Prep', 'Infant Care'])
                  .map((skill) => Chip(
                        label: Text(skill),
                        backgroundColor: AppColors.mint,
                        labelStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.teal,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: AppColors.teal.withValues(alpha: 0.2)),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Languages
        _buildSectionCard(
          title: 'Languages Spoken',
          icon: Icons.translate_rounded,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (req.languages.isNotEmpty
                      ? req.languages
                      : const ['English', 'Sinhala'])
                  .map((lang) => Chip(
                        label: Text(lang),
                        backgroundColor: const Color(0xFFF1F5F9),
                        labelStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Qualifications
        _buildSectionCard(
          title: 'Qualifications & Certifications',
          icon: Icons.school_outlined,
          children: [
            if (req.qualifications.isEmpty)
              const Text(
                'No formal qualifications listed.',
                style: TextStyle(fontSize: 13, color: AppColors.muted),
              )
            else
              ...req.qualifications.map(
                (q) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppColors.mint,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.school, size: 14, color: AppColors.teal),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          q,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildDocumentsTab(VerificationRequestModel req) {
    final docs = req.documents;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(AppSizes.radius),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, size: 20, color: Color(0xFF2563EB)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${docs.length} Verification documents submitted. Tap any document to inspect full preview and zoom.',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF1E40AF),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        if (docs.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            alignment: Alignment.center,
            child: const Text(
              'No documents uploaded for this application.',
              style: TextStyle(color: AppColors.muted),
            ),
          )
        else
          ...docs.map((doc) => _buildDocCard(doc)),
      ],
    );
  }

  Widget _buildDocCard(VerificationDocItem doc) {
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.mint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(doc.iconData, color: AppColors.teal, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc.name,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  doc.displayType,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  doc.uploadedAt != null
                      ? 'Uploaded ${doc.uploadedAt!.day}/${doc.uploadedAt!.month}/${doc.uploadedAt!.year}'
                      : 'Uploaded recently',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            onPressed: () => DocumentPreviewDialog.show(context, doc),
            icon: const Icon(Icons.visibility_outlined, size: 16),
            label: const Text('View'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.teal,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditTab(VerificationRequestModel req) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionCard(
          title: 'Review Audit Details',
          icon: Icons.history_edu_rounded,
          children: [
            _buildDetailRow(
              Icons.flag_outlined,
              'Current Status',
              req.status.toUpperCase(),
            ),
            const Divider(height: 20, color: Color(0xFFF1F5F9)),
            _buildDetailRow(
              Icons.calendar_today_outlined,
              'Submission Date',
              req.submittedAt != null
                  ? '${req.submittedAt!.day}/${req.submittedAt!.month}/${req.submittedAt!.year}'
                  : 'N/A',
            ),
            const Divider(height: 20, color: Color(0xFFF1F5F9)),
            _buildDetailRow(
              Icons.verified_user_outlined,
              'Reviewed By',
              req.reviewedBy ?? 'Not yet reviewed',
            ),
            const Divider(height: 20, color: Color(0xFFF1F5F9)),
            _buildDetailRow(
              Icons.access_time_rounded,
              'Review Timestamp',
              req.reviewedAt != null
                  ? '${req.reviewedAt!.day}/${req.reviewedAt!.month}/${req.reviewedAt!.year}'
                  : 'Pending Review',
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (req.reviewNotes.isNotEmpty) ...[
          _buildSectionCard(
            title: 'Administrative Review Notes',
            icon: Icons.notes_rounded,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  req.reviewNotes,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.ink,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildBottomActionBar(VerificationRequestModel req) {
    final isAlreadyVerified = req.status.toLowerCase() == 'verified';
    final isAlreadyRejected = req.status.toLowerCase() == 'rejected';

    if (isAlreadyVerified) {
      return Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFDCFCE7),
            borderRadius: BorderRadius.circular(AppSizes.radius),
            border: Border.all(color: const Color(0xFF86EFAC)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_rounded, color: Color(0xFF15803D), size: 20),
              SizedBox(width: 8),
              Text(
                'This Babysitter has already been Approved & Verified.',
                style: TextStyle(
                  color: Color(0xFF15803D),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (isAlreadyRejected) {
      return Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFEE2E2),
            borderRadius: BorderRadius.circular(AppSizes.radius),
            border: Border.all(color: const Color(0xFFFCA5A5)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cancel_rounded, color: Color(0xFFB91C1C), size: 20),
              SizedBox(width: 8),
              Text(
                'This verification application has been Rejected.',
                style: TextStyle(
                  color: Color(0xFFB91C1C),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SafeArea(
        child: Row(
          children: [
            // Reject Button
            OutlinedButton(
              onPressed: _handleReject,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFDC2626),
                side: const BorderSide(color: Color(0xFFFCA5A5)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.close_rounded, size: 16),
                  SizedBox(width: 4),
                  Text('Reject', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Request Changes Button
            OutlinedButton(
              onPressed: _handleRequestChanges,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFD97706),
                side: const BorderSide(color: Color(0xFFFCD34D)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.edit_note_rounded, size: 18),
                  SizedBox(width: 4),
                  Text('Changes', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Approve Button (Primary)
            Expanded(
              child: ElevatedButton(
                onPressed: _handleApprove,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.verified_rounded, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Approve Sitter',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.teal),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 10),
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
              Icon(icon, size: 18, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }
}
