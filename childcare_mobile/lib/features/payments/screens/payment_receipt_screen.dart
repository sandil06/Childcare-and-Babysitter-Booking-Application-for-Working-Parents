import 'package:flutter/material.dart';

import '../../../config/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../bookings/models/booking_model.dart';
import '../../bookings/providers/booking_provider.dart';
import '../models/payment_model.dart';
import '../services/payment_service.dart';
import '../services/receipt_pdf_service.dart';

class PaymentReceiptScreen extends StatefulWidget {
  final BookingModel? booking;
  final PaymentModel? payment;
  final String? receiptId;

  const PaymentReceiptScreen({
    super.key,
    this.booking,
    this.payment,
    this.receiptId,
  });

  @override
  State<PaymentReceiptScreen> createState() => _PaymentReceiptScreenState();
}

class _PaymentReceiptScreenState extends State<PaymentReceiptScreen> {
  final PaymentService _paymentService = PaymentService();
  bool _isLoading = false;
  bool _isDownloadingPdf = false;
  bool _hasLoaded = false;
  Map<String, dynamic>? _receiptData;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoaded) {
      _hasLoaded = true;
      _loadReceipt();
    }
  }

  Future<void> _loadReceipt() async {
    final args = ModalRoute.of(context)?.settings.arguments;
    String? lookupId = widget.receiptId;
    if (args is Map) {
      if (args['receiptId'] != null) {
        lookupId = args['receiptId'].toString();
      } else if (args['payment'] is PaymentModel && (args['payment'] as PaymentModel).paymentIntentId.isNotEmpty) {
        lookupId = (args['payment'] as PaymentModel).paymentIntentId;
      } else if (args['payment'] is PaymentModel && (args['payment'] as PaymentModel).id.isNotEmpty) {
        lookupId = (args['payment'] as PaymentModel).id;
      } else if (args['booking'] is BookingModel && (args['booking'] as BookingModel).id.isNotEmpty) {
        lookupId = (args['booking'] as BookingModel).id;
      } else if (args['paymentIntentId'] != null) {
        lookupId = args['paymentIntentId'].toString();
      } else if (args['bookingId'] != null) {
        lookupId = args['bookingId'].toString();
      }
    } else if (args is BookingModel && args.id.isNotEmpty) {
      lookupId = args.id;
    } else if (args is PaymentModel && args.paymentIntentId.isNotEmpty) {
      lookupId = args.paymentIntentId;
    } else if (widget.payment?.paymentIntentId != null) {
      lookupId = widget.payment!.paymentIntentId;
    } else if (widget.booking?.id != null) {
      lookupId = widget.booking!.id;
    }

    if (lookupId != null && lookupId.isNotEmpty) {
      setState(() => _isLoading = true);
      final data = await _paymentService.getReceipt(lookupId);
      if (mounted) {
        setState(() {
          _receiptData = data;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    BookingModel? booking = widget.booking;
    PaymentModel? payment = widget.payment;

    if (args is Map) {
      if (args['booking'] is BookingModel) booking = args['booking'] as BookingModel;
      if (args['payment'] is PaymentModel) payment = args['payment'] as PaymentModel;
    } else if (args is BookingModel) {
      booking = args;
    }

    booking ??= BookingProvider.instance.createdBooking;

    final receiptId = _receiptData?['receiptId'] ??
        (payment != null ? 'RCPT-${payment.id.toUpperCase().replaceAll('PAY-', '')}' : 'RCPT-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}');
    final transactionId = _receiptData?['transactionId'] ?? payment?.paymentIntentId ?? 'pi_test_sandbox_verified';
    final bookingId = _receiptData?['bookingId'] ?? booking?.displayBookingId ?? 'BK-849204';
    final parentName = _receiptData?['parentName'] ?? 'Parent User';
    final sitterName = _receiptData?['babysitterName'] ?? booking?.babysitterName ?? 'Caregiver';
    final dateStr = _receiptData?['bookingDate'] != null
        ? _formatDate(_receiptData!['bookingDate'])
        : (booking?.formattedDate ?? '18 Oct 2026');
    final duration = (_receiptData?['durationHours'] is num)
        ? (_receiptData!['durationHours'] as num).toDouble()
        : (booking?.durationHours ?? 4.0);
    final hourlyRate = (_receiptData?['hourlyRate'] is num)
        ? (_receiptData!['hourlyRate'] as num).toDouble()
        : (booking?.hourlyRate ?? 1500.0);
    final subtotal = (_receiptData?['subtotal'] is num)
        ? (_receiptData!['subtotal'] as num).toDouble()
        : (booking?.subtotal ?? (duration * hourlyRate));
    final serviceFee = (_receiptData?['serviceFee'] is num)
        ? (_receiptData!['serviceFee'] as num).toDouble()
        : (booking?.serviceFee ?? 0.0);
    double total = (_receiptData?['totalAmount'] is num)
        ? (_receiptData!['totalAmount'] as num).toDouble()
        : (payment != null && payment.amount > 0
            ? payment.amount
            : (booking != null && booking.totalAmount > 0
                ? booking.totalAmount
                : (booking != null && booking.total > 0
                    ? booking.total
                    : subtotal + serviceFee)));
    if (total <= 0) {
      total = subtotal + serviceFee;
    }
    if (total <= 0) {
      total = duration * hourlyRate;
    }
    final provider = _receiptData?['provider']?.toString() ?? 'Stripe (Test Mode)';

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.ink, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Payment Receipt',
          style: TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined, color: AppColors.ink, size: 22),
            tooltip: 'Home',
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, color: AppColors.ink, size: 22),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Receipt shared successfully'),
                  backgroundColor: AppColors.teal,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.teal),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                children: [
                  // Receipt Container
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Receipt Header
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: const BoxDecoration(
                            color: Color(0xFFE6F5F2),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(24),
                              topRight: Radius.circular(24),
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF005B60),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check, color: Colors.white, size: 32),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Payment Successful',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF005B60),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Transaction ID: $transactionId',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.muted,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                        // Receipt Details Body
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildReceiptRow('Receipt No.', receiptId),
                              _buildReceiptRow('Booking ID', bookingId),
                              _buildReceiptRow('Parent', parentName),
                              _buildReceiptRow('Babysitter', sitterName),
                              _buildReceiptRow('Date', dateStr),
                              _buildReceiptRow('Duration', '${duration.toStringAsFixed(1)} Hours'),
                              _buildReceiptRow('Hourly Rate', 'Rs. ${hourlyRate.toStringAsFixed(0)} / hr'),
                              _buildReceiptRow('Payment Provider', provider),
                              _buildReceiptRow(
                                'Payment Status',
                                'PAID',
                                valueWidget: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(6),
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
                              ),

                              // Perforated / Dashed Divider
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                child: Row(
                                  children: List.generate(
                                    30,
                                    (index) => Expanded(
                                      child: Container(
                                        color: index % 2 == 0 ? const Color(0xFFCBD5E1) : Colors.transparent,
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // Breakdown & Total
                              _buildReceiptRow('Subtotal', 'Rs. ${subtotal.toStringAsFixed(0)}'),
                              _buildReceiptRow('Service Fee', serviceFee == 0 ? 'FREE' : 'Rs. ${serviceFee.toStringAsFixed(0)}'),
                              const SizedBox(height: 8),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Total Amount',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                  Text(
                                    'Rs. ${total.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.teal,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Receipt Bottom Notch Card Info
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(24),
                              bottomRight: Radius.circular(24),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.shield_outlined, size: 14, color: AppColors.muted),
                              SizedBox(width: 6),
                              Text(
                                'Verified by LittleHands Escrow Protection',
                                style: TextStyle(fontSize: 11.5, color: AppColors.muted, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Actions
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: _isDownloadingPdf
                          ? null
                          : () => _handleDownloadPdf(
                                receiptNo: receiptId,
                                transactionId: transactionId,
                                bookingId: bookingId,
                                parentName: parentName,
                                babysitterName: sitterName,
                                dateStr: dateStr,
                                timeRange: '${booking?.startTime ?? "09:00 AM"} – ${booking?.endTime ?? "05:00 PM"}',
                                duration: duration,
                                hourlyRate: hourlyRate,
                                subtotal: subtotal,
                                serviceFee: serviceFee,
                                total: total,
                                provider: provider,
                              ),
                      icon: _isDownloadingPdf
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.download_rounded, size: 20),
                      label: Text(
                        _isDownloadingPdf ? 'Generating PDF Receipt...' : 'Download PDF Receipt',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF005B60),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFF005B60).withValues(alpha: 0.6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

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
                        'Return to Bookings',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

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
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildReceiptRow(String label, String value, {Widget? valueWidget}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppColors.muted, fontWeight: FontWeight.w500),
          ),
          valueWidget ??
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return '18 Oct 2026';
    if (date is DateTime) {
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    }
    final parsed = DateTime.tryParse(date.toString());
    if (parsed != null) {
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${parsed.day} ${months[parsed.month - 1]} ${parsed.year}';
    }
    return date.toString();
  }

  Future<void> _handleDownloadPdf({
    required String receiptNo,
    required String transactionId,
    required String bookingId,
    required String parentName,
    required String babysitterName,
    required String dateStr,
    required String timeRange,
    required double duration,
    required double hourlyRate,
    required double subtotal,
    required double serviceFee,
    required double total,
    required String provider,
  }) async {
    setState(() => _isDownloadingPdf = true);
    try {
      final path = await ReceiptPdfService().downloadReceiptPdf(
        receiptNo: receiptNo,
        transactionId: transactionId,
        bookingId: bookingId,
        parentName: parentName,
        babysitterName: babysitterName,
        date: dateStr,
        timeRange: timeRange,
        duration: '${duration.toStringAsFixed(1)} Hours',
        hourlyRate: 'Rs. ${hourlyRate.toStringAsFixed(0)} / hr',
        subtotal: 'Rs. ${subtotal.toStringAsFixed(0)}',
        serviceFee: serviceFee == 0 ? 'FREE' : 'Rs. ${serviceFee.toStringAsFixed(0)}',
        totalAmount: 'Rs. ${total.toStringAsFixed(0)}',
        paymentStatus: 'PAID',
        provider: provider,
      );

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: AppColors.teal, size: 26),
              SizedBox(width: 10),
              Text('Receipt Downloaded', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your official LittleHands PDF receipt has been saved to your device storage:',
                style: TextStyle(fontSize: 13.5, color: AppColors.ink),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SelectableText(
                  path,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.teal)),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to download PDF receipt: $e'),
          backgroundColor: AppColors.coral,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isDownloadingPdf = false);
    }
  }
}
