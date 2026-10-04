import 'package:flutter/material.dart';

import '../../../config/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../babysitter/models/babysitter_model.dart';
import '../../bookings/providers/booking_provider.dart';
import '../providers/parent_provider.dart';

class BookingDateScreen extends StatefulWidget {
  const BookingDateScreen({super.key});

  @override
  State<BookingDateScreen> createState() => _BookingDateScreenState();
}

class _BookingDateScreenState extends State<BookingDateScreen>
    with SingleTickerProviderStateMixin {
  final _booking = BookingProvider.instance;

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _booking.addListener(_refresh);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );

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

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  String _formatDate(DateTime date) {
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
        '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _shortDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[date.month - 1]} ${date.day}';
  }

  void _selectDate(DateTime date) {
    _booking.selectDate(date);
  }

  void _selectQuickDate(DateTime date) {
    _selectDate(date);
  }

  DateTime _nextSaturday() {
    final difference = DateTime.saturday - _today.weekday;
    final daysUntilSaturday = difference <= 0 ? difference + 7 : difference;
    return _today.add(Duration(days: daysUntilSaturday));
  }

  @override
  Widget build(BuildContext context) {
    final sitter = ParentProvider.instance.selectedBabysitter;
    final selectedDate = _booking.selectedDate;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        title: const Text(
          'Book a babysitter',
          style: TextStyle(
            color: AppColors.ink,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.ink,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.pagePadding,
              8,
              AppSizes.pagePadding,
              130,
            ),
            children: [
              const _BookingProgress(currentStep: 1),
              const SizedBox(height: 26),

              const Text(
                'When do you need\nchildcare?',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 30,
                  height: 1.12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.7,
                ),
              ),
              const SizedBox(height: 9),
              const Text(
                'Choose a date that works best for your family.',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),

              const SizedBox(height: 22),

              if (sitter != null) ...[
                _SitterContextCard(sitter: sitter),
                const SizedBox(height: 24),
              ],

              const Text(
                'Select a date',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),

              _QuickDateRow(
                today: _today,
                tomorrow: _today.add(const Duration(days: 1)),
                weekend: _nextSaturday(),
                selectedDate: selectedDate,
                onSelected: _selectQuickDate,
                shortDate: _shortDate,
              ),

              const SizedBox(height: 18),

              _CalendarCard(
                firstDate: _today,
                selectedDate: selectedDate ?? _today,
                onDateChanged: _selectDate,
              ),

              const SizedBox(height: 18),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: selectedDate == null
                    ? const _DateHintCard()
                    : _SelectedDateCard(
                        key: ValueKey(selectedDate),
                        date: selectedDate,
                        formattedDate: _formatDate(selectedDate),
                      ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _BottomContinue(
        enabled: selectedDate != null,
        onPressed: selectedDate == null
            ? null
            : () => Navigator.pushNamed(
                context,
                AppRoutes.bookingStartTime,
              ),
      ),
    );
  }
}

class _BookingProgress extends StatelessWidget {
  const _BookingProgress({required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    const steps = ['Date', 'Start time', 'End time', 'Summary'];

    return Row(
      children: List.generate(steps.length, (index) {
        final stepNumber = index + 1;
        final active = stepNumber == currentStep;
        final completed = stepNumber < currentStep;

        return Expanded(
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: active || completed
                              ? AppColors.ink
                              : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: active || completed
                                ? AppColors.ink
                                : Color(0xFFE2E8F0),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: completed
                            ? const Icon(
                                Icons.check_rounded,
                                size: 16,
                                color: Colors.white,
                              )
                            : Text(
                                '$stepNumber',
                                style: TextStyle(
                                  color: active
                                      ? Colors.white
                                      : AppColors.muted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Text(
                    steps[index],
                    style: TextStyle(
                      color: active ? AppColors.ink : AppColors.muted,
                      fontSize: 10,
                      fontWeight:
                          active ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (index != steps.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(
                      left: 8,
                      right: 8,
                      bottom: 22,
                    ),
                    color: index < currentStep - 1
                        ? AppColors.ink
                        : Color(0xFFE2E8F0),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}

class _SitterContextCard extends StatelessWidget {
  const _SitterContextCard({required this.sitter});

  final BabysitterModel sitter;

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .toList();

    if (parts.isEmpty) return 'S';

    return parts.map((part) => part[0]).join().toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final hasImage =
        sitter.profileImage != null &&
        sitter.profileImage!.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Color(0xFFE2E8F0).withValues(alpha: 0.7),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: hasImage
                ? Image.network(
                    sitter.profileImage!,
                    width: 58,
                    height: 58,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _avatar(),
                  )
                : _avatar(),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        sitter.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (sitter.isVerified) ...[
                      const SizedBox(width: 5),
                      const Icon(
                        Icons.verified_rounded,
                        size: 16,
                        color: AppColors.teal,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 15,
                      color: Color(0xFFF4B740),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      sitter.totalReviews > 0
                          ? sitter.averageRating.toStringAsFixed(1)
                          : 'New',
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 3,
                      height: 3,
                      decoration: const BoxDecoration(
                        color: AppColors.muted,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${sitter.experienceYears} yrs experience',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.muted,
          ),
        ],
      ),
    );
  }

  Widget _avatar() => Container(
    width: 58,
    height: 58,
    color: AppColors.mint,
    alignment: Alignment.center,
    child: Text(
      _initials(sitter.name),
      style: const TextStyle(
        color: AppColors.teal,
        fontSize: 18,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

class _QuickDateRow extends StatelessWidget {
  const _QuickDateRow({
    required this.today,
    required this.tomorrow,
    required this.weekend,
    required this.selectedDate,
    required this.onSelected,
    required this.shortDate,
  });

  final DateTime today;
  final DateTime tomorrow;
  final DateTime weekend;
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onSelected;
  final String Function(DateTime) shortDate;

  bool _sameDay(DateTime? first, DateTime second) {
    if (first == null) return false;

    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  @override
  Widget build(BuildContext context) {
    final options = [
      ('Today', today),
      ('Tomorrow', tomorrow),
      ('This weekend', weekend),
    ];

    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final option = options[index];
          final selected = _sameDay(selectedDate, option.$2);

          return GestureDetector(
            onTap: () => onSelected(option.$2),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: index == 2 ? 125 : 104,
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: selected ? AppColors.ink : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected
                      ? AppColors.ink
                      : Color(0xFFE2E8F0).withValues(alpha: 0.7),
                ),
                boxShadow: [
                  if (!selected)
                    BoxShadow(
                      color: AppColors.ink.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    option.$1,
                    style: TextStyle(
                      color: selected ? Colors.white : AppColors.ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    shortDate(option.$2),
                    style: TextStyle(
                      color: selected
                          ? Colors.white.withValues(alpha: 0.72)
                          : AppColors.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CalendarCard extends StatelessWidget {
  const _CalendarCard({
    required this.firstDate,
    required this.selectedDate,
    required this.onDateChanged,
  });

  final DateTime firstDate;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Color(0xFFE2E8F0).withValues(alpha: 0.7),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.055),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: AppColors.ink,
            onPrimary: Colors.white,
            surface: Colors.white,
          ),
        ),
        child: CalendarDatePicker(
          initialDate: selectedDate,
          firstDate: firstDate,
          lastDate: firstDate.add(const Duration(days: 365)),
          onDateChanged: onDateChanged,
        ),
      ),
    );
  }
}

class _DateHintCard extends StatelessWidget {
  const _DateHintCard();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: Color(0xFFE2E8F0).withValues(alpha: 0.6),
      ),
    ),
    child: const Row(
      children: [
        Icon(
          Icons.event_available_rounded,
          color: AppColors.teal,
          size: 22,
        ),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            'Pick a date above to continue with your booking.',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
      ],
    ),
  );
}

class _SelectedDateCard extends StatelessWidget {
  const _SelectedDateCard({
    super.key,
    required this.date,
    required this.formattedDate,
  });

  final DateTime date;
  final String formattedDate;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          AppColors.mint,
          AppColors.mint.withValues(alpha: 0.55),
        ],
      ),
      borderRadius: BorderRadius.circular(19),
      border: Border.all(
        color: AppColors.teal.withValues(alpha: 0.16),
      ),
    ),
    child: Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(
            Icons.event_rounded,
            color: AppColors.teal,
            size: 22,
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Booking date',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                formattedDate,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 14,
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

class _BottomContinue extends StatelessWidget {
  const _BottomContinue({
    required this.enabled,
    required this.onPressed,
  });

  final bool enabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
    decoration: BoxDecoration(
      color: AppColors.cream,
      boxShadow: [
        BoxShadow(
          color: AppColors.ink.withValues(alpha: 0.08),
          blurRadius: 20,
          offset: const Offset(0, -6),
        ),
      ],
    ),
    child: SafeArea(
      top: false,
      child: SizedBox(
        height: 54,
        width: double.infinity,
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.ink,
            disabledBackgroundColor: Color(0xFFE2E8F0),
            foregroundColor: Colors.white,
            disabledForegroundColor: AppColors.muted,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(17),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                enabled ? 'Continue to start time' : 'Select a date to continue',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (enabled) ...[
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 19,
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}