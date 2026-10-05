import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../models/availability_model.dart';
import '../providers/babysitter_provider.dart';
import '../widgets/availability_card.dart';

class AvailabilityScreen extends StatefulWidget {
  const AvailabilityScreen({super.key});

  @override
  State<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  final BabysitterProvider _provider = BabysitterProvider.instance;
  late DateTime _selectedDate;
  late List<DateTime> _dates;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _dates = List.generate(
      14,
      (i) => DateTime(now.year, now.month, now.day).add(Duration(days: i)),
    );
    _provider.addListener(_onStateChanged);
    _provider.fetchAvailabilities();
  }

  @override
  void dispose() {
    _provider.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  List<AvailabilityModel> get _slotsForSelectedDate {
    return _provider.availabilities.where((slot) {
      final isSameDay = slot.date.year == _selectedDate.year &&
          slot.date.month == _selectedDate.month &&
          slot.date.day == _selectedDate.day;
      if (isSameDay) return true;
      if (slot.isRecurring) {
        if (slot.repeatDays.isNotEmpty) {
          return slot.repeatDays.contains(_selectedDate.weekday);
        }
        return slot.date.weekday == _selectedDate.weekday;
      }
      return false;
    }).toList();
  }

  bool get _isCurrentDateFullyUnavailable {
    final slots = _slotsForSelectedDate;
    if (slots.isEmpty) return false;
    return slots.every((s) => !s.available);
  }

  void _toggleDateUnavailable(bool makeUnavailable) async {
    final slots = _slotsForSelectedDate;
    if (makeUnavailable) {
      if (slots.isEmpty) {
        final slot = AvailabilityModel(
          id: 'av-${DateTime.now().millisecondsSinceEpoch}',
          babysitterId: _provider.profile?.id ?? 'sitter-1',
          date: _selectedDate,
          startTime: '00:00',
          endTime: '23:59',
          available: false,
        );
        await _provider.addAvailabilitySlot(slot);
      } else {
        for (var s in slots) {
          final updated = s.copyWith(available: false);
          await _provider.updateAvailabilitySlot(updated);
        }
      }
    } else {
      for (var s in slots) {
        if (!s.available && s.startTime == '00:00' && s.endTime == '23:59') {
          await _provider.deleteAvailabilitySlot(s.id);
        } else {
          final updated = s.copyWith(available: true);
          await _provider.updateAvailabilitySlot(updated);
        }
      }
    }
    setState(() {});
  }

  Future<void> _openAddOrEditSlotModal({AvailabilityModel? existing}) async {
    TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 17, minute: 0);
    bool isRecurring = existing?.isRecurring ?? false;

    if (existing != null) {
      final sParts = existing.startTime.split(':');
      final eParts = existing.endTime.split(':');
      if (sParts.length == 2) {
        startTime = TimeOfDay(
          hour: int.tryParse(sParts[0]) ?? 9,
          minute: int.tryParse(sParts[1]) ?? 0,
        );
      }
      if (eParts.length == 2) {
        endTime = TimeOfDay(
          hour: int.tryParse(eParts[0]) ?? 17,
          minute: int.tryParse(eParts[1]) ?? 0,
        );
      }
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final startMinutes = startTime.hour * 60 + startTime.minute;
            final endMinutes = endTime.hour * 60 + endTime.minute;
            final isInvalidInterval = endMinutes <= startMinutes;

            return Padding(
              padding: EdgeInsets.only(
                left: AppSizes.pagePadding,
                right: AppSizes.pagePadding,
                top: 24,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 28,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        existing != null ? 'Edit Time Slot' : 'Add Time Slot',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: AppColors.muted),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Set your working hours for ${_formatDateHeader(_selectedDate)}',
                    style: const TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                  const SizedBox(height: 24),

                  // Start and End Time Selectors
                  Row(
                    children: [
                      Expanded(
                        child: _buildTimePickerBox(
                          label: 'Start Time',
                          time: startTime,
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: startTime,
                            );
                            if (picked != null) {
                              setModalState(() => startTime = picked);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildTimePickerBox(
                          label: 'End Time',
                          time: endTime,
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: endTime,
                            );
                            if (picked != null) {
                              setModalState(() => endTime = picked);
                            }
                          },
                        ),
                      ),
                    ],
                  ),

                  if (isInvalidInterval) ...[
                    const SizedBox(height: 10),
                    const Row(
                      children: [
                        Icon(Icons.error_outline_rounded,
                            size: 16, color: AppColors.coral),
                        SizedBox(width: 6),
                        Text(
                          'End time must be after start time',
                          style: TextStyle(
                            color: AppColors.coral,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Recurring switch
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.cream,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.sand),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.repeat_rounded,
                            color: AppColors.teal, size: 20),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Repeat Weekly',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                              Text(
                                'Apply this slot to this weekday every week',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: isRecurring,
                          activeTrackColor: AppColors.teal,
                          onChanged: (val) {
                            setModalState(() => isRecurring = val);
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Save Action
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: isInvalidInterval
                          ? null
                          : () async {
                              final startStr =
                                  '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
                              final endStr =
                                  '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';

                              bool ok = false;
                              if (existing != null) {
                                final updated = existing.copyWith(
                                  startTime: startStr,
                                  endTime: endStr,
                                  isRecurring: isRecurring,
                                );
                                ok = await _provider.updateAvailabilitySlot(updated);
                              } else {
                                final newSlot = AvailabilityModel(
                                  id: 'av-${DateTime.now().millisecondsSinceEpoch}',
                                  babysitterId:
                                      _provider.profile?.id ?? 'sitter-1',
                                  date: _selectedDate,
                                  startTime: startStr,
                                  endTime: endStr,
                                  available: true,
                                  isRecurring: isRecurring,
                                );
                                ok = await _provider.addAvailabilitySlot(newSlot);
                              }
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(ok
                                        ? (existing != null
                                            ? 'Slot updated successfully!'
                                            : 'Slot added successfully!')
                                        : (_provider.errorMessage ??
                                            'Failed to save slot')),
                                    backgroundColor:
                                        ok ? AppColors.teal : AppColors.coral,
                                  ),
                                );
                              }
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.ink,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        existing != null ? 'Update Slot' : 'Save Slot',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDeleteSlot(AvailabilityModel slot) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete Time Slot?',
          style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Remove the slot ${slot.timeRangeLabel} for ${_formatDateHeader(_selectedDate)}?',
          style: const TextStyle(color: AppColors.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.muted)),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await _provider.deleteAvailabilitySlot(slot.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ok
                        ? 'Slot removed successfully!'
                        : (_provider.errorMessage ?? 'Failed to delete slot')),
                    backgroundColor: ok ? AppColors.teal : AppColors.coral,
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.coral,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildTimePickerBox({
    required String label,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.sand),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  time.format(context),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const Icon(Icons.access_time_rounded,
                    size: 18, color: AppColors.teal),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateHeader(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    final slots = _slotsForSelectedDate;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Availability Management',
          style: TextStyle(
            color: AppColors.ink,
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Horizontal Date Carousel
            Container(
              height: 94,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.builder(
                physics: const ClampingScrollPhysics(),
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _dates.length,
                itemBuilder: (context, index) {
                  final date = _dates[index];
                  final isSelected = date.year == _selectedDate.year &&
                      date.month == _selectedDate.month &&
                      date.day == _selectedDate.day;
                  final isToday = index == 0;

                  const weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                  final dayChar = weekdays[date.weekday - 1];

                  return GestureDetector(
                    onTap: () => setState(() => _selectedDate = date),
                    child: Container(
                      width: 58,
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.teal : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.teal
                              : AppColors.sand.withValues(alpha: 0.6),
                          width: 1.2,
                        ),
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(
                              color: AppColors.teal.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            dayChar,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white70 : AppColors.muted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            date.day.toString(),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white : AppColors.ink,
                            ),
                          ),
                          if (isToday) ...[
                            const SizedBox(height: 3),
                            Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.white : AppColors.teal,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 1, color: AppColors.sand),

            Expanded(
              child: ScrollConfiguration(
                behavior:
                    ScrollConfiguration.of(context).copyWith(overscroll: false),
                child: RefreshIndicator(
                  displacement: 20,
                  edgeOffset: 0,
                  color: AppColors.teal,
                  onRefresh: () async {
                    await _provider.fetchAvailabilities();
                  },
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: ClampingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.all(AppSizes.pagePadding),
                children: [
                  // Selected Date Header and Add button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatDateHeader(_selectedDate),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                          Text(
                            '${slots.length} slot${slots.length == 1 ? '' : 's'} configured',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                      FilledButton.icon(
                        onPressed: () => _openAddOrEditSlotModal(),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add Slot'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Entire Day Unavailable Toggle
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.sand),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.block_rounded,
                            color: AppColors.coral, size: 20),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mark Date as Unavailable',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                              Text(
                                'Prevent any parent bookings on this date',
                                style: TextStyle(
                                    fontSize: 11, color: AppColors.muted),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _isCurrentDateFullyUnavailable,
                          activeTrackColor: AppColors.coral,
                          onChanged: (val) => _toggleDateUnavailable(val),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Slots List
                  if (slots.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                              color: AppColors.cream,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.event_busy_rounded,
                              size: 36,
                              color: AppColors.muted,
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'No Time Slots Configured',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Tap "+ Add Slot" above to set available childcare hours for this day.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.muted,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...slots.map((slot) {
                      return AvailabilityCard(
                        slot: slot,
                        onEdit: () => _openAddOrEditSlotModal(existing: slot),
                        onDelete: () => _confirmDeleteSlot(slot),
                      );
                    }),
                ],
              ),
            ),
          ),
        ),
          ],
        ),
      ),
    );
  }
}
