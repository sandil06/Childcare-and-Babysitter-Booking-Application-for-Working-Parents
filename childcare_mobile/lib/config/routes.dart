import 'package:flutter/material.dart';

import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/onboarding_screen.dart';
import '../features/babysitter/screens/availability_screen.dart';
import '../features/babysitter/screens/booking_requests_screen.dart';
import '../features/babysitter/screens/earnings_screen.dart';
import '../features/babysitter/screens/sitter_dashboard_screen.dart';
import '../features/babysitter/screens/sitter_profile_screen.dart';
import '../features/babysitter/screens/sitter_registration_screen.dart';
import '../features/parent/screens/parent_home_screen.dart';

class AppRoutes {
  static const home = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';

  // Babysitter module routes
  static const sitterDashboard = '/babysitter/dashboard';
  static const sitterRegistration = '/babysitter/register';
  static const sitterProfile = '/babysitter/profile';
  static const sitterDetails = '/babysitter/details';
  static const editSitterProfile = '/babysitter/profile/edit';
  static const sitterAvailability = '/babysitter/availability';
  static const sitterBookingRequests = '/babysitter/booking-requests';
  static const sitterBookingRequestDetails = '/babysitter/booking-requests/details';
  static const sitterUpcomingBookings = '/babysitter/upcoming-bookings';
  static const sitterBookingHistory = '/babysitter/booking-history';
  static const sitterEarnings = '/babysitter/earnings';
  static const sitterNotifications = '/babysitter/notifications';
  static const sitterMessages = '/babysitter/messages';
  static const sitterChat = '/babysitter/chat';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    return MaterialPageRoute(
      settings: settings,
      builder: (context) {
        switch (settings.name) {
          case onboarding:
            return const OnboardingScreen();
          case login:
            return const LoginScreen();
          case sitterDashboard:
            return const SitterDashboardScreen();
          case sitterRegistration:
            return const SitterRegistrationScreen();
          case sitterProfile:
          case sitterDetails:
            return const SitterProfileScreen();
          case sitterAvailability:
            return const AvailabilityScreen();
          case sitterBookingRequests:
            return const BookingRequestsScreen();
          case sitterEarnings:
            return const EarningsScreen();
          case home:
          default:
            return const ParentHomeScreen();
        }
      },
    );
  }
}
