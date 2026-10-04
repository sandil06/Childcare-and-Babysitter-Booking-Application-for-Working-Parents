import 'package:flutter/material.dart';

import '../../../config/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../bookings/providers/booking_provider.dart';

enum BookingTimeMode { start, end }

class BookingTimeScreen extends StatefulWidget {
  const BookingTimeScreen({super.key, required this.mode});
  final BookingTimeMode mode;

  @override
  State<BookingTimeScreen> createState() => _BookingTimeScreenState();
}

class _BookingTimeScreenState extends State<BookingTimeScreen> {
  final _booking = BookingProvider.instance;

  @override
  void initState() {
    super.initState();
    _booking.addListener(_refresh);
  }

  @override
  void dispose() {
    _booking.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _chooseTime() async {
    final existing = widget.mode == BookingTimeMode.start
        ? _booking.startTime
        : _booking.endTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: existing == null
          ? const TimeOfDay(hour: 9, minute: 0)
          : TimeOfDay(hour: existing.hour, minute: existing.minute),
      helpText: widget.mode == BookingTimeMode.start
          ? 'Choose start time'
          : 'Choose end time',
    );
    if (picked == null) return;
    final value = TimeOfDayValue(hour: picked.hour, minute: picked.minute);
    if (widget.mode == BookingTimeMode.start) {
      _booking.selectStartTime(value);
    } else if (_booking.startTime == null ||
        value.toMinutes <= _booking.startTime!.toMinutes) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('End time must be later than the start time.'),
          ),
        );
      }
    } else {
      _booking.selectEndTime(value);
    }
  }

  String _dateLabel(DateTime? date) {
    if (date == null) return 'No date selected';
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
    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    final isStart = widget.mode == BookingTimeMode.start;
    final selected = isStart ? _booking.startTime : _booking.endTime;
    final canContinue =
        selected != null && (isStart || _booking.startTime != null);
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text(isStart ? 'Select Start Time' : 'Select End Time'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.pagePadding),
        children: [
          Text(
            isStart
                ? 'Choose when care should begin'
                : 'Choose when care should end',
            style: const TextStyle(color: AppColors.muted, fontSize: 15),
          ),
          const SizedBox(height: 18),
          _ContextPanel(
            date: _dateLabel(_booking.selectedDate),
            start: isStart ? null : _booking.startTime?.formatted,
          ),
          const SizedBox(height: 18),
          InkWell(
            onTap: _chooseTime,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected == null ? AppColors.sand : AppColors.teal,
                  width: selected == null ? 1 : 1.5,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    color: AppColors.teal,
                    size: 30,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isStart ? 'Start time' : 'End time',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          selected?.formatted ?? 'Tap to choose a time',
                          style: TextStyle(
                            color: selected == null
                                ? AppColors.muted
                                : AppColors.ink,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.edit_calendar_rounded,
                    color: AppColors.teal,
                  ),
                ],
              ),
            ),
          ),
          if (!isStart) ...[
            const SizedBox(height: 12),
            const Text(
              'End time must be later than the selected start time.',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: canContinue
                ? () => Navigator.pushNamed(
                    context,
                    isStart
                        ? AppRoutes.bookingEndTime
                        : AppRoutes.bookingSummary,
                  )
                : null,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: Text(isStart ? 'Continue' : 'Review Booking'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContextPanel extends StatelessWidget {
  const _ContextPanel({required this.date, this.start});
  final String date;
  final String? start;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.calendar_today_rounded,
                color: AppColors.teal,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  date,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (start != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.play_circle_outline_rounded,
                  color: AppColors.teal,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Start time: $start',
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
