import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class VerificationBadge extends StatelessWidget {
  const VerificationBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  final String status; // 'verified', 'under_review', 'pending', 'rejected'
  final bool compact;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    IconData icon;
    String label;

    switch (status.toLowerCase()) {
      case 'verified':
        bg = AppColors.mint;
        fg = AppColors.teal;
        icon = Icons.verified_rounded;
        label = 'Verified Sitter';
        break;
      case 'under_review':
        bg = AppColors.sand;
        fg = const Color(0xFFB57012);
        icon = Icons.hourglass_top_rounded;
        label = 'Under Review';
        break;
      case 'rejected':
        bg = const Color(0xFFFDE8E8);
        fg = AppColors.coral;
        icon = Icons.error_outline_rounded;
        label = 'Needs Resubmission';
        break;
      case 'pending':
      default:
        bg = const Color(0xFFE8EEF5);
        fg = const Color(0xFF336699);
        icon = Icons.access_time_rounded;
        label = 'Pending Review';
        break;
    }

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
