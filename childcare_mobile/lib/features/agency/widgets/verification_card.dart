import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../models/verification_request_model.dart';
import 'verification_status_chip.dart';

class VerificationCard extends StatelessWidget {
  final VerificationRequestModel request;
  final VoidCallback onTap;

  const VerificationCard({
    super.key,
    required this.request,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.radius),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Avatar, Name, Email, Status Chip
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFFE6F5F2),
                  backgroundImage: request.avatar.isNotEmpty
                      ? NetworkImage(request.avatar)
                      : null,
                  child: request.avatar.isEmpty
                      ? Text(
                          request.name.isNotEmpty
                              ? request.name[0].toUpperCase()
                              : 'B',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.teal,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              request.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          VerificationStatusChip(status: request.status),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        request.email,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.muted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 12),

            // Bottom Metrics: Experience, Hourly Rate, Documents
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _metricItem(
                  icon: Icons.work_outline_rounded,
                  label: '${request.experienceYears} Years Exp.',
                ),
                _metricItem(
                  icon: Icons.payments_outlined,
                  label: 'Rs. ${request.hourlyRate.toInt()}/hr',
                ),
                _metricItem(
                  icon: Icons.attach_file_rounded,
                  label: '${request.documents.length} Documents',
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: AppColors.muted,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricItem({required IconData icon, required String label}) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.teal),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF475569),
          ),
        ),
      ],
    );
  }
}
