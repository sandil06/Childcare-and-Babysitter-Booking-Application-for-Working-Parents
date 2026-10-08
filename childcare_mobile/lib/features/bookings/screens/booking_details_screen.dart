import 'package:flutter/material.dart';

import '../../../config/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../models/booking_model.dart';
import '../services/booking_service.dart';
import '../widgets/status_chip.dart';

class BookingDetailsScreen extends StatefulWidget {
  final BookingModel? initialBooking;

  const BookingDetailsScreen({super.key, this.initialBooking});

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  final BookingService _service = BookingService();
  BookingModel? _booking;
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_booking == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is BookingModel) {
        _booking = args;
        _refreshDetails();
      } else if (widget.initialBooking != null) {
        _booking = widget.initialBooking;
        _refreshDetails();
      } else if (args is Map && args['booking'] is BookingModel) {
        _booking = args['booking'] as BookingModel;
        _refreshDetails();
      } else {
        String? idToLoad;
        if (args is String && args.isNotEmpty) {
          idToLoad = args;
        } else if (args is Map) {
          idToLoad = args['id']?.toString() ?? args['bookingId']?.toString();
        }
        if (idToLoad != null && idToLoad.isNotEmpty) {
          _loadBookingById(idToLoad);
        }
      }
    }
  }

  Future<void> _loadBookingById(String id) async {
    setState(() => _isLoading = true);
    try {
      final fresh = await _service.getBookingById(id);
      if (fresh != null && mounted) {
        setState(() => _booking = fresh);
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshDetails() async {
    if (_booking == null) return;
    try {
      final targetId = _booking!.id.isNotEmpty ? _booking!.id : _booking!.bookingId;
      final fresh = await _service.getBookingById(targetId);
      if (fresh != null && mounted) {
        setState(() => _booking = fresh);
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = _booking;
    if (b == null) {
      return Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(backgroundColor: AppColors.cream, elevation: 0),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
            : const Center(
                child: Text(
                  'Booking details not found.',
                  style: TextStyle(color: AppColors.muted, fontSize: 15),
                ),
              ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        title: Text(
          b.bookingId,
          style: const TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined, color: AppColors.ink),
            tooltip: 'Home',
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.ink),
            onPressed: _refreshDetails,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.pagePadding,
                8,
                AppSizes.pagePadding,
                32,
              ),
              children: [
                // Top Status & Reference Card
                _buildHeaderCard(b),
                const SizedBox(height: 16),

                // Live Sitter Tracking CTA (Active statuses)
                if (b.isLiveTrackingAvailable) ...[
                  _buildTrackingBanner(b),
                  const SizedBox(height: 16),
                ],

                // Babysitter Info Card
                _buildSitterCard(b),
                const SizedBox(height: 16),

                // Care Schedule Card
                _buildScheduleCard(b),
                const SizedBox(height: 16),

                // Location & Child Details Card
                _buildLocationAndChildrenCard(b),
                const SizedBox(height: 16),

                // Payment & Price Breakdown Card
                _buildBillingCard(b),
                const SizedBox(height: 24),

                // Context Action Buttons
                _buildActionButtons(b),
              ],
            ),
    );
  }

  Widget _buildHeaderCard(BookingModel b) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radius),
        border: Border.all(color: AppColors.sand),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Booking Status',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 6),
              StatusChip(status: b.status),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Payment',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: b.paymentStatus == 'paid'
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  b.paymentStatus.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: b.paymentStatus == 'paid'
                        ? const Color(0xFF166534)
                        : const Color(0xFFB45309),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingBanner(BookingModel b) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F5F2),
        borderRadius: BorderRadius.circular(AppSizes.radius),
        border: Border.all(color: const Color(0xFF005B60).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFF005B60),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.location_searching_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Live Babysitter Tracking',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF005B60),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Track your sitter in real-time on Google Maps.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.liveTracking, arguments: b);
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF005B60),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Track', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildSitterCard(BookingModel b) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radius),
        border: Border.all(color: AppColors.sand),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Assigned Babysitter',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.mint,
                child: Text(
                  b.babysitterName.isNotEmpty ? b.babysitterName[0].toUpperCase() : 'C',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.teal),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            b.babysitterName,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.verified, size: 16, color: AppColors.teal),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rate: Rs. ${b.hourlyRate.toStringAsFixed(0)} / hr',
                      style: const TextStyle(fontSize: 13, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.parentChat, arguments: {
                    'recipientId': b.babysitterId,
                    'recipientName': b.babysitterName,
                    'bookingId': b.id,
                  });
                },
                icon: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF005B60)),
                tooltip: 'Chat with Caregiver',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(BookingModel b) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radius),
        border: Border.all(color: AppColors.sand),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Care Schedule', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.muted)),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.teal),
              const SizedBox(width: 8),
              Text(b.formattedDate, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                child: Text('${b.durationHours.toStringAsFixed(1)} hrs', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.schedule_rounded, size: 16, color: AppColors.teal),
              const SizedBox(width: 8),
              Text(b.timeRange, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.muted)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationAndChildrenCard(BookingModel b) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radius),
        border: Border.all(color: AppColors.sand),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Location & Care Info', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.muted)),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_outlined, size: 18, color: AppColors.teal),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  b.location,
                  style: const TextStyle(fontSize: 13.5, color: AppColors.ink, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          if (b.children.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text('Children:', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.muted)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: b.children.map((child) {
                return Chip(
                  backgroundColor: AppColors.mint,
                  label: Text('${child.name} (${child.age} yrs)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF005B60))),
                  padding: EdgeInsets.zero,
                );
              }).toList(),
            ),
          ],
          if (b.specialNotes.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Special Notes:', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.muted)),
            const SizedBox(height: 4),
            Text(
              b.specialNotes,
              style: const TextStyle(fontSize: 13, color: AppColors.ink, fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBillingCard(BookingModel b) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radius),
        border: Border.all(color: AppColors.sand),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Payment Breakdown', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.muted)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${b.durationHours.toStringAsFixed(1)} hrs × Rs. ${b.hourlyRate.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13.5, color: AppColors.muted)),
              Text('Rs. ${b.subtotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.ink)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Platform Service Fee', style: TextStyle(fontSize: 13.5, color: AppColors.muted)),
              Text(
                b.serviceFee == 0 ? 'FREE' : 'Rs. ${b.serviceFee.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: b.serviceFee == 0 ? const Color(0xFF166534) : AppColors.ink,
                ),
              ),
            ],
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(color: AppColors.sand)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Paid', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink)),
              Text('Rs. ${b.totalAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.teal)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BookingModel b) {
    return Column(
      children: [
        if (b.canBeRescheduled) ...[
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () async {
                final result = await Navigator.pushNamed(
                  context,
                  AppRoutes.parentRescheduleBooking,
                  arguments: b,
                );
                if (result == true) _refreshDetails();
              },
              icon: const Icon(Icons.edit_calendar_rounded, size: 18),
              label: const Text('Reschedule Booking', style: TextStyle(fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF005B60),
                side: const BorderSide(color: Color(0xFF005B60)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (b.canBeCancelled) ...[
          SizedBox(
            width: double.infinity,
            height: 48,
            child: TextButton.icon(
              onPressed: () async {
                final result = await Navigator.pushNamed(
                  context,
                  AppRoutes.parentCancelBooking,
                  arguments: b,
                );
                if (result == true) _refreshDetails();
              },
              icon: const Icon(Icons.cancel_outlined, size: 18, color: AppColors.coral),
              label: const Text('Cancel Booking', style: TextStyle(color: AppColors.coral, fontWeight: FontWeight.w700)),
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: AppColors.coral),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (b.status == 'completed') ...[
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.parentPaymentReceipt,
                  arguments: b,
                );
              },
              icon: const Icon(Icons.receipt_long_rounded, size: 18),
              label: const Text('View Payment Receipt', style: TextStyle(fontWeight: FontWeight.w700)),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF005B60),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
