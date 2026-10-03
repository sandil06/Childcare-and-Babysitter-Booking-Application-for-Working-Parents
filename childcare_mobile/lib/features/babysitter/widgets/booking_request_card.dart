import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../models/booking_request_model.dart';

class BookingRequestCard extends StatelessWidget {
  const BookingRequestCard({
    super.key,
    required this.booking,
    required this.onTap,
    this.onAccept,
    this.onReject,
  });

  final BookingRequestModel booking;
  final VoidCallback onTap;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  Color _getStatusBg(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
      case 'confirmed':
        return AppColors.mint;
      case 'in_progress':
      case 'travelling':
      case 'arrived':
        return const Color(0xFFE0F2FE);
      case 'completed':
        return AppColors.mint;
      case 'cancelled':
      case 'rejected':
        return const Color(0xFFFDE8E8);
      case 'pending':
      default:
        return AppColors.sand;
    }
  }

  Color _getStatusFg(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
      case 'confirmed':
        return AppColors.teal;
      case 'in_progress':
      case 'travelling':
      case 'arrived':
        return const Color(0xFF0284C7);
      case 'completed':
        return AppColors.teal;
      case 'cancelled':
      case 'rejected':
        return AppColors.coral;
      case 'pending':
      default:
        return const Color(0xFF92400E);
    }
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final statusBg = _getStatusBg(booking.status);
    final statusFg = _getStatusFg(booking.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header: Parent + Status
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.sand,
                      child: Text(
                        booking.parentName.isNotEmpty
                            ? booking.parentName[0]
                            : 'P',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.parentName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            booking.bookingId,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.muted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        booking.status.toUpperCase(),
                        style: TextStyle(
                          color: statusFg,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 22, color: AppColors.sand),

                // Date & Time Row
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        size: 15, color: AppColors.teal),
                    const SizedBox(width: 6),
                    Text(
                      _formatDate(booking.date),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Icon(Icons.access_time_rounded,
                        size: 15, color: AppColors.teal),
                    const SizedBox(width: 6),
                    Text(
                      '${booking.timeFormatted} (${booking.durationHours.toInt()}h)',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Location Row
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 16, color: AppColors.muted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        booking.location,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                // Children Details
                if (booking.childrenDetails.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.child_care_rounded,
                          size: 16, color: AppColors.muted),
                      const SizedBox(width: 6),
                      Text(
                        booking.childrenDetails
                            .map((c) => '${c.name} (${c.age}y)')
                            .join(', '),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 12),
                // Price & Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '\$${booking.totalAmount.toInt()}.00',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    if (booking.isPending && onAccept != null && onReject != null)
                      Row(
                        children: [
                          OutlinedButton(
                            onPressed: onReject,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.coral,
                              side: const BorderSide(color: AppColors.coral),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('Decline'),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: onAccept,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.teal,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('Accept'),
                          ),
                        ],
                      )
                    else
                      const Row(
                        children: [
                          Text(
                            'Details',
                            style: TextStyle(
                              color: AppColors.teal,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded,
                              size: 18, color: AppColors.teal),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
