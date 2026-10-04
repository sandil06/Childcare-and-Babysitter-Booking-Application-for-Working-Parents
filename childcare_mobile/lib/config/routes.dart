import 'package:flutter/material.dart';

import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/onboarding_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/babysitter/screens/availability_screen.dart';
import '../features/babysitter/screens/booking_history_screen.dart';
import '../features/babysitter/screens/booking_request_details_screen.dart';
import '../features/babysitter/screens/booking_requests_screen.dart';
import '../features/babysitter/screens/earnings_screen.dart';
import '../features/babysitter/screens/edit_sitter_profile_screen.dart';
import '../features/babysitter/screens/messages_screen.dart';
import '../features/babysitter/screens/chat_screen.dart';
import '../features/babysitter/screens/notifications_screen.dart';
import '../features/babysitter/screens/sitter_dashboard_screen.dart';
import '../features/babysitter/screens/sitter_details_screen.dart';
import '../features/babysitter/screens/sitter_profile_screen.dart';
import '../features/babysitter/screens/sitter_registration_screen.dart';
import '../features/babysitter/screens/upcoming_bookings_screen.dart';
import '../features/babysitter/providers/babysitter_provider.dart';
import '../features/parent/screens/parent_home_screen.dart';
import '../features/parent/screens/parent_profile_screen.dart';

class AppRoutes {
  static const splash = '/splash';
  static const home = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';
  static const parentProfile = '/parent/profile';
  static const customerProfile = '/customer/profile';

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
          case splash:
            return const SplashScreen();
          case onboarding:
            return const OnboardingScreen();
          case login:
            return const LoginScreen();
          case register:
            return const RegisterScreen();
          case parentProfile:
          case customerProfile:
            return const ParentProfileScreen();
          case sitterDashboard:
            return const SitterDashboardScreen();
          case sitterRegistration:
            return const SitterRegistrationScreen();
          case sitterProfile:
            return const SitterProfileScreen();
          case sitterDetails:
            return const SitterDetailsScreen();
          case editSitterProfile:
            final p = BabysitterProvider.instance.profile;
            return EditSitterProfileScreen(profile: p!);
          case sitterAvailability:
            return const AvailabilityScreen();
          case sitterBookingRequests:
            return const BookingRequestsScreen();
          case sitterBookingRequestDetails:
            return const BookingRequestDetailsScreen();
          case sitterUpcomingBookings:
            return const UpcomingBookingsScreen();
          case sitterBookingHistory:
            return const BookingHistoryScreen();
          case sitterNotifications:
            return const NotificationsScreen();
          case sitterMessages:
            return const MessagesScreen();
          case sitterChat:
            return const ChatScreen();
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
