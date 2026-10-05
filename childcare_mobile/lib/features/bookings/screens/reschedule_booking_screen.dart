import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../models/booking_model.dart';
import '../models/booking_price_model.dart';
import '../services/booking_service.dart';

class RescheduleBookingScreen extends StatefulWidget {
  final BookingModel? initialBooking;

  const RescheduleBookingScreen({super.key, this.initialBooking});

  @override
  State<RescheduleBookingScreen> createState() => _RescheduleBookingScreenState();
}

class _RescheduleBookingScreenState extends State<RescheduleBookingScreen> {
  final BookingService _service = BookingService();

  BookingModel? _booking;
  DateTime _newDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _newStartTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _newEndTime = const TimeOfDay(hour: 13, minute: 0);

  BookingPriceModel? _recalculatedPrice;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_booking == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is BookingModel) {
        _booking = args;
        _newDate = args.date.add(const Duration(days: 1));
        _parseInitialTimes(args);
        _recalculatePrice();
      } else if (widget.initialBooking != null) {
        _booking = widget.initialBooking;
        _parseInitialTimes(widget.initialBooking!);
        _recalculatePrice();
      }
    }
  }

  void _parseInitialTimes(BookingModel b) {
    try {
      final sParts = b.startTime.split(':');
      if (sParts.length >= 2) {
        _newStartTime = TimeOfDay(
          hour: int.tryParse(sParts[0]) ?? 9,
          minute: int.tryParse(sParts[1].split(' ')[0]) ?? 0,
        );
      }
      final eParts = b.endTime.split(':');
      if (eParts.length >= 2) {
        _newEndTime = TimeOfDay(
          hour: int.tryParse(eParts[0]) ?? 13,
          minute: int.tryParse(eParts[1].split(' ')[0]) ?? 0,
        );
      }
    } catch (_) {}
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatDisplayTime(TimeOfDay time) {
    final hourLabel = time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '${hourLabel.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} $period';
  }

  Future<void> _recalculatePrice() async {
    if (_booking == null) return;
    setState(() => _errorMessage = null);

    final sMin = _newStartTime.hour * 60 + _newStartTime.minute;
    final eMin = _newEndTime.hour * 60 + _newEndTime.minute;
    if (eMin <= sMin) {
      setState(() => _errorMessage = 'End time must be after start time.');
      return;
    }

    try {
      final dateStr = '${_newDate.year}-${_newDate.month.toString().padLeft(2, '0')}-${_newDate.day.toString().padLeft(2, '0')}';
      final price = await _service.calculatePrice(
        babysitterId: _booking!.babysitterId,
        date: dateStr,
        startTime: _formatTimeOfDay(_newStartTime),
        endTime: _formatTimeOfDay(_newEndTime),
      );
      if (mounted) {
        setState(() => _recalculatedPrice = price);
      }
    } catch (_) {}
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _newDate.isBefore(DateTime.now()) ? DateTime.now() : _newDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.teal,
              onPrimary: Colors.white,
              onSurface: AppColors.ink,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _newDate = picked);
      _recalculatePrice();
    }
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _newStartTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.teal,
              onPrimary: Colors.white,
              onSurface: AppColors.ink,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _newStartTime = picked);
      _recalculatePrice();
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _newEndTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.teal,
              onPrimary: Colors.white,
              onSurface: AppColors.ink,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _newEndTime = picked);
      _recalculatePrice();
    }
  }

  Future<void> _handleConfirmReschedule() async {
    if (_booking == null) return;
    final sMin = _newStartTime.hour * 60 + _newStartTime.minute;
    final eMin = _newEndTime.hour * 60 + _newEndTime.minute;
    if (eMin <= sMin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End time must be after start time.'),
          backgroundColor: AppColors.coral,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Confirm Reschedule',
          style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink),
        ),
        content: Text(
          'Change care reservation to ${_newDate.day}/${_newDate.month}/${_newDate.year} (${_formatDisplayTime(_newStartTime)} – ${_formatDisplayTime(_newEndTime)})?',
          style: const TextStyle(color: AppColors.muted, fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.muted)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF005B60),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Confirm', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final dateStr = '${_newDate.year}-${_newDate.month.toString().padLeft(2, '0')}-${_newDate.day.toString().padLeft(2, '0')}';
      final res = await _service.rescheduleBooking(
        _booking!.id,
        date: dateStr,
        startTime: _formatTimeOfDay(_newStartTime),
        endTime: _formatTimeOfDay(_newEndTime),
      );

      if (mounted) {
        if (res != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Care reservation rescheduled successfully!'),
              backgroundColor: AppColors.teal,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to reschedule. Selected slot may have a conflict.'),
              backgroundColor: AppColors.coral,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
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

    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dateDisplay = '${_newDate.day} ${months[_newDate.month - 1]} ${_newDate.year}';

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        title: const Text(
          'Reschedule Care',
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
          const Text(
            'Choose new time slot',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Select a new date and schedule for your caregiver.',
            style: TextStyle(color: AppColors.muted, fontSize: 13.5),
          ),
          const SizedBox(height: 18),

          // Current Schedule Reference Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.history_rounded, size: 20, color: AppColors.muted),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current Schedule',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.muted),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${b.formattedDate} (${b.timeRange})',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Date Picker Card
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
                  'New Date',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.teal),
                            const SizedBox(width: 10),
                            Text(
                              dateDisplay,
                              style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.ink),
                            ),
                          ],
                        ),
                        const Icon(Icons.arrow_drop_down, color: AppColors.muted),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Time Range Picker Card
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
                  'New Time Range',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Start Time
                    Expanded(
                      child: GestureDetector(
                        onTap: _pickStartTime,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Start Time', style: TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.schedule, size: 15, color: AppColors.teal),
                                  const SizedBox(width: 6),
                                  Text(
                                    _formatDisplayTime(_newStartTime),
                                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.ink),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // End Time
                    Expanded(
                      child: GestureDetector(
                        onTap: _pickEndTime,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('End Time', style: TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.schedule, size: 15, color: AppColors.teal),
                                  const SizedBox(width: 6),
                                  Text(
                                    _formatDisplayTime(_newEndTime),
                                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.ink),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Pricing & Duration Feedback
          if (_recalculatedPrice != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
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
                      const Text('Updated Duration', style: TextStyle(fontSize: 12, color: AppColors.muted)),
                      const SizedBox(height: 2),
                      Text(
                        '${_recalculatedPrice!.duration.toStringAsFixed(1)} Hours',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Total Amount', style: TextStyle(fontSize: 12, color: AppColors.muted)),
                      const SizedBox(height: 2),
                      Text(
                        'Rs. ${_recalculatedPrice!.totalAmount.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.teal),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

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
                  const Icon(Icons.error_outline_rounded, color: AppColors.coral, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: _isLoading ? null : _handleConfirmReschedule,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF005B60),
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
                      'Confirm Reschedule',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
