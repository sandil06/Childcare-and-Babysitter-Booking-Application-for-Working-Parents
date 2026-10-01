import 'package:flutter/material.dart';

import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/onboarding_screen.dart';
import '../features/parent/screens/parent_home_screen.dart';

class AppRoutes {
  static const home = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    return MaterialPageRoute(
      settings: settings,
      builder: (_) {
        switch (settings.name) {
          case onboarding:
            return const OnboardingScreen();
          case login:
            return const LoginScreen();
          case home:
          default:
            return const ParentHomeScreen();
        }
      },
    );
  }
}
