import 'package:flutter/material.dart';

import '../../../config/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../babysitter/models/babysitter_model.dart';
import '../../bookings/providers/booking_provider.dart';
import '../providers/parent_provider.dart';

class PriceScreen extends StatefulWidget {
  const PriceScreen({super.key});

  @override
  State<PriceScreen> createState() => _PriceScreenState();
}

class _PriceScreenState extends State<PriceScreen> {
  final _booking = BookingProvider.instance;
  final _parent = ParentProvider.instance;

  @override
  void initState() {
    super.initState();
    _loadCalculation();
  }

  void _loadCalculation() {
    final sitter = _parent.selectedBabysitter;
    if (sitter != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _booking.fetchPriceCalculation(babysitterId: sitter.id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sitter = _parent.selectedBabysitter;
    final price = _booking.priceModel;
    final isLoading = _booking.isCalculatingPrice;

    // Fallback calculation if priceModel is loading
    final duration = price?.duration ?? 4.0;
    final rate = price?.hourlyRate ?? (sitter?.hourlyRate ?? 1500.0);
    final subtotal = price?.subtotal ?? (duration * rate);
    final serviceFee = price?.serviceFee ?? 0.0;
    final total = price?.totalAmount ?? (subtotal + serviceFee);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        title: const Text(
          'Price Calculation',
          style: TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSizes.pagePadding),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.mint,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Step 5 of 5',
                  style: TextStyle(
                    color: AppColors.teal,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.teal),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.pagePadding,
                8,
                AppSizes.pagePadding,
                32,
              ),
              children: [
                const Text(
                  'Service pricing summary',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Server-verified hourly rate and transparent billing.',
                  style: TextStyle(color: AppColors.muted, fontSize: 14),
                ),
                const SizedBox(height: 20),

                // Sitter Card
                if (sitter != null) _buildSitterHeader(sitter),
                const SizedBox(height: 16),

                // Booking schedule card
                _buildScheduleCard(duration),
                const SizedBox(height: 16),

                // Pricing details card
                _buildPriceCard(duration, rate, subtotal, serviceFee, total),
                const SizedBox(height: 16),

                // Trust & Escrow Guarantee
                _buildGuaranteeCard(),
                const SizedBox(height: 28),

                // Continue Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.parentPaymentMethod);
                    },
                    icon: const Icon(Icons.payment_rounded, size: 20),
                    label: Text(
                      'Proceed to Payment (Rs. ${total.toStringAsFixed(0)})',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF005B60),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSitterHeader(BabysitterModel sitter) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radius),
        border: Border.all(color: AppColors.sand),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.mint,
            child: Text(
              sitter.name.isNotEmpty ? sitter.name[0].toUpperCase() : 'C',
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
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        sitter.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
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
                  'Hourly Rate: Rs. ${sitter.hourlyRate.toStringAsFixed(0)} / hr',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.muted,
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

  Widget _buildScheduleCard(double duration) {
    final date = _booking.selectedDate;
    final start = _booking.startTime?.formatted ?? '09:00 AM';
    final end = _booking.endTime?.formatted ?? '01:00 PM';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dateText = date != null
        ? '${date.day} ${months[date.month - 1]} ${date.year}'
        : 'Scheduled Date';

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
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.teal),
              const SizedBox(width: 8),
              Text(
                dateText,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.ink,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${duration.toStringAsFixed(1)} hrs',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.schedule_rounded, size: 18, color: AppColors.teal),
              const SizedBox(width: 8),
              Text(
                '$start – $end',
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceCard(
    double duration,
    double rate,
    double subtotal,
    double serviceFee,
    double total,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radius),
        border: Border.all(color: AppColors.sand),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Calculation Breakdown',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 16),

          // Duration x Rate row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Care Duration (${duration.toStringAsFixed(1)} hrs × Rs. ${rate.toStringAsFixed(0)})',
                style: const TextStyle(fontSize: 13.5, color: AppColors.muted),
              ),
              Text(
                'Rs. ${subtotal.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Subtotal row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Subtotal',
                style: TextStyle(fontSize: 13.5, color: AppColors.muted),
              ),
              Text(
                'Rs. ${subtotal.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Service Fee row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Platform Service Fee',
                style: TextStyle(fontSize: 13.5, color: AppColors.muted),
              ),
              if (serviceFee == 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'FREE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF166534),
                    ),
                  ),
                )
              else
                Text(
                  'Rs. ${serviceFee.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(color: AppColors.sand),
          ),

          // Total Amount
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Amount',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              Text(
                'Rs. ${total.toStringAsFixed(0)}',
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
    );
  }

  Widget _buildGuaranteeCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F5F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFB2DFDB)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, color: Color(0xFF005B60), size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Escrow Payment Protection: Your payment is securely held and only released once the babysitting service is successfully completed.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF005B60),
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
