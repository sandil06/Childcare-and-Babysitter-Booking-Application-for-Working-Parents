import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
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

class _FilterViewState extends State<_FilterView> {
  final _provider = ParentProvider.instance;
  late RangeValues _rate;
  double _experience = 0;
  double _rating = 0;
  bool _availableOnly = false;

  @override
  void initState() {
    super.initState();
    _rate = const RangeValues(0, 5000);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Filter babysitters'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _provider.clearFilters();
              setState(() {
                _rate = const RangeValues(0, 5000);
                _experience = 0;
                _rating = 0;
                _availableOnly = false;
              });
            },
            child: const Text('Clear'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.pagePadding),
        children: [
          const Text(
            'Hourly rate',
            style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink),
          ),
          RangeSlider(
            values: _rate,
            min: 0,
            max: 5000,
            divisions: 20,
            labels: RangeLabels(
              'Rs. ${_rate.start.round()}',
              'Rs. ${_rate.end.round()}',
            ),
            activeColor: AppColors.teal,
            onChanged: (value) => setState(() => _rate = value),
          ),
          Text(
            'Rs. ${_rate.start.round()} - Rs. ${_rate.end.round()}',
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 24),
          Text(
            'Minimum experience: ${_experience.round()} years',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          Slider(
            value: _experience,
            min: 0,
            max: 10,
            divisions: 10,
            activeColor: AppColors.teal,
            onChanged: (value) => setState(() => _experience = value),
          ),
          const SizedBox(height: 12),
          Text(
            'Minimum rating: ${_rating == 0 ? 'Any' : '${_rating.toStringAsFixed(1)} stars'}',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          Slider(
            value: _rating,
            min: 0,
            max: 5,
            divisions: 10,
            activeColor: AppColors.teal,
            onChanged: (value) => setState(() => _rating = value),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Available caregivers only'),
            value: _availableOnly,
            activeThumbColor: AppColors.teal,
            onChanged: (value) => setState(() => _availableOnly = value),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _apply,
              icon: const Icon(Icons.check_rounded),
              label: const Text('Apply filters'),
            ),
          ),
        ],
      ),
    );
  }
}
