import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../models/booking_model.dart';
import 'status_chip.dart';

class BookingCard extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback onTap;

  const BookingCard({
    super.key,
    required this.booking,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Avatar, Name, Reference, Status Chip
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.mint,
                  child: Text(
                    booking.babysitterName.isNotEmpty
                        ? booking.babysitterName[0].toUpperCase()
                        : 'C',
                    style: const TextStyle(
                      color: AppColors.teal,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              booking.babysitterName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.verified, size: 14, color: AppColors.teal),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        booking.bookingId,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusChip(status: booking.status, isCompact: true),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: AppColors.sand, height: 1),
            ),

            // Middle: Date & Time Info
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 15, color: AppColors.teal),
                const SizedBox(width: 6),
                Text(
                  booking.formattedDate,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.schedule_rounded, size: 15, color: AppColors.teal),
                const SizedBox(width: 6),
                Text(
                  booking.timeRange,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Location Info
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 15, color: AppColors.muted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    booking.location,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.muted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Bottom Row: Price and View Details Action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Rs. ${booking.totalAmount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.teal,
                  ),
                ),
                Row(
                  children: const [
                    Text(
                      'View Details',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF005B60),
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: Color(0xFF005B60),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
