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

class _BookingTimeScreenState extends State<BookingTimeScreen>
    with SingleTickerProviderStateMixin {
  final _booking = BookingProvider.instance;
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _booking.addListener(_refresh);
    _animationController.forward();
  }

  @override
  void dispose() {
    _booking.removeListener(_refresh);
    _animationController.dispose();
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
          : TimeOfDay(
              hour: existing.hour,
              minute: existing.minute,
            ),
      helpText: widget.mode == BookingTimeMode.start
          ? 'Choose start time'
          : 'Choose end time',
    );

    if (picked == null) return;

    final value = TimeOfDayValue(
      hour: picked.hour,
      minute: picked.minute,
    );

    if (widget.mode == BookingTimeMode.start) {
      _booking.selectStartTime(value);
    } else if (_booking.startTime == null ||
        value.toMinutes <= _booking.startTime!.toMinutes) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'End time must be later than the start time.',
            ),
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

    return '${weekdays[date.weekday - 1]}, '
        '${months[date.month - 1]} ${date.day}';
  }

  String _stepLabel(bool isStart) {
    return isStart ? 'Step 2 of 4' : 'Step 3 of 4';
  }

  String _title(bool isStart) {
    return isStart
        ? 'When should care begin?'
        : 'When should care end?';
  }

  String _subtitle(bool isStart) {
    return isStart
        ? 'Choose a convenient start time for your childcare booking.'
        : 'Choose an end time after your selected start time.';
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
        backgroundColor: AppColors.cream,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isStart ? 'Start Time' : 'End Time',
          style: const TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.pagePadding,
                  8,
                  AppSizes.pagePadding,
                  130,
                ),
                children: [
                  _ProgressHeader(
                    isStart: isStart,
                  ),
                  const SizedBox(height: 28),
                  Text(
                    _stepLabel(isStart),
                    style: const TextStyle(
                      color: AppColors.teal,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _title(isStart),
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _subtitle(isStart),
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _BookingContextCard(
                    date: _dateLabel(_booking.selectedDate),
                    start: isStart
                        ? null
                        : _booking.startTime?.formatted,
                  ),
                  const SizedBox(height: 18),
                  _TimeSelectorCard(
                    isStart: isStart,
                    selected: selected,
                    onTap: _chooseTime,
                  ),
                  if (!isStart) ...[
                    const SizedBox(height: 14),
                    const _InfoBanner(
                      text:
                          'Your end time must be later than your start time.',
                    ),
                  ],
                  if (selected != null) ...[
                    const SizedBox(height: 22),
                    _SelectedTimeCard(
                      label: isStart
                          ? 'Start time selected'
                          : 'End time selected',
                      time: selected.formatted,
                      icon: isStart
                          ? Icons.play_arrow_rounded
                          : Icons.stop_rounded,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSizes.pagePadding,
          14,
          AppSizes.pagePadding,
          20,
        ),
        decoration: BoxDecoration(
          color: AppColors.cream,
          boxShadow: [
            BoxShadow(
              blurRadius: 18,
              offset: const Offset(0, -6),
              color: Colors.black.withValues(alpha: 0.06),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: canContinue
                  ? () => Navigator.pushNamed(
                      context,
                      isStart
                          ? AppRoutes.bookingEndTime
                          : AppRoutes.bookingSummary,
                    )
                  : null,
              icon: Icon(
                isStart
                    ? Icons.arrow_forward_rounded
                    : Icons.rate_review_outlined,
              ),
              label: Text(
                isStart ? 'Continue' : 'Review Booking',
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.isStart});

  final bool isStart;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Step(
          label: 'Date',
          active: false,
          completed: true,
        ),
        _Line(active: true),
        _Step(
          label: 'Start',
          active: isStart,
          completed: !isStart,
        ),
        _Line(active: !isStart),
        _Step(
          label: 'End',
          active: !isStart,
          completed: false,
        ),
        _Line(active: false),
        _Step(
          label: 'Summary',
          active: false,
          completed: false,
        ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.label,
    required this.active,
    required this.completed,
  });

  final String label;
  final bool active;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: active || completed
                ? AppColors.teal
                : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: active || completed
                  ? AppColors.teal
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Icon(
            completed
                ? Icons.check_rounded
                : active
                    ? Icons.circle
                    : Icons.circle_outlined,
            size: completed ? 16 : 8,
            color: active || completed
                ? Colors.white
                : AppColors.muted,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: active ? AppColors.ink : AppColors.muted,
            fontSize: 10,
            fontWeight: active ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 20),
        color: active
            ? AppColors.teal
            : const Color(0xFFE2E8F0),
      ),
    );
  }
}

class _BookingContextCard extends StatelessWidget {
  const _BookingContextCard({
    required this.date,
    this.start,
  });

  final String date;
  final String? start;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'BOOKING DETAILS',
            style: TextStyle(
              color: AppColors.teal,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_rounded,
                color: AppColors.teal,
                size: 18,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  date,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
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
                const SizedBox(width: 9),
                Text(
                  'Start time: $start',
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 14,
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

class _TimeSelectorCard extends StatelessWidget {
  const _TimeSelectorCard({
    required this.isStart,
    required this.selected,
    required this.onTap,
  });

  final bool isStart;
  final TimeOfDayValue? selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasSelection = selected != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: hasSelection
                  ? AppColors.teal
                  : const Color(0xFFE2E8F0),
              width: hasSelection ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                blurRadius: 20,
                offset: const Offset(0, 8),
                color: Colors.black.withValues(alpha: 0.05),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.mint,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.schedule_rounded,
                  color: AppColors.teal,
                  size: 32,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                isStart ? 'START TIME' : 'END TIME',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                selected?.formatted ?? 'Tap to choose',
                style: TextStyle(
                  color: hasSelection
                      ? AppColors.ink
                      : AppColors.muted,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                hasSelection
                    ? 'Tap to change your selection'
                    : 'Select a suitable time for childcare',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: AppColors.teal,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedTimeCard extends StatelessWidget {
  const _SelectedTimeCard({
    required this.label,
    required this.time,
    required this.icon,
  });

  final String label;
  final String time;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color: AppColors.teal,
              size: 22,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  time,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.check_circle_rounded,
            color: AppColors.teal,
          ),
        ],
      ),
    );
  }
}