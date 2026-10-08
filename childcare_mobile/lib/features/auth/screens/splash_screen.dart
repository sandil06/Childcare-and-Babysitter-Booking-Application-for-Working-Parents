import 'dart:async';
import 'package:flutter/material.dart';

import '../../../config/routes.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/local_storage.dart';
import '../../agency/providers/agency_provider.dart';
import '../../babysitter/providers/babysitter_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  bool _hasNavigated = false;
  String _destinationRoute = AppRoutes.onboarding;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _checkSessionAndNavigate();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _checkSessionAndNavigate() async {
    final minDisplayDuration = Future.delayed(const Duration(milliseconds: 1800));

    try {
      final token = await LocalStorage.instance.read('auth_token');
      if (token != null && token.toString().trim().isNotEmpty) {
        ApiClient.authToken = token.toString().trim();
        try {
          final res = await ApiClient().get('auth/me');
          Map<String, dynamic>? data;
          if (res is Map<String, dynamic>) {
            if (res['data'] is Map<String, dynamic>) {
              data = res['data'] as Map<String, dynamic>;
            } else {
              data = res;
            }
          }

          final userObj = data?['user'] is Map<String, dynamic>
              ? data!['user'] as Map<String, dynamic>
              : null;
          final serverRole = userObj?['role']?.toString().toLowerCase();

          if (serverRole == 'agency' || serverRole == 'admin') {
            await AgencyProvider.instance.loadDashboard();
            _destinationRoute = AppRoutes.agencyDashboard;
          } else if (serverRole == 'babysitter') {
            await BabysitterProvider.instance.fetchProfile();
            await BabysitterProvider.instance.fetchDashboard();
            _destinationRoute = AppRoutes.sitterDashboard;
          } else if (serverRole == 'parent') {
            _destinationRoute = AppRoutes.home;
          } else {
            _destinationRoute = AppRoutes.login;
          }
        } catch (_) {
          ApiClient.authToken = null;
          await LocalStorage.instance.remove('auth_token');
          await LocalStorage.instance.remove('user_role');
          _destinationRoute = AppRoutes.login;
        }
      } else {
        _destinationRoute = AppRoutes.onboarding;
      }
    } catch (_) {
      _destinationRoute = AppRoutes.onboarding;
    }

    await minDisplayDuration;

    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;
    Navigator.pushReplacementNamed(context, _destinationRoute);
  }

  void _navigateToNext() {
    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;
    Navigator.pushReplacementNamed(context, _destinationRoute);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _navigateToNext,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF004D40),
                Color(0xFF005B60),
                Color(0xFF004648),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 3),

                // LittleHands Logo Mark Squircle
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.22),
                        blurRadius: 28,
                        offset: const Offset(0, 12),
                      ),
                      BoxShadow(
                        color: const Color(0xFF005B60).withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: const [
                            Text(
                              'L',
                              style: TextStyle(
                                fontFamily: 'serif',
                                fontSize: 42,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF004D40),
                                letterSpacing: -2,
                                height: 1.0,
                              ),
                            ),
                            Text(
                              'h',
                              style: TextStyle(
                                fontFamily: 'serif',
                                fontSize: 40,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF004D40),
                                letterSpacing: -1,
                                height: 1.0,
                              ),
                            ),
                          ],
                        ),
                        // Small teal heart accent over the 'h'
                        Positioned(
                          right: -4,
                          top: 4,
                          child: const Icon(
                            Icons.favorite,
                            size: 15,
                            color: Color(0xFF26A69A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Brand Name
                const Text(
                  'LittleHands',
                  style: TextStyle(
                    fontFamily: 'serif',
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle / Tagline
                const Text(
                  'Trusted childcare, booked in minutes',
                  style: TextStyle(
                    color: Color(0xFF80CBC4),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 22),

                // Accreditation Pill Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.22),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.shield_outlined,
                        size: 13,
                        color: Color(0xFF80CBC4),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        'SRI LANKA ACCREDITED CARE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                          color: Colors.white.withValues(alpha: 0.95),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 4),

                // Bottom Loading Dots (. . .)
                AnimatedBuilder(
                  animation: _animController,
                  builder: (context, _) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (index) {
                        final value = (_animController.value - (index * 0.2))
                            .clamp(0.0, 1.0);
                        final opacity = 0.35 + (value * 0.65);
                        final scale = 0.8 + (value * 0.3);
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Transform.scale(
                            scale: scale,
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF80CBC4).withValues(
                                  alpha: opacity,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    );
                  },
                ),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
