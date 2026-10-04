import 'package:flutter/material.dart';

import '../../../config/routes.dart';
import '../../../core/constants/app_colors.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  // Start on step 1 (0-indexed: index 1 is Step 2 in the mockup)
  final PageController _pageController = PageController(initialPage: 1);
  int _currentPage = 1;

  final List<Map<String, dynamic>> _steps = [
    {
      'title': 'Find trusted care in minutes',
      'body':
          'Connect with certified, caring babysitters right in your neighborhood across Sri Lanka.',
      'type': 'step1',
    },
    {
      'title': 'ID-verified sitters, every time',
      'body':
          'Every caregiver on LittleHands undergoes national police background verification, NIC verification, and in-person interviews before their first booking.',
      'type': 'step2',
    },
    {
      'title': 'Track & pay securely in LKR',
      'body':
          'Enjoy real-time session tracking, direct chat, and transparent hourly rates in Sri Lankan Rupees.',
      'type': 'step3',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentPage < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _skipToLogin();
    }
  }

  void _skipToLogin() {
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // LittleHands Brand Label
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(width: 7),
                      const Text(
                        'LITTLEHANDS',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: Color(0xFF005B60),
                        ),
                      ),
                    ],
                  ),

                  // Skip Button
                  GestureDetector(
                    onTap: _skipToLogin,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Page View Carousel
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _steps.length,
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                itemBuilder: (context, index) {
                  return _buildPageSlide(_steps[index]);
                },
              ),
            ),

            // Dots Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_steps.length, (idx) {
                final isActive = idx == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isActive ? 22 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF005B60)
                        : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),

            // Bottom Action Button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _onNext,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF005B60),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _currentPage == _steps.length - 1 ? 'Get Started' : 'Next',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageSlide(Map<String, dynamic> step) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),

          // Graphic Illustration
          if (step['type'] == 'step2')
            _buildVettedIllustration()
          else if (step['type'] == 'step1')
            _buildSearchIllustration()
          else
            _buildPaymentIllustration(),

          const SizedBox(height: 36),

          // Headline
          Text(
            step['title'] as String,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),

          // Body Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              step['body'] as String,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13.5,
                color: Color(0xFF6B7280),
                height: 1.55,
              ),
            ),
          ),

          const Spacer(),
        ],
      ),
    );
  }

  // The 100% Vetted artwork from Screen 2
  Widget _buildVettedIllustration() {
    return SizedBox(
      height: 250,
      width: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Soft radiant background glow
          Container(
            width: 230,
            height: 230,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Color(0xFFD8F3EE),
                  Color(0xFFF0FAF7),
                  Colors.white,
                ],
                stops: [0.0, 0.65, 1.0],
              ),
            ),
          ),

          // Little soft accent sparkles / dots
          Positioned(
            top: 48,
            right: 40,
            child: Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFF59E0B),
              ),
            ),
          ),
          Positioned(
            bottom: 56,
            left: 36,
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF2DD4BF),
              ),
            ),
          ),

          // Central Rounded Card with 100% Vetted
          Container(
            width: 145,
            height: 145,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: const Color(0xFFE2E8F0),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF005B60).withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Deep teal squircle badge with check
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFF005B60),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF005B60).withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.verified_rounded,
                      size: 36,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // 100% VETTED label
                const Text(
                  '100% VETTED',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: Color(0xFF005B60),
                  ),
                ),
              ],
            ),
          ),

          // Floating Chip 1 (Top Left): Police Cleared
          Positioned(
            top: 18,
            left: 10,
            child: _buildFloatingBadge(
              icon: Icons.shield_rounded,
              text: 'Police Cleared',
            ),
          ),

          // Floating Chip 2 (Bottom Right): NIC Verified
          Positioned(
            bottom: 18,
            right: 10,
            child: _buildFloatingBadge(
              icon: Icons.badge_outlined,
              text: 'NIC Verified',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingBadge({
    required IconData icon,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: const Color(0xFF0D9488),
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }

  // Supporting graphic for Slide 1
  Widget _buildSearchIllustration() {
    return SizedBox(
      height: 250,
      width: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 220,
            height: 220,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFE6F5F2),
            ),
          ),
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF005B60).withValues(alpha: 0.08),
                  blurRadius: 20,
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.family_restroom_rounded,
                size: 60,
                color: Color(0xFF005B60),
              ),
            ),
          ),
          Positioned(
            top: 20,
            left: 20,
            child: _buildFloatingBadge(
              icon: Icons.location_on_rounded,
              text: 'Island-wide Care',
            ),
          ),
        ],
      ),
    );
  }

  // Supporting graphic for Slide 3
  Widget _buildPaymentIllustration() {
    return SizedBox(
      height: 250,
      width: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 220,
            height: 220,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFE6F5F2),
            ),
          ),
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF005B60).withValues(alpha: 0.08),
                  blurRadius: 20,
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.account_balance_wallet_rounded,
                size: 58,
                color: Color(0xFF005B60),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: _buildFloatingBadge(
              icon: Icons.lock_outline_rounded,
              text: 'CEFT / Card Secure',
            ),
          ),
        ],
      ),
    );
  }
}
