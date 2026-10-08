import 'package:flutter/material.dart';

import '../../../config/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../bookings/models/booking_model.dart';
import '../../bookings/providers/booking_provider.dart';
import '../../bookings/widgets/status_chip.dart';
import '../../parent/providers/parent_provider.dart';
import '../../payments/models/payment_model.dart';

class BookingConfirmationScreen extends StatelessWidget {
  final BookingModel? booking;
  final PaymentModel? payment;

  const BookingConfirmationScreen({
    super.key,
    this.booking,
    this.payment,
  });

  @override
  Widget build(BuildContext context) {
    // Resolve booking from argument or provider
    final args = ModalRoute.of(context)?.settings.arguments;
    BookingModel? activeBooking = booking;
    PaymentModel? activePayment = payment;

    if (args is Map) {
      if (args['booking'] is BookingModel) {
        activeBooking = args['booking'] as BookingModel;
      }
      if (args['payment'] is PaymentModel) {
        activePayment = args['payment'] as PaymentModel;
      }
    } else if (args is BookingModel) {
      activeBooking = args;
    }

    activeBooking ??= BookingProvider.instance.createdBooking;
    final sitter = ParentProvider.instance.selectedBabysitter;

    final referenceId = activeBooking?.displayBookingId ?? 'BK-849204';
    final sitterName = activeBooking?.babysitterName ?? sitter?.name ?? 'Caregiver';
    final totalAmount = activeBooking?.totalAmount ?? activeBooking?.total ?? activePayment?.amount ?? 6000.0;
    final dateStr = activeBooking?.formattedDate ?? 'Scheduled Date';
    final timeStr = activeBooking != null
        ? '${activeBooking.startTime} - ${activeBooking.endTime} (${activeBooking.durationHours.toStringAsFixed(1)} hrs)'
        : '09:00 AM - 01:00 PM (4.0 hrs)';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.pushNamedAndRemoveUntil(context, AppRoutes.parentUpcomingBookings, (route) => false);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),

                // Success Animated Badge
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF16A34A).withValues(alpha: 0.18),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF16A34A),
                      size: 54,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Confirmation Title
                const Text(
                  'Booking Confirmed!',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Your babysitting request has been confirmed and payment held securely in escrow.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.muted,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Booking Details Summary Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      // Booking Reference
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Booking Reference',
                            style: TextStyle(fontSize: 13, color: AppColors.muted, fontWeight: FontWeight.w600),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF005B60).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              referenceId,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF005B60),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Divider(color: Color(0xFFE2E8F0)),
                      ),

                      // Babysitter
                      _buildRow(
                        label: 'Caregiver',
                        value: sitterName,
                        leadingIcon: Icons.person_outline,
                      ),
                      const SizedBox(height: 12),

                      // Date
                      _buildRow(
                        label: 'Date',
                        value: dateStr,
                        leadingIcon: Icons.calendar_today_outlined,
                      ),
                      const SizedBox(height: 12),

                      // Time & Duration
                      _buildRow(
                        label: 'Schedule',
                        value: timeStr,
                        leadingIcon: Icons.schedule_outlined,
                      ),
                      const SizedBox(height: 12),

                      // Status Chips
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.shield_outlined, size: 16, color: AppColors.muted),
                              SizedBox(width: 8),
                              Text(
                                'Status',
                                style: TextStyle(fontSize: 13, color: AppColors.muted, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const StatusChip(status: 'confirmed'),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'PAID',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF166534),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Divider(color: Color(0xFFE2E8F0)),
                      ),

                      // Total Paid
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Paid',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink),
                          ),
                          Text(
                            'Rs. ${totalAmount.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: AppColors.teal,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Primary CTA: View Booking
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: () {
                      if (activeBooking != null) {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.parentBookingDetails,
                          arguments: activeBooking,
                        );
                      } else {
                        Navigator.pushNamed(context, AppRoutes.parentUpcomingBookings);
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF005B60),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text(
                      'View Booking Details',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Secondary CTA: Go to My Bookings
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.parentUpcomingBookings,
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.ink,
                      side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text(
                      'Go to My Bookings',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Return to Parent Dashboard CTA
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRoutes.home,
                        (route) => false,
                      );
                    },
                    icon: const Icon(Icons.home_rounded, color: AppColors.teal),
                    label: const Text(
                      'Return to Parent Dashboard',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.teal),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Receipt CTA Link
                TextButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.parentPaymentReceipt,
                      arguments: {
                        'booking': activeBooking,
                        'payment': activePayment,
                      },
                    );
                  },
                  icon: const Icon(Icons.receipt_long_outlined, size: 18, color: AppColors.teal),
                  label: const Text(
                    'View Payment Receipt',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.teal,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRow({
    required String label,
    required String value,
    required IconData leadingIcon,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(leadingIcon, size: 16, color: AppColors.muted),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppColors.muted, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.ink),
          ),
        ),
      ],
    );
  }
}
