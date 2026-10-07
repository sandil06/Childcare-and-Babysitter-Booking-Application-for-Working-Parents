import 'package:flutter/material.dart';

import '../../../config/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../bookings/models/booking_model.dart';
import '../../bookings/providers/booking_provider.dart';
import '../../bookings/services/booking_service.dart';
import '../../parent/providers/parent_provider.dart';
import '../services/payment_service.dart';

class PaymentMethodScreen extends StatefulWidget {
  const PaymentMethodScreen({super.key});

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  final BookingProvider _bookingProvider = BookingProvider.instance;
  final ParentProvider _parentProvider = ParentProvider.instance;
  final PaymentService _paymentService = PaymentService();
  final BookingService _bookingService = BookingService();

  bool _isProcessing = false;
  String? _errorMessage;
  int _selectedMethodIndex = 0; // 0 for Stripe Card

  @override
  Widget build(BuildContext context) {
    final sitter = _parentProvider.selectedBabysitter;
    final priceModel = _bookingProvider.priceModel;
    final totalAmount = priceModel?.totalAmount ?? 6000.0;
    final duration = priceModel?.duration ?? 4.0;
    final date = _bookingProvider.selectedDate;
    final startTime = _bookingProvider.startTime?.formatted ?? '09:00 AM';
    final endTime = _bookingProvider.endTime?.formatted ?? '01:00 PM';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.ink, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Payment Method',
          style: TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Prominent Stripe Sandbox Test Mode Banner
            _buildTestModeBanner(),
            const SizedBox(height: 20),

            // Booking Amount Card
            _buildAmountSummaryCard(sitter?.name ?? 'Caregiver', date, startTime, endTime, duration, totalAmount),
            const SizedBox(height: 24),

            // Select Payment Method Header
            const Text(
              'Select Payment Option',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 12),

            // Stripe Payment Option Tile
            _buildStripeCardOption(),
            const SizedBox(height: 20),

            // Stripe Test Card Details Box
            _buildTestCardPreview(),
            const SizedBox(height: 20),

            // Developer Sandbox Notice
            _buildDeveloperNotice(),
            const SizedBox(height: 24),

            // Error Message (if any)
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.coral, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(fontSize: 13, color: Color(0xFFB91C1C)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Pay Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                onPressed: _isProcessing ? null : () => _handlePay(totalAmount),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF005B60),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFF005B60).withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isProcessing
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Processing Test Payment...',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.lock_outline_rounded, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Pay Rs. ${totalAmount.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Secure Encrypted Escrow Footer
            const Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shield_outlined, size: 14, color: AppColors.muted),
                  SizedBox(width: 6),
                  Text(
                    '256-Bit SSL Encrypted Escrow Payment',
                    style: TextStyle(fontSize: 11.5, color: AppColors.muted, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTestModeBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.science_outlined, color: Color(0xFFD97706), size: 22),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'STRIPE SANDBOX - TEST MODE',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF92400E),
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'You are operating in Stripe Sandbox Mode. No real credit card charges will occur. Use standard test cards below.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF78350F), height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountSummaryCard(
    String sitterName,
    DateTime? date,
    String start,
    String end,
    double duration,
    double totalAmount,
  ) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dateStr = date != null ? '${date.day} ${months[date.month - 1]} ${date.year}' : 'Scheduled Date';

    return Container(
      padding: const EdgeInsets.all(18),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Amount to Pay',
                style: TextStyle(fontSize: 13, color: AppColors.muted, fontWeight: FontWeight.w600),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F5F2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Escrow Protected',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF005B60)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Rs. ${totalAmount.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: AppColors.teal,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: AppColors.sand),
          ),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 16, color: AppColors.muted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Babysitter: $sitterName',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 15, color: AppColors.muted),
              const SizedBox(width: 8),
              Text(
                '$dateStr  •  $start - $end (${duration.toStringAsFixed(1)} hrs)',
                style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStripeCardOption() {
    final isSelected = _selectedMethodIndex == 0;
    return GestureDetector(
      onTap: () => setState(() => _selectedMethodIndex = 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.radius),
          border: Border.all(
            color: isSelected ? const Color(0xFF005B60) : AppColors.sand,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF005B60).withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.credit_card, color: Color(0xFF005B60), size: 24),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Stripe Card Payment',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'TEST',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFD97706),
                          backgroundColor: Color(0xFFFEF3C7),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Instant checkout via Stripe Test Sandbox',
                    style: TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? const Color(0xFF005B60) : AppColors.muted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestCardPreview() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.contactless, color: Colors.white70, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'STRIPE TEST CARD',
                    style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'SANDBOX',
                  style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            '4242  4242  4242  4242',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.5,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 20),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CARDHOLDER', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.w600)),
                  SizedBox(height: 2),
                  Text('TEST PARENT', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('EXPIRES', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.w600)),
                  SizedBox(height: 2),
                  Text('12/28', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CVC', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.w600)),
                  SizedBox(height: 2),
                  Text('123', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeveloperNotice() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: AppColors.muted, size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Developer & Testing Note: Standard Stripe test card numbers (4242 4242 4242 4242) simulate successful payments on the sandbox test mode. Secret keys remain strictly on the backend.',
              style: TextStyle(fontSize: 11.5, color: AppColors.muted, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePay(double totalAmount) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      BookingModel? booking = _bookingProvider.createdBooking;

      // 1. If booking hasn't been created on backend yet, create it now
      if (booking == null) {
        final sitter = _parentProvider.selectedBabysitter;
        final selectedDate = _bookingProvider.selectedDate ?? DateTime.now();
        final start = _bookingProvider.startTime?.formatted ?? '09:00 AM';
        final end = _bookingProvider.endTime?.formatted ?? '01:00 PM';
        final price = _bookingProvider.priceModel;

        final newBooking = await _bookingService.createBooking({
          'babysitterId': sitter?.id ?? 'sitter-1',
          'date': '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
          'startTime': start,
          'endTime': end,
          'hourlyRate': sitter?.hourlyRate ?? 1500.0,
          'location': 'Colombo, Sri Lanka',
          'specialNotes': 'Childcare booking via mobile app',
          'children': [
            {'name': 'Child', 'age': 4},
          ],
          'subtotal': price?.subtotal ?? totalAmount,
          'serviceFee': price?.serviceFee ?? 0.0,
          'totalAmount': totalAmount,
        });

        booking = newBooking;
        _bookingProvider.setCreatedBooking(newBooking);
      }

      final bookingId = booking.id;

      // 2. Create Stripe PaymentIntent on backend
      final intentData = await _paymentService.createPaymentIntent(bookingId);
      final paymentIntentId = intentData['paymentIntentId']?.toString() ?? 'pi_test_${DateTime.now().millisecondsSinceEpoch}';

      // 3. Confirm Payment on backend (simulating sandbox completion)
      final confirmedPayment = await _paymentService.confirmPayment(
        bookingId: bookingId,
        paymentIntentId: paymentIntentId,
      );

      // 4. Update local booking state to confirmed & paid
      final updatedBooking = booking.copyWith(
        paymentStatus: 'paid',
        status: 'confirmed',
        paymentIntentId: paymentIntentId,
      );
      _bookingProvider.setCreatedBooking(updatedBooking);

      if (!mounted) return;

      // 5. Navigate to Booking Confirmation screen
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.bookingConfirmation,
        arguments: {
          'booking': updatedBooking,
          'payment': confirmedPayment,
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Payment processing failed: ${e.toString()}';
          _isProcessing = false;
        });
      }
    }
  }
}
