import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../models/booking_model.dart';
import '../services/booking_service.dart';

class CancelBookingScreen extends StatefulWidget {
  final BookingModel? initialBooking;

  const CancelBookingScreen({super.key, this.initialBooking});

  @override
  State<CancelBookingScreen> createState() => _CancelBookingScreenState();
}

class _CancelBookingScreenState extends State<CancelBookingScreen> {
  final BookingService _service = BookingService();
  final TextEditingController _notesController = TextEditingController();

  BookingModel? _booking;
  String _selectedReason = 'Schedule conflict or change of plans';
  bool _isLoading = false;

  final List<String> _cancellationReasons = [
    'Schedule conflict or change of plans',
    'Child feeling unwell',
    'Found alternate care arrangement',
    'Booked by mistake',
    'Other reason',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_booking == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is BookingModel) {
        _booking = args;
      } else if (widget.initialBooking != null) {
        _booking = widget.initialBooking;
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleConfirmCancel() async {
    if (_booking == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Confirm Cancellation',
          style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink),
        ),
        content: const Text(
          'Are you sure you want to cancel this care booking? This action cannot be undone.',
          style: TextStyle(color: AppColors.muted, fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Booking', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.muted)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.coral,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Cancel Booking', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final customNotes = _notesController.text.trim();
      final fullReason = customNotes.isNotEmpty
          ? '$_selectedReason ($customNotes)'
          : _selectedReason;

      final res = await _service.cancelBooking(_booking!.id, reason: fullReason);
      if (mounted) {
        if (res != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Care reservation cancelled successfully.'),
              backgroundColor: AppColors.teal,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to cancel booking. Please try again.'),
              backgroundColor: AppColors.coral,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cancellation error: ${e.toString()}'),
            backgroundColor: AppColors.coral,
          ),
        );
      }
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
        body: const Center(child: Text('Booking details not available.')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        title: const Text(
          'Cancel Reservation',
          style: TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSizes.pagePadding,
          8,
          AppSizes.pagePadding,
          32,
        ),
        children: [
          // Header
          const Text(
            'Reason for cancellation',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Help us improve our service by providing a reason for this cancellation.',
            style: TextStyle(color: AppColors.muted, fontSize: 13.5, height: 1.4),
          ),
          const SizedBox(height: 18),

          // Mini Booking Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.sand),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.mint,
                  child: Text(
                    b.babysitterName.isNotEmpty ? b.babysitterName[0].toUpperCase() : 'C',
                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.teal),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        b.babysitterName,
                        style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.ink),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${b.formattedDate} • ${b.timeRange}',
                        style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Rs. ${b.totalAmount.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.teal),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Selection Options
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSizes.radius),
              border: Border.all(color: AppColors.sand),
            ),
            child: Column(
              children: _cancellationReasons.map((reason) {
                final isSelected = _selectedReason == reason;
                return InkWell(
                  onTap: () => setState(() => _selectedReason = reason),
                  borderRadius: BorderRadius.circular(AppSizes.radius),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? AppColors.teal : const Color(0xFFCBD5E1),
                              width: isSelected ? 6 : 2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            reason,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? AppColors.ink : const Color(0xFF475569),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // Additional Note
          Container(
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
                  'Additional comments (Optional)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _notesController,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 13.5, color: AppColors.ink),
                  decoration: InputDecoration(
                    hintText: 'Enter any additional feedback...',
                    hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF005B60), width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Policy & Refund Info Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Icon(Icons.info_outline_rounded, color: Color(0xFF166534), size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Full Escrow Refund: For advance cancellations, your payment of 100% will be automatically refunded back to your account.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF166534),
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Submit Cancellation Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: _isLoading ? null : _handleConfirmCancel,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.coral,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'Cancel Booking',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
