import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../models/booking_request_model.dart';
import '../providers/babysitter_provider.dart';

class BookingRequestDetailsScreen extends StatefulWidget {
  const BookingRequestDetailsScreen({super.key, this.booking});

  final BookingRequestModel? booking;

  @override
  State<BookingRequestDetailsScreen> createState() =>
      _BookingRequestDetailsScreenState();
}

class _BookingRequestDetailsScreenState
    extends State<BookingRequestDetailsScreen> {
  final BabysitterProvider _provider = BabysitterProvider.instance;
  bool _isProcessing = false;

  BookingRequestModel get _booking {
    return widget.booking ??
        _provider.selectedBooking ??
        BookingRequestModel(
          id: 'temp',
          bookingId: '#BK-8841',
          parentId: 'p-1',
          parentName: 'Sarah Jenkins',
          date: DateTime.now(),
          startTime: '15:00',
          endTime: '19:00',
          durationHours: 4.0,
          location: '142 West End Ave, Apt 4B',
          totalAmount: 112.0,
        );
  }

  String _formatDate(DateTime d) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    const weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    return '${weekdays[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  void _confirmAccept() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Accept Booking Request',
          style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Confirm acceptance of the booking for ${_booking.parentName} on ${_booking.timeFormatted}?',
          style: const TextStyle(color: AppColors.muted, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.muted)),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isProcessing = true);
              final ok = await _provider.acceptBooking(_booking.id);
              setState(() => _isProcessing = false);
              if (mounted && ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Booking accepted! It is now listed under Upcoming Bookings.',
                    ),
                    backgroundColor: AppColors.teal,
                  ),
                );
                Navigator.pop(context);
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.teal,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Confirm Accept'),
          ),
        ],
      ),
    );
  }

  void _confirmReject() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Decline Booking Request',
          style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Are you sure you want to decline this booking request? The parent will be notified.',
          style: TextStyle(color: AppColors.muted, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.muted)),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isProcessing = true);
              final ok = await _provider.rejectBooking(_booking.id);
              setState(() => _isProcessing = false);
              if (mounted && ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Booking request declined.'),
                    backgroundColor: AppColors.ink,
                  ),
                );
                Navigator.pop(context);
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.coral,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Confirm Decline'),
          ),
        ],
      ),
    );
  }

  void _advanceJobStatus() async {
    final nextStatus = _booking.nextStatusTarget;
    if (nextStatus == null) return;

    setState(() => _isProcessing = true);
    final ok = await _provider.updateJobStatus(_booking.id, nextStatus);
    setState(() => _isProcessing = false);

    if (mounted && ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking status updated to ${nextStatus.toUpperCase()}'),
          backgroundColor: AppColors.teal,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = _booking;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Booking ${booking.bookingId}',
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.pagePadding),
          children: [
            // Status and ID Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Booking Reference',
                        style: TextStyle(fontSize: 11, color: AppColors.muted),
                      ),
                      Text(
                        booking.bookingId,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: booking.isPending
                          ? AppColors.sand
                          : (booking.isCompleted
                              ? AppColors.mint
                              : (booking.isCancelled
                                  ? const Color(0xFFFDE8E8)
                                  : AppColors.mint)),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      booking.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: booking.isPending
                            ? const Color(0xFF92400E)
                            : (booking.isCancelled
                                ? AppColors.coral
                                : AppColors.teal),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Parent Information Card
            _buildSectionCard(
              title: 'Parent Information',
              icon: Icons.person_outline_rounded,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.mint,
                    child: Text(
                      booking.parentName.isNotEmpty
                          ? booking.parentName[0]
                          : 'P',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.teal,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.parentName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          booking.parentPhone,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Schedule Details Card
            _buildSectionCard(
              title: 'Date & Time',
              icon: Icons.calendar_today_rounded,
              child: Column(
                children: [
                  _buildDetailRow(
                    label: 'Date',
                    value: _formatDate(booking.date),
                    icon: Icons.event_rounded,
                  ),
                  const Divider(height: 20, color: AppColors.sand),
                  _buildDetailRow(
                    label: 'Hours',
                    value: booking.timeFormatted,
                    icon: Icons.access_time_rounded,
                  ),
                  const Divider(height: 20, color: AppColors.sand),
                  _buildDetailRow(
                    label: 'Duration',
                    value: '${booking.durationHours.toInt()} Hours',
                    icon: Icons.timelapse_rounded,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Location Card
            _buildSectionCard(
              title: 'Location & Address',
              icon: Icons.location_on_outlined,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.mint,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.home_rounded,
                        color: AppColors.teal, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Family Residence',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          booking.location,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.muted,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Children Details
            _buildSectionCard(
              title: 'Children Cared For',
              icon: Icons.child_care_rounded,
              child: booking.childrenDetails.isNotEmpty
                  ? Column(
                      children: booking.childrenDetails.map((c) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.cream,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.sand),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: AppColors.sand,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.face_rounded,
                                    size: 18, color: AppColors.ink),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${c.name} (${c.age} years old)',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                    if (c.notes != null && c.notes!.isNotEmpty)
                                      Text(
                                        c.notes!,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.muted,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    )
                  : const Text('1 Child', style: TextStyle(color: AppColors.muted)),
            ),
            const SizedBox(height: 16),

            // Special Notes
            if (booking.specialNotes != null &&
                booking.specialNotes!.isNotEmpty) ...[
              _buildSectionCard(
                title: 'Special Instructions / Notes',
                icon: Icons.notes_rounded,
                child: Text(
                  booking.specialNotes!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.ink,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Pricing Breakdown Card
            _buildSectionCard(
              title: 'Payment & Earnings Breakdown',
              icon: Icons.payments_outlined,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${booking.hourlyRate.toInt()} / hr × ${booking.durationHours.toInt()} hours',
                        style: const TextStyle(color: AppColors.muted, fontSize: 13),
                      ),
                      Text(
                        '\$${booking.totalAmount.toInt()}.00',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20, color: AppColors.sand),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Sitter Earnings',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        '\$${booking.totalAmount.toInt()}.00',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.teal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.check_circle_outline_rounded,
                          size: 14, color: AppColors.teal),
                      const SizedBox(width: 4),
                      Text(
                        'Payment Status: ${booking.paymentStatus.toUpperCase()} (Protected by In-App Escrow)',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.teal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Action Buttons
            if (booking.isPending) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isProcessing ? null : _confirmReject,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.coral,
                        side: const BorderSide(color: AppColors.coral, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Decline Request',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: FilledButton(
                      onPressed: _isProcessing ? null : _confirmAccept,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Accept Booking',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                ],
              ),
            ] else if (booking.nextStatusActionLabel.isNotEmpty) ...[
              FilledButton(
                onPressed: _isProcessing ? null : _advanceJobStatus,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.ink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        booking.nextStatusActionLabel,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
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
                  fontSize: 15,
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

  Widget _buildDetailRow({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.muted),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.muted)),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }
}
