import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../providers/parent_provider.dart';

class FilterScreen extends StatelessWidget {
  const FilterScreen({super.key});

  @override
  Widget build(BuildContext context) => const _FilterView();
}

class _FilterView extends StatefulWidget {
  const _FilterView();

  @override
  State<_FilterView> createState() => _FilterViewState();
}

class _FilterViewState extends State<_FilterView>
    with SingleTickerProviderStateMixin {
  final _provider = ParentProvider.instance;

  late RangeValues _rate;

  double _experience = 0;
  double _rating = 0;
  bool _availableOnly = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  static const _surfaceColor = Color(0xFFFFFFFF);
  static const _softBackground = Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();

    _rate = const RangeValues(0, 5000);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  int get _activeFilterCount {
    int count = 0;

    if (_rate.start > 0 || _rate.end < 5000) count++;
    if (_experience > 0) count++;
    if (_rating > 0) count++;
    if (_availableOnly) count++;

    return count;
  }

  void _apply() {
    _provider.setFilters(
      minHourlyRate: _rate.start == 0 ? null : _rate.start,
      maxHourlyRate: _rate.end == 5000 ? null : _rate.end,
      minExperience: _experience == 0 ? null : _experience.round(),
      minRating: _rating == 0 ? null : _rating,
      isAvailable: _availableOnly ? true : null,
    );

    Navigator.pop(context);
  }

  void _clear() {
    _provider.clearFilters();

    setState(() {
      _rate = const RangeValues(0, 5000);
      _experience = 0;
      _rating = 0;
      _availableOnly = false;
    });
  }

  String _formatRate(double value) {
    return 'Rs. ${value.round()}';
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: _softBackground,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: _softBackground,
        surfaceTintColor: Colors.transparent,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'Back',
          ),
        ),
        titleSpacing: 8,
        title: const Text(
          'Refine your search',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        actions: [
          if (_activeFilterCount > 0)
            TextButton(
              onPressed: _clear,
              child: const Text(
                'Clear all',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.teal,
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 150),
          children: [
            _buildIntro(),
            const SizedBox(height: 20),

            _buildSectionLabel(
              'Hourly rate',
              'Set the price range that works for you',
            ),
            const SizedBox(height: 10),
            _buildRateCard(),

            const SizedBox(height: 24),

            _buildSectionLabel(
              'Experience',
              'Choose the minimum experience you prefer',
            ),
            const SizedBox(height: 10),
            _buildExperienceCard(),

            const SizedBox(height: 24),

            _buildSectionLabel(
              'Rating',
              'Only show sitters with your preferred rating',
            ),
            const SizedBox(height: 10),
            _buildRatingCard(),

            const SizedBox(height: 24),

            _buildSectionLabel(
              'Availability',
              'Find caregivers who are currently available',
            ),
            const SizedBox(height: 10),
            _buildAvailabilityCard(),

            if (_activeFilterCount > 0) ...[
              const SizedBox(height: 24),
              _buildActiveFilters(),
            ],
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomAction(bottomPadding),
    );
  }

  Widget _buildIntro() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.teal.withValues(alpha: 0.14),
            AppColors.teal.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.teal.withValues(alpha: 0.14),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.teal.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.tune_rounded,
              color: AppColors.teal,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Find the right fit',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Fine-tune your preferences to find babysitters that match your needs.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12.5,
            color: AppColors.muted,
          ),
        ),
      ],
    );
  }

  Widget _buildRateCard() {
    return _CardContainer(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ValuePill(
                label: 'Minimum',
                value: _formatRate(_rate.start),
              ),
              const Icon(
                Icons.remove_rounded,
                size: 18,
                color: AppColors.muted,
              ),
              _ValuePill(
                label: 'Maximum',
                value: _rate.end >= 5000
                    ? 'No limit'
                    : _formatRate(_rate.end),
              ),
            ],
          ),
          const SizedBox(height: 10),
          RangeSlider(
            values: _rate,
            min: 0,
            max: 5000,
            divisions: 20,
            activeColor: AppColors.teal,
            inactiveColor: AppColors.teal.withValues(alpha: 0.12),
            labels: RangeLabels(
              _formatRate(_rate.start),
              _formatRate(_rate.end),
            ),
            onChanged: (RangeValues value) {
              setState(() {
                _rate = value;
              });
            },
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Rs. 0',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.muted,
                  ),
                ),
                Text(
                  'Rs. 5,000+',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExperienceCard() {
    const options = <int>[0, 1, 3, 5, 7, 10];

    return _CardContainer(
      child: Wrap(
        spacing: 8,
        runSpacing: 10,
        children: options.map((int years) {
          final selected = _experience.round() == years;

          return _SelectionChip(
            label: years == 0 ? 'Any' : '$years+ years',
            selected: selected,
            onTap: () {
              setState(() {
                _experience = years.toDouble();
              });
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRatingCard() {
    const options = <double>[0, 3, 3.5, 4, 4.5, 5];

    return _CardContainer(
      child: Wrap(
        spacing: 8,
        runSpacing: 10,
        children: options.map((double rating) {
          final selected = _rating == rating;

          return _SelectionChip(
            label: rating == 0
                ? 'Any rating'
                : '${rating.toStringAsFixed(1)}+',
            icon: rating == 0 ? null : Icons.star_rounded,
            selected: selected,
            onTap: () {
              setState(() {
                _rating = rating;
              });
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAvailabilityCard() {
    return _CardContainer(
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: _availableOnly
                  ? Colors.green.withValues(alpha: 0.12)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.schedule_rounded,
              color: _availableOnly
                  ? Colors.green.shade700
                  : AppColors.muted,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Available caregivers only',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Hide sitters who are currently unavailable',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _availableOnly,
            activeTrackColor: AppColors.teal,
            onChanged: (bool value) {
              setState(() {
                _availableOnly = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilters() {
    return _CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.filter_alt_rounded,
                size: 18,
                color: AppColors.teal,
              ),
              const SizedBox(width: 8),
              const Text(
                'Active filters',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const Spacer(),
              Text(
                '$_activeFilterCount selected',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.teal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (_rate.start > 0 || _rate.end < 5000)
                _ActiveChip(
                  label:
                      '${_formatRate(_rate.start)} - '
                      '${_rate.end >= 5000 ? 'No limit' : _formatRate(_rate.end)}',
                ),
              if (_experience > 0)
                _ActiveChip(
                  label: '${_experience.round()}+ years',
                ),
              if (_rating > 0)
                _ActiveChip(
                  label: '${_rating.toStringAsFixed(1)}+ rating',
                ),
              if (_availableOnly)
                const _ActiveChip(
                  label: 'Available now',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction(double bottomPadding) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        bottomPadding > 0 ? bottomPadding + 8 : 16,
      ),
      decoration: BoxDecoration(
        color: _surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (_activeFilterCount > 0) ...[
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Text(
                  '$_activeFilterCount',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.teal,
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: SizedBox(
                height: 54,
                child: FilledButton.icon(
                  onPressed: _apply,
                  icon: const Icon(Icons.check_rounded),
                  label: Text(
                    _activeFilterCount == 0
                        ? 'Apply filters'
                        : 'Apply $_activeFilterCount filters',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(17),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardContainer extends StatelessWidget {
  const _CardContainer({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ValuePill extends StatelessWidget {
  const _ValuePill({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectionChip extends StatelessWidget {
  const _SelectionChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(
            horizontal: 13,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.teal.withValues(alpha: 0.11)
                : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: selected
                  ? AppColors.teal
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: selected
                      ? AppColors.teal
                      : const Color(0xFFF59E0B),
                ),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: selected ? AppColors.teal : AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveChip extends StatelessWidget {
  const _ActiveChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.teal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: AppColors.teal.withValues(alpha: 0.18),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: AppColors.teal,
        ),
      ),
    );
  }
}