import 'package:flutter/material.dart';

import '../../../config/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/storage/local_storage.dart';

class ParentHomeScreen extends StatelessWidget {
  const ParentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(overscroll: false),
          child: RefreshIndicator(
            displacement: 20,
            edgeOffset: 0,
            color: AppColors.teal,
            onRefresh: () async {
              await Future.delayed(const Duration(milliseconds: 400));
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: ClampingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(
                AppSizes.pagePadding,
                18,
                AppSizes.pagePadding,
                32,
              ),
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, AppRoutes.parentProfile),
                  child: const CircleAvatar(
                    radius: 23,
                    backgroundColor: AppColors.sand,
                    child: Icon(Icons.person_outline, color: AppColors.ink),
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: () => Navigator.pushNamed(context, AppRoutes.sitterDashboard),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.mint,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.teal.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.swap_horiz_rounded, size: 16, color: AppColors.teal),
                        SizedBox(width: 4),
                        Text(
                          'Sitter Mode',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.teal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.sitterNotifications),
                  icon: const Icon(Icons.notifications_none_rounded),
                ),
              ],
            ),
            const SizedBox(height: 28),
            FutureBuilder<dynamic>(
              future: LocalStorage.instance.read('user_name'),
              builder: (context, snapshot) {
                final name = snapshot.data?.toString();
                final greetingName = (name != null && name.trim().isNotEmpty)
                    ? name.trim()
                    : 'Parent';
                return Text(
                  'Good morning, $greetingName',
                  style: const TextStyle(color: AppColors.muted, fontSize: 15),
                );
              },
            ),
            const SizedBox(height: 8),
            const Text(
              AppStrings.welcome,
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 34,
                fontWeight: FontWeight.w700,
                height: 1.05,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              AppStrings.welcomeBody,
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 16,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            _SearchCard(
              onTap: () => Navigator.pushNamed(context, AppRoutes.onboarding),
            ),
            const SizedBox(height: 16),

            // Sitter Portal Quick Access Banner
            InkWell(
              onTap: () => Navigator.pushNamed(context, AppRoutes.sitterDashboard),
              borderRadius: BorderRadius.circular(AppSizes.radius),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.mint.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppSizes.radius),
                  border: Border.all(color: AppColors.teal.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.child_care_rounded, color: AppColors.teal),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Babysitter Portal',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                              fontSize: 15,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Manage bookings, requests, & earnings',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.teal),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 26),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Popular near you',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextButton(onPressed: () {}, child: const Text('See all')),
              ],
            ),
            const SizedBox(height: 10),
            const _SitterCard(
              name: 'Amelia R.',
              detail: 'Early years specialist',
              rating: '4.9',
              color: AppColors.mint,
              initials: 'AR',
            ),
            const SizedBox(height: 12),
            const _SitterCard(
              name: 'Sofia M.',
              detail: 'First aid certified',
              rating: '4.8',
              color: AppColors.sand,
              initials: 'SM',
            ),
          ],
        ),
      ),
    ),
  ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (idx) {
          switch (idx) {
            case 0:
              break;
            case 1:
              Navigator.pushNamed(context, AppRoutes.sitterUpcomingBookings);
              break;
            case 2:
              Navigator.pushNamed(context, AppRoutes.sitterMessages);
              break;
            case 3:
              Navigator.pushNamed(context, AppRoutes.parentProfile);
              break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
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
      ),
    );
  }
}

class _SearchCard extends StatelessWidget {
  const _SearchCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.teal,
      borderRadius: BorderRadius.circular(AppSizes.radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radius),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Need a sitter?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Tell us when and where',
                      style: TextStyle(color: Color(0xFFD8F0E5)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(13),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SitterCard extends StatelessWidget {
  const _SitterCard({
    required this.name,
    required this.detail,
    required this.rating,
    required this.color,
    required this.initials,
  });
  final String name;
  final String detail;
  final String rating;
  final Color color;
  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: color,
            child: Text(
              initials,
              style: const TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(detail, style: const TextStyle(color: AppColors.muted)),
                const SizedBox(height: 5),
                Text(
                  '★ $rating  ·  Available today',
                  style: const TextStyle(
                    color: AppColors.coral,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        ],
      ),
    );
  }
}
