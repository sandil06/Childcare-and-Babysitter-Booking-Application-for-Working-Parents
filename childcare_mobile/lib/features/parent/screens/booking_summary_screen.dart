import 'package:flutter/material.dart';

import '../../../config/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../babysitter/models/babysitter_model.dart';
import '../../bookings/providers/booking_provider.dart';
import '../models/parent_model.dart';
import '../providers/parent_provider.dart';

class BookingSummaryScreen extends StatefulWidget {
  const BookingSummaryScreen({super.key});

  @override
  State<BookingSummaryScreen> createState() => _BookingSummaryScreenState();
}

class _BookingSummaryScreenState extends State<BookingSummaryScreen> {
  final _booking = BookingProvider.instance;
  final _parent = ParentProvider.instance;

  @override
  void initState() {
    super.initState();
    _booking.addListener(_refresh);
    _parent.addListener(_refresh);
    _booking.loadLiveLocationStatus();
  }

  @override
  void dispose() {
    _booking.removeListener(_refresh);
    _parent.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final sitter = _parent.selectedBabysitter;
    final parent = _parent.profile;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Booking Summary'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSizes.pagePadding),
            child: Center(child: _StepPill()),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSizes.pagePadding,
          8,
          AppSizes.pagePadding,
          32,
        ),
        children: [
          const Text(
            'Review care details',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Ensure all details are accurate before continuing.',
            style: TextStyle(color: AppColors.muted, fontSize: 14),
          ),
          const SizedBox(height: 20),
          if (sitter != null) _SitterCard(sitter: sitter),
          if (sitter == null)
            const _UnavailableCard(message: 'No babysitter has been selected.'),
          const SizedBox(height: 16),
          _BookingDetailsCard(
            booking: _booking,
            parent: parent,
            onEditDate: () =>
                Navigator.pushNamed(context, AppRoutes.bookingDate),
            onEditTime: () =>
                Navigator.pushNamed(context, AppRoutes.bookingStartTime),
            onToggleLiveLocation: () =>
                _booking.setLiveLocationEnabled(!_booking.liveLocationEnabled),
          ),
          const SizedBox(height: 16),
          _NotesCard(),
          if (_booking.isComplete) ...[
            const SizedBox(height: 16),
            _NeutralInfoCard(),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _booking.isComplete ? _continueWithoutSubmitting : null,
            icon: const Icon(Icons.check_rounded),
            label: const Text('Continue'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.ink,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _continueWithoutSubmitting() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Your booking details are ready for the next confirmation step.',
        ),
      ),
    );
  }
}

class _StepPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.mint,
      borderRadius: BorderRadius.circular(20),
    ),
    child: const Text(
      'Step 4 of 5',
      style: TextStyle(
        color: AppColors.teal,
        fontSize: 11,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _SitterCard extends StatelessWidget {
  const _SitterCard({required this.sitter});
  final BabysitterModel sitter;

  @override
  Widget build(BuildContext context) {
    final verifiedDocuments = sitter.documents
        .where((document) => document.status == 'verified')
        .toList();
    final rating = sitter.totalReviews > 0
        ? '★ ${sitter.averageRating.toStringAsFixed(1)} (${sitter.totalReviews} reviews)'
        : null;

    return _SurfaceCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Avatar(sitter: sitter, radius: 31),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sitter.name.isEmpty ? 'Selected babysitter' : sitter.name,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                if (sitter.bio.isNotEmpty)
                  Text(
                    sitter.bio,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                if (rating != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    rating,
                    style: const TextStyle(
                      color: AppColors.coral,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                if (sitter.address.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _MetaLine(
                    icon: Icons.location_on_outlined,
                    text: sitter.address,
                  ),
                ],
                if (sitter.isVerified || verifiedDocuments.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (sitter.isVerified)
                        const _StatusChip(label: 'Verified'),
                      ...verifiedDocuments
                          .take(2)
                          .map(
                            (document) => _StatusChip(
                              label: _documentLabel(document.type),
                            ),
                          ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _documentLabel(String type) {
    switch (type) {
      case 'id':
        return 'ID verified';
      case 'police_check':
        return 'Police cleared';
      default:
        return 'Verified';
    }
  }
}

class _BookingDetailsCard extends StatelessWidget {
  const _BookingDetailsCard({
    required this.booking,
    required this.parent,
    required this.onEditDate,
    required this.onEditTime,
    required this.onToggleLiveLocation,
  });

  final BookingProvider booking;
  final ParentModel? parent;
  final VoidCallback onEditDate;
  final VoidCallback onEditTime;
  final Future<bool> Function() onToggleLiveLocation;

  @override
  Widget build(BuildContext context) {
    final child = parent?.children.isNotEmpty == true
        ? parent!.children.first
        : null;
    final hasAddress = parent?.address.trim().isNotEmpty == true;

    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeading(
            title: 'Booking Details',
            icon: Icons.event_note_outlined,
            action: TextButton(
              onPressed: onEditDate,
              child: const Text('Edit'),
            ),
          ),
          const Divider(height: 24, color: AppColors.sand),
          _DetailRow(
            icon: Icons.calendar_today_rounded,
            label: 'DATE',
            value: _formatDate(booking.selectedDate),
          ),
          const Divider(height: 24, color: AppColors.sand),
          _DetailRow(
            icon: Icons.schedule_rounded,
            label: 'TIME & DURATION',
            value: _timeRange(booking),
            trailing: TextButton(
              onPressed: onEditTime,
              child: const Text('Edit'),
            ),
          ),
          if (child != null) ...[
            const Divider(height: 24, color: AppColors.sand),
            _DetailRow(
              icon: Icons.child_care_rounded,
              label: 'CHILD',
              value: _childLabel(child),
            ),
          ],
          if (hasAddress) ...[
            const Divider(height: 24, color: AppColors.sand),
            _DetailRow(
              icon: Icons.location_on_outlined,
              label: 'SERVICE ADDRESS',
              value: parent!.address,
            ),
          ],
          const Divider(height: 24, color: AppColors.sand),
          _LiveLocationRow(booking: booking, onToggle: onToggleLiveLocation),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Not selected';
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _timeRange(BookingProvider booking) {
    final start = booking.startTime?.formatted;
    final end = booking.endTime?.formatted;
    if (start == null || end == null) return 'Not selected';
    final durationMinutes =
        booking.endTime!.toMinutes - booking.startTime!.toMinutes;
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    final duration = minutes == 0 ? '$hours hours' : '$hours hr $minutes min';
    return '$start - $end\n$duration';
  }

  String _childLabel(Map<String, dynamic> child) {
    final name = child['name']?.toString().trim() ?? '';
    final age = child['age']?.toString().trim() ?? '';
    if (name.isEmpty) return 'Child information available';
    return age.isEmpty ? name : '$name ($age yrs)';
  }
}

class _LiveLocationRow extends StatelessWidget {
  const _LiveLocationRow({required this.booking, required this.onToggle});

  final BookingProvider booking;
  final Future<bool> Function() onToggle;

  @override
  Widget build(BuildContext context) {
    final isEnabled = booking.liveLocationEnabled;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isEnabled ? AppColors.mint : AppColors.sand,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isEnabled
                    ? Icons.location_on_rounded
                    : Icons.location_on_outlined,
                color: isEnabled ? AppColors.teal : AppColors.muted,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LIVE LOCATION',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Share your live location with the babysitter',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: booking.isUpdatingLiveLocation
                ? null
                : () async {
                    final ok = await onToggle();
                    if (!context.mounted || ok) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          booking.liveLocationError ??
                              'Unable to update live location sharing.',
                        ),
                        backgroundColor: AppColors.coral,
                      ),
                    );
                  },
            icon: booking.isUpdatingLiveLocation
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    isEnabled
                        ? Icons.stop_circle_outlined
                        : Icons.location_searching_rounded,
                  ),
            label: Text(
              booking.isUpdatingLiveLocation
                  ? 'Updating...'
                  : isEnabled
                  ? 'Stop Sharing'
                  : 'Enable Live Location',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: isEnabled ? AppColors.coral : AppColors.teal,
              side: BorderSide(
                color: isEnabled ? AppColors.coral : AppColors.teal,
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          isEnabled
              ? 'Sharing is active. Location coordinates will be added when a device location provider is connected.'
              : 'Sharing is off until you enable it.',
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 11,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}

class _NotesCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _SurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _CardHeading(
          title: 'Special Instructions & Notes',
          icon: Icons.edit_note_rounded,
          trailingLabel: 'Caregiver visible',
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.sand),
          ),
          child: const Text(
            'No special instructions have been added.',
            style: TextStyle(color: AppColors.muted, fontSize: 13, height: 1.4),
          ),
        ),
        const SizedBox(height: 12),
        const _MetaLine(
          icon: Icons.info_outline_rounded,
          text:
              'Instructions will be securely shared with the caregiver upon confirmation.',
        ),
      ],
    ),
  );
}

class _NeutralInfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.mint,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.teal.withValues(alpha: 0.2)),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.shield_outlined, color: AppColors.teal),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            'Review the details above before continuing to the next step.',
            style: TextStyle(color: AppColors.ink, fontSize: 13, height: 1.35),
          ),
        ),
      ],
    ),
  );
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.035),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: child,
  );
}

class _CardHeading extends StatelessWidget {
  const _CardHeading({
    required this.title,
    required this.icon,
    this.action,
    this.trailingLabel,
  });
  final String title;
  final IconData icon;
  final Widget? action;
  final String? trailingLabel;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: AppColors.teal, size: 19),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      ...trailingLabel == null
          ? const <Widget>[]
          : [
              Text(
                trailingLabel!,
                style: const TextStyle(color: AppColors.muted, fontSize: 11),
              ),
            ],
      ...action == null ? const <Widget>[] : [action!],
    ],
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
  });
  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.mint,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.teal, size: 18),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
      ...trailing == null ? const <Widget>[] : [trailing!],
    ],
  );
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: AppColors.teal, size: 15),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 11,
            height: 1.3,
          ),
        ),
      ),
    ],
  );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: AppColors.mint,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: AppColors.teal,
        fontSize: 10,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.sitter, required this.radius});
  final BabysitterModel sitter;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final image = sitter.profileImage;
    final initials = sitter.name.trim().isEmpty
        ? 'S'
        : sitter.name.trim()[0].toUpperCase();
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.mint,
      backgroundImage: image == null || image.isEmpty
          ? null
          : NetworkImage(image),
      child: image == null || image.isEmpty
          ? Text(
              initials,
              style: const TextStyle(
                color: AppColors.teal,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            )
          : null,
    );
  }
}

class _UnavailableCard extends StatelessWidget {
  const _UnavailableCard({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => _SurfaceCard(
    child: Row(
      children: [
        const Icon(Icons.info_outline_rounded, color: AppColors.muted),
        const SizedBox(width: 10),
        Expanded(
          child: Text(message, style: const TextStyle(color: AppColors.muted)),
        ),
      ],
    ),
  );
}
