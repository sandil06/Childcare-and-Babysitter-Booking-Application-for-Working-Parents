import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../models/babysitter_model.dart';
import '../widgets/verification_badge.dart';

class SitterDetailsScreen extends StatelessWidget {
  const SitterDetailsScreen({super.key, this.profile});

  final BabysitterModel? profile;

  @override
  Widget build(BuildContext context) {
    final sitter = profile ??
        const BabysitterModel(
          id: 'sitter-1',
          userId: 'u-1',
          name: 'Kavindi Perera',
          email: 'kavindi.perera@example.com',
          phone: '+94 77 019 2834',
          address: 'Colombo, Sri Lanka',
          bio:
              'Certified early childhood educator with over 4 years of experience specializing in infant care and toddler development across Colombo. Passionate about fun, creative learning and child safety.',
          hourlyRate: 1500.0,
          experienceYears: 4,
          skills: [
            'Infant Care',
            'Toddler Care',
            'First Aid & CPR',
            'Meal Preparation',
            'Bedtime Routines',
          ],
          languages: ['Sinhala', 'English', 'Tamil'],
          qualifications: [
            'CPR & Pediatric First Aid Certified (SL Red Cross)',
            'Early Childhood Education Diploma',
          ],
          verificationStatus: 'verified',
          averageRating: 4.95,
          totalReviews: 32,
          totalCompletedBookings: 48,
          isAvailable: true,
        );

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
          'Babysitter Details',
          style: TextStyle(
            color: AppColors.ink,
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.pagePadding),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: AppColors.mint,
                  child: Text(
                    sitter.name.isNotEmpty
                        ? sitter.name
                            .split(' ')
                            .map((e) => e.isNotEmpty ? e[0] : '')
                            .take(2)
                            .join()
                        : 'MJ',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.teal,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  sitter.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${sitter.experienceYears} Years Childcare Experience',
                  style: const TextStyle(color: AppColors.muted, fontSize: 14),
                ),
                const SizedBox(height: 8),
                VerificationBadge(status: sitter.verificationStatus),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Rate & Rating Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetric('Rate', 'Rs. ${sitter.hourlyRate.toInt()}/hr', AppColors.teal),
                Container(height: 32, width: 1, color: AppColors.sand),
                _buildMetric('Rating', '★ ${sitter.averageRating}', AppColors.coral),
                Container(height: 32, width: 1, color: AppColors.sand),
                _buildMetric('Bookings', '${sitter.totalCompletedBookings}', AppColors.ink),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // About Section
          _buildCard(
            title: 'About Me',
            child: Text(
              sitter.bio,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.ink,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Skills Section
          _buildCard(
            title: 'Skills & Care Capabilities',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: sitter.skills.map((s) {
                return Chip(
                  backgroundColor: AppColors.mint,
                  label: Text(
                    s,
                    style: const TextStyle(
                      color: AppColors.teal,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Certifications
          _buildCard(
            title: 'Verified Qualifications',
            child: Column(
              children: sitter.qualifications.map((q) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          color: AppColors.teal, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          q,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(fontSize: 12, color: AppColors.muted)),
      ],
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
