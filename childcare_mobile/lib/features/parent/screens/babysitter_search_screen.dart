import 'dart:async';
import 'package:flutter/material.dart';

import '../../../config/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../babysitter/models/babysitter_model.dart';
import '../providers/parent_provider.dart';

class BabysitterSearchScreen extends StatelessWidget {
  const BabysitterSearchScreen({super.key});

  @override
  Widget build(BuildContext context) => const _BabysitterSearchView();
}

class _BabysitterSearchView extends StatefulWidget {
  const _BabysitterSearchView();

  @override
  State<_BabysitterSearchView> createState() => _BabysitterSearchViewState();
}

class _BabysitterSearchViewState extends State<_BabysitterSearchView> {
  final _controller = TextEditingController();
  final _provider = ParentProvider.instance;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _provider.addListener(_refresh);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _provider.removeListener(_refresh);
    _controller.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _onSearchChanged(String query) {
    setState(() {});
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      _provider.searchBabysitters(search: query.trim());
    });
  }

  Future<void> _submit() async {
    _debounceTimer?.cancel();
    final searchText = _controller.text.trim();
    await _provider.searchBabysitters(search: searchText);
  }

  @override
  Widget build(BuildContext context) {
    final sitters = _provider.babysitters;
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Search Babysitters'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.teal,
          onRefresh: _provider.searchBabysitters,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: ClampingScrollPhysics(),
            ),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.pagePadding,
                  8,
                  AppSizes.pagePadding,
                  24,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const Text(
                      'Care that fits your family',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 29,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Find trusted caregivers for the moments that matter.',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _SearchField(
                      controller: _controller,
                      isLoading: _provider.isLoading,
                      onChanged: _onSearchChanged,
                      onSubmitted: (_) => _submit(),
                      onClear: () {
                        _controller.clear();
                        _submit();
                      },
                      onFilter: () =>
                          Navigator.pushNamed(context, AppRoutes.babysitterList),
                    ),
                    const SizedBox(height: 12),
                    const _LocationRow(),
                    const SizedBox(height: 16),
                    _FilterStrip(
                      hasFilters: _provider.hasFilters,
                      onFilters: () async {
                        await Navigator.pushNamed(
                          context,
                          AppRoutes.parentFilters,
                        );
                        await _provider.searchBabysitters();
                      },
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.teal,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${sitters.length} sitter${sitters.length == 1 ? '' : 's'} nearby',
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        if (_provider.hasFilters)
                          TextButton(
                            onPressed: () async {
                              _provider.clearFilters();
                              await _provider.searchBabysitters();
                            },
                            child: const Text('Clear filters'),
                          ),
                      ],
                    ),
                    if (sitters.any((sitter) => sitter.isVerified)) ...[
                      const SizedBox(height: 14),
                      const _TrustBanner(),
                    ],
                    const SizedBox(height: 14),
                  ]),
                ),
              ),
              if (_provider.isLoading)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.pagePadding,
                  ),
                  sliver: SliverList.builder(
                    itemCount: 3,
                    itemBuilder: (_, _) => const _SitterSkeleton(),
                  ),
                )
              else if (_provider.errorMessage != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _ErrorState(
                    message: _provider.errorMessage!,
                    onRetry: _submit,
                  ),
                )
              else if (sitters.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyState(),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.pagePadding,
                  ),
                  sliver: SliverList.builder(
                    itemCount: sitters.length,
                    itemBuilder: (context, index) => _AnimatedResultCard(
                      index: index,
                      sitter: sitters[index],
                      onTap: () async {
                        await _provider.selectBabysitter(sitters[index]);
                        if (context.mounted) {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.babysitterProfile,
                          );
                        }
                      },
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 18)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _ParentNavigationBar(
        onSelected: (index) {
          switch (index) {
            case 1:
              Navigator.pushNamed(context, AppRoutes.parentUpcomingBookings);
              break;
            case 2:
              Navigator.pushNamed(context, AppRoutes.parentMessages);
              break;
            case 3:
              Navigator.pushNamed(context, AppRoutes.parentProfile);
              break;
          }
        },
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.isLoading,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
    required this.onFilter,
  });
  final TextEditingController controller;
  final bool isLoading;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;
  final VoidCallback onFilter;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    elevation: 2,
    shadowColor: AppColors.ink.withValues(alpha: 0.08),
    borderRadius: BorderRadius.circular(17),
    child: AppTextField(
      controller: controller,
      label: 'Search by name or email',
      hint: 'e.g. a trusted caregiver',
      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.teal),
      suffixIcon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.teal,
                ),
              ),
            ),
          if (!isLoading && controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: onClear,
            ),
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: AppColors.teal),
            tooltip: 'Filters',
            onPressed: onFilter,
          ),
        ],
      ),
      onChanged: onChanged,
      onSubmitted: onSubmitted,
    ),
  );
}

class _LocationRow extends StatelessWidget {
  const _LocationRow();
  @override
  Widget build(BuildContext context) => const Row(
    children: [
      Icon(Icons.location_on_outlined, color: AppColors.teal, size: 18),
      SizedBox(width: 6),
      Text(
        'Location not set',
        style: TextStyle(
          color: AppColors.ink,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
      Spacer(),
      Text(
        'Change location unavailable',
        style: TextStyle(color: AppColors.muted, fontSize: 11),
      ),
    ],
  );
}

class _FilterStrip extends StatelessWidget {
  const _FilterStrip({required this.hasFilters, required this.onFilters});
  final bool hasFilters;
  final VoidCallback onFilters;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 38,
    child: ListView(
      scrollDirection: Axis.horizontal,
      children: [
        _FilterChip(
          label: 'Filters',
          icon: Icons.tune_rounded,
          selected: hasFilters,
          onTap: onFilters,
        ),
        const SizedBox(width: 8),
        _FilterChip(
          label: 'Available now',
          icon: Icons.check_circle_outline_rounded,
          selected: false,
          onTap: onFilters,
        ),
        const SizedBox(width: 8),
        _FilterChip(
          label: 'Rating',
          icon: Icons.star_border_rounded,
          selected: false,
          onTap: onFilters,
        ),
        const SizedBox(width: 8),
        _FilterChip(
          label: 'Experience',
          icon: Icons.workspace_premium_outlined,
          selected: false,
          onTap: onFilters,
        ),
      ],
    ),
  );
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(20),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? AppColors.teal : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: selected ? AppColors.teal : AppColors.sand),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: selected ? Colors.white : AppColors.teal),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.ink,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
}

class _TrustBanner extends StatelessWidget {
  const _TrustBanner();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: AppColors.mint,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.teal.withValues(alpha: 0.15)),
    ),
    child: const Row(
      children: [
        Icon(Icons.verified_user_outlined, color: AppColors.teal, size: 20),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'Verified caregiver profiles are marked clearly on each result.',
            style: TextStyle(color: AppColors.ink, fontSize: 12, height: 1.3),
          ),
        ),
      ],
    ),
  );
}

class _AnimatedResultCard extends StatelessWidget {
  const _AnimatedResultCard({
    required this.index,
    required this.sitter,
    required this.onTap,
  });
  final int index;
  final BabysitterModel sitter;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: Duration(milliseconds: 280 + (index * 70)),
    curve: Curves.easeOutCubic,
    builder: (context, value, child) => Opacity(
      opacity: value,
      child: Transform.translate(
        offset: Offset(0, 12 * (1 - value)),
        child: child,
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _ResultCard(sitter: sitter, onTap: onTap),
    ),
  );
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.sitter, required this.onTap});
  final BabysitterModel sitter;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final image = sitter.profileImage;
    final rating = sitter.totalReviews > 0
        ? '★ ${sitter.averageRating.toStringAsFixed(1)}  (${sitter.totalReviews})'
        : 'New profile';
    final initials = sitter.name.trim().isEmpty
        ? 'S'
        : sitter.name
              .trim()
              .split(' ')
              .take(2)
              .map((part) => part[0])
              .join()
              .toUpperCase();
    return Material(
      color: Colors.white,
      elevation: 1,
      shadowColor: AppColors.ink.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.mint,
                backgroundImage: image == null || image.isEmpty
                    ? null
                    : NetworkImage(image),
                child: image == null || image.isEmpty
                    ? Text(
                        initials,
                        style: const TextStyle(
                          color: AppColors.teal,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            sitter.name.isEmpty ? 'Babysitter' : sitter.name,
                            style: const TextStyle(
                              color: AppColors.ink,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.muted,
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    if (sitter.bio.isNotEmpty)
                      Text(
                        sitter.bio,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 5,
                      children: [
                        Text(
                          rating,
                          style: const TextStyle(
                            color: AppColors.coral,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${sitter.experienceYears} yrs experience',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    if (sitter.skills.isNotEmpty) ...[
                      const SizedBox(height: 9),
                      Wrap(
                        spacing: 6,
                        runSpacing: 5,
                        children: sitter.skills
                            .take(2)
                            .map((skill) => _MiniTag(label: skill))
                            .toList(),
                      ),
                    ],
                    if (sitter.isVerified) ...[
                      const SizedBox(height: 8),
                      const _MiniTag(
                        label: 'Verified caregiver',
                        icon: Icons.verified_rounded,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  const _MiniTag({required this.label, this.icon});
  final String label;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: AppColors.mint,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 12, color: AppColors.teal),
          const SizedBox(width: 4),
        ],
        Text(
          label,
          style: const TextStyle(
            color: AppColors.teal,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _SitterSkeleton extends StatelessWidget {
  const _SitterSkeleton();
  @override
  Widget build(BuildContext context) => Container(
    height: 132,
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      children: [
        const CircleAvatar(radius: 32, backgroundColor: AppColors.sand),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(height: 14, width: 150, color: AppColors.sand),
              const SizedBox(height: 12),
              Container(
                height: 10,
                width: double.infinity,
                color: AppColors.cream,
              ),
              const SizedBox(height: 8),
              Container(height: 10, width: 110, color: AppColors.cream),
            ],
          ),
        ),
      ],
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, color: AppColors.muted, size: 44),
          SizedBox(height: 12),
          Text(
            'No babysitters found',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Try a different search or adjust your filters.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted),
          ),
        ],
      ),
    ),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, color: AppColors.coral, size: 44),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
          ),
        ],
      ),
    ),
  );
}

class _ParentNavigationBar extends StatelessWidget {
  const _ParentNavigationBar({required this.onSelected});
  final ValueChanged<int> onSelected;
  @override
  Widget build(BuildContext context) => NavigationBar(
    selectedIndex: 0,
    onDestinationSelected: onSelected,
    destinations: const [
      NavigationDestination(
        icon: Icon(Icons.search_rounded),
        label: 'Find Sitters',
      ),
      NavigationDestination(
        icon: Icon(Icons.calendar_month_outlined),
        label: 'Bookings',
      ),
      NavigationDestination(
        icon: Icon(Icons.chat_bubble_outline_rounded),
        label: 'Messages',
      ),
      NavigationDestination(
        icon: Icon(Icons.person_outline_rounded),
        label: 'Profile',
      ),
    ],
  );
}
