import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../babysitter/models/babysitter_model.dart';

class SitterCard extends StatelessWidget {
  const SitterCard({super.key, required this.sitter, required this.onTap});
  final BabysitterModel sitter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final initials = sitter.name
        .trim()
        .split(' ')
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0])
        .join()
        .toUpperCase();
    final rating = sitter.totalReviews > 0
        ? '★ ${sitter.averageRating.toStringAsFixed(1)} (${sitter.totalReviews})'
        : 'New caregiver';
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.mint,
                child: Text(
                  initials.isEmpty ? 'S' : initials,
                  style: const TextStyle(
                    color: AppColors.teal,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sitter.name.isEmpty ? 'Babysitter' : sitter.name,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Rs. ${sitter.hourlyRate.toStringAsFixed(0)} / hour',
                      style: const TextStyle(
                        color: AppColors.teal,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${sitter.experienceYears} years experience  •  $rating',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                    if (sitter.skills.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        sitter.skills.take(2).join('  •  '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
