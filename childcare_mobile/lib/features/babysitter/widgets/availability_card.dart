import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../models/availability_model.dart';

class AvailabilityCard extends StatelessWidget {
  const AvailabilityCard({
    super.key,
    required this.slot,
    required this.onEdit,
    required this.onDelete,
  });

  final AvailabilityModel slot;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: slot.available
              ? AppColors.teal.withValues(alpha: 0.3)
              : AppColors.sand,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: slot.available ? AppColors.mint : AppColors.sand,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.access_time_filled_rounded,
              color: slot.available ? AppColors.teal : AppColors.muted,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      slot.timeRangeLabel,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    if (slot.isRecurring) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.sand,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Repeating',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  slot.available
                      ? 'Available for bookings'
                      : 'Marked unavailable',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: slot.available ? AppColors.teal : AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined,
                size: 20, color: AppColors.teal),
            onPressed: onEdit,
            tooltip: 'Edit Slot',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                size: 20, color: AppColors.coral),
            onPressed: onDelete,
            tooltip: 'Delete Slot',
          ),
        ],
      ),
    );
  }
}
