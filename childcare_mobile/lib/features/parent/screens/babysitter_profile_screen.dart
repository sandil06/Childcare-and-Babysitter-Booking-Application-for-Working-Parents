import 'package:flutter/material.dart';

import '../../../config/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../babysitter/models/babysitter_model.dart';
import '../../bookings/providers/booking_provider.dart';
import '../providers/parent_provider.dart';

class BabysitterProfileScreen extends StatelessWidget {
  const BabysitterProfileScreen({super.key});

  @override
  Widget build(BuildContext context) => const _BabysitterProfileView();
}

class _BabysitterProfileView extends StatefulWidget {
  const _BabysitterProfileView();

  @override
  State<_BabysitterProfileView> createState() => _BabysitterProfileViewState();
}

class _BabysitterProfileViewState extends State<_BabysitterProfileView> {
  final _provider = ParentProvider.instance;

  @override
  void initState() {
    super.initState();
    _provider.addListener(_refresh);
  }

  @override
  void dispose() {
    _provider.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final sitter = _provider.selectedBabysitter;
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Babysitter profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: sitter == null
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.teal),
            )
          : ListView(
              padding: const EdgeInsets.all(AppSizes.pagePadding),
              children: [
                _buildHeader(sitter),
                const SizedBox(height: 18),
                _section(
                  'About',
                  sitter.bio.isEmpty ? 'No biography provided.' : sitter.bio,
                ),
                const SizedBox(height: 14),
                _buildDetails(sitter),
                if (sitter.skills.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _buildTags('Skills', sitter.skills),
                ],
                if (sitter.languages.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _buildTags('Languages', sitter.languages),
                ],
                if (sitter.qualifications.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _buildTags('Qualifications', sitter.qualifications),
                ],
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      BookingProvider.instance.reset();
                      Navigator.pushNamed(context, AppRoutes.bookingDate);
                    },
                    icon: const Icon(Icons.calendar_month_rounded),
                    label: const Text('Select booking date'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.ink,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader(BabysitterModel sitter) {
    final initials = sitter.name
        .trim()
        .split(' ')
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0])
        .join()
        .toUpperCase();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 42,
            backgroundColor: AppColors.mint,
            child: Text(
              initials.isEmpty ? 'S' : initials,
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w800,
                color: AppColors.teal,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            sitter.name,
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            sitter.isAvailable
                ? 'Available for bookings'
                : 'Currently unavailable',
            style: TextStyle(
              color: sitter.isAvailable ? AppColors.teal : AppColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Rs. ${sitter.hourlyRate.toStringAsFixed(0)} / hour',
            style: const TextStyle(
              color: AppColors.coral,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetails(BabysitterModel sitter) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _metric('Experience', '${sitter.experienceYears} yrs'),
        _metric(
          'Rating',
          sitter.totalReviews > 0
              ? sitter.averageRating.toStringAsFixed(1)
              : 'New',
        ),
        _metric('Reviews', '${sitter.totalReviews}'),
      ],
    ),
  );

  Widget _metric(String label, String value) => Column(
    children: [
      Text(
        value,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: AppColors.ink,
        ),
      ),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
    ],
  );

  Widget _section(String title, String body) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          body,
          style: const TextStyle(color: AppColors.muted, height: 1.45),
        ),
      ],
    ),
  );

  Widget _buildTags(String title, List<String> values) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: values
              .map(
                (value) => Chip(
                  label: Text(value),
                  backgroundColor: AppColors.mint,
                  side: BorderSide.none,
                ),
              )
              .toList(),
        ),
      ],
    ),
  );
}
