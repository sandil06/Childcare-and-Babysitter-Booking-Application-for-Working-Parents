import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class StatusChip extends StatelessWidget {
  final String status;
  final bool isCompact;

  const StatusChip({
    super.key,
    required this.status,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final lower = status.toLowerCase();
    Color bg;
    Color fg;
    Color border;
    IconData icon;
    String label = status;

    switch (lower) {
      case 'accepted':
      case 'confirmed':
        bg = const Color(0xFFE6F5F2);
        fg = AppColors.teal;
        border = const Color(0xFFB2DFDB);
        icon = Icons.check_circle_outline_rounded;
        label = lower == 'accepted' ? 'Accepted' : 'Confirmed';
        break;
      case 'travelling':
        bg = const Color(0xFFE0F2FE);
        fg = const Color(0xFF0284C7);
        border = const Color(0xFFBAE6FD);
        icon = Icons.directions_car_rounded;
        label = 'Travelling';
        break;
      case 'arrived':
        bg = const Color(0xFFE0F2FE);
        fg = const Color(0xFF0369A1);
        border = const Color(0xFFBAE6FD);
        icon = Icons.person_pin_circle_rounded;
        label = 'Arrived';
        break;
      case 'in_progress':
        bg = const Color(0xFFEDE9FE);
        fg = const Color(0xFF7C3AED);
        border = const Color(0xFFDDD6FE);
        icon = Icons.hourglass_top_rounded;
        label = 'In Progress';
        break;
      case 'completed':
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF166534);
        border = const Color(0xFFBBF7D0);
        icon = Icons.task_alt_rounded;
        label = 'Completed';
        break;
      case 'cancelled':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFDC2626);
        border = const Color(0xFFFECACA);
        icon = Icons.cancel_outlined;
        label = 'Cancelled';
        break;
      case 'rejected':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFB91C1C);
        border = const Color(0xFFFECACA);
        icon = Icons.close_rounded;
        label = 'Declined';
        break;
      case 'pending':
      default:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFB45309);
        border = const Color(0xFFFDE68A);
        icon = Icons.access_time_rounded;
        label = 'Pending';
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 10,
        vertical: isCompact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isCompact ? 12 : 14, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: isCompact ? 11 : 12,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
