import 'package:flutter/material.dart';

class VerificationStatusChip extends StatelessWidget {
  final String status;

  const VerificationStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color border;
    Color text;
    String label;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'verified':
        bg = const Color(0xFFF0FDF4); // Green 50
        border = const Color(0xFF86EFAC); // Green 300
        text = const Color(0xFF15803D); // Green 700
        label = 'Verified';
        icon = Icons.verified_rounded;
        break;
      case 'under_review':
        bg = const Color(0xFFFFFBEB); // Amber 50
        border = const Color(0xFFFDE68A); // Amber 300
        text = const Color(0xFFB45309); // Amber 700
        label = 'Under Review';
        icon = Icons.sync_rounded;
        break;
      case 'rejected':
        bg = const Color(0xFFFEF2F2); // Red 50
        border = const Color(0xFFFCA5A5); // Red 300
        text = const Color(0xFFB91C1C); // Red 700
        label = 'Rejected';
        icon = Icons.cancel_outlined;
        break;
      case 'changes_requested':
        bg = const Color(0xFFEFF6FF); // Blue 50
        border = const Color(0xFFBFDBFE); // Blue 300
        text = const Color(0xFF1D4ED8); // Blue 700
        label = 'Changes Req.';
        icon = Icons.info_outline_rounded;
        break;
      case 'pending':
      default:
        bg = const Color(0xFFF8FAFC); // Slate 50
        border = const Color(0xFFCBD5E1); // Slate 300
        text = const Color(0xFF475569); // Slate 600
        label = 'Pending Review';
        icon = Icons.hourglass_top_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.5, color: text),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: text,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
