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
import '../features/parent/screens/babysitter_search_screen.dart';
import '../features/parent/screens/babysitter_list_screen.dart';
import '../features/parent/screens/babysitter_profile_screen.dart';
import '../features/parent/screens/filter_screen.dart';
import '../features/parent/screens/booking_date_screen.dart';
import '../features/parent/screens/booking_time_screen.dart';
import '../features/parent/screens/booking_summary_screen.dart';
import '../features/parent/screens/price_screen.dart';
import '../features/parent/screens/booking_confirmation_screen.dart';
import '../features/bookings/screens/booking_details_screen.dart';
import '../features/bookings/screens/booking_history_screen.dart'
    as parent_bookings;
import '../features/bookings/screens/cancel_booking_screen.dart';
import '../features/bookings/screens/reschedule_booking_screen.dart';
import '../features/bookings/screens/upcoming_bookings_screen.dart'
    as parent_bookings;
import '../features/chat/screens/chat_screen.dart' as parent_chat;
import '../features/chat/screens/inbox_screen.dart';
import '../features/notifications/screens/notifications_screen.dart'
    as parent_notifications;
import '../features/payments/screens/payment_method_screen.dart';
import '../features/payments/screens/payment_receipt_screen.dart';
import '../features/tracking/screens/live_tracking_screen.dart';
import '../features/agency/screens/agency_dashboard_screen.dart';
import '../features/agency/screens/agency_login_screen.dart';
import '../features/agency/screens/reports_screen.dart';
import '../features/agency/screens/sitter_verification_screen.dart';
import '../features/agency/screens/verification_requests_screen.dart';
import '../features/agency/screens/user_management_screen.dart';
import '../features/agency/screens/parent_management_screen.dart';
import '../features/agency/screens/babysitter_management_screen.dart';
import '../features/agency/screens/booking_monitoring_screen.dart';
import '../features/agency/models/verification_request_model.dart';

class AppRoutes {
  static const splash = '/splash';
  static const home = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';
  static const parentProfile = '/parent/profile';
  static const customerProfile = '/customer/profile';
  static const babysitterSearch = '/parent/babysitters/search';
  static const babysitterList = '/parent/babysitters';
  static const parentFilters = '/parent/babysitters/filters';
  static const babysitterProfile = '/parent/babysitters/profile';
  static const bookingDate = '/parent/booking/date';
  static const bookingStartTime = '/parent/booking/start-time';
  static const bookingEndTime = '/parent/booking/end-time';
  static const bookingSummary = '/parent/booking/summary';
  static const bookingPrice = '/parent/booking/price';
  static const bookingConfirmation = '/parent/booking/confirmation';
  static const parentUpcomingBookings = '/parent/bookings/upcoming';
  static const parentBookingHistory = '/parent/bookings/history';
  static const parentBookingDetails = '/parent/bookings/details';
  static const parentRescheduleBooking = '/parent/bookings/reschedule';
  static const parentCancelBooking = '/parent/bookings/cancel';
  static const parentPaymentMethod = '/parent/payments/method';
  static const parentPaymentReceipt = '/parent/payments/receipt';
  static const parentMessages = '/parent/messages';
  static const parentChat = '/parent/chat';
  static const parentNotifications = '/parent/notifications';
  static const liveTracking = '/tracking/live';
  static const agencyLogin = '/agency/login';
  static const agencyDashboard = '/agency/dashboard';
  static const agencyReports = '/agency/reports';
  static const agencyVerificationRequests = '/agency/verification-requests';
  static const agencySitterVerification = '/agency/sitter-verification';
  static const agencyUserManagement = '/agency/users';
  static const agencyParentManagement = '/agency/parents';
  static const agencyBabysitterManagement = '/agency/babysitters';
  static const agencyBookings = '/agency/bookings';

  // Babysitter module routes
  static const sitterDashboard = '/babysitter/dashboard';
  static const sitterRegistration = '/babysitter/register';
  static const sitterProfile = '/babysitter/profile';
  static const sitterDetails = '/babysitter/details';
  static const editSitterProfile = '/babysitter/profile/edit';
  static const sitterAvailability = '/babysitter/availability';
  static const sitterBookingRequests = '/babysitter/booking-requests';
  static const sitterBookingRequestDetails =
      '/babysitter/booking-requests/details';
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
          case babysitterSearch:
            return const BabysitterSearchScreen();
          case babysitterList:
            return const BabysitterListScreen();
          case parentFilters:
            return const FilterScreen();
          case babysitterProfile:
            return const BabysitterProfileScreen();
          case bookingDate:
            return const BookingDateScreen();
          case bookingStartTime:
            return const BookingTimeScreen(mode: BookingTimeMode.start);
          case bookingEndTime:
            return const BookingTimeScreen(mode: BookingTimeMode.end);
          case bookingSummary:
            return const BookingSummaryScreen();
          case bookingPrice:
            return const PriceScreen();
          case bookingConfirmation:
            return const BookingConfirmationScreen();
          case parentUpcomingBookings:
            return const parent_bookings.UpcomingBookingsScreen();
          case parentBookingHistory:
            return const parent_bookings.BookingHistoryScreen();
          case parentBookingDetails:
            return const BookingDetailsScreen();
          case parentRescheduleBooking:
            return const RescheduleBookingScreen();
          case parentCancelBooking:
            return const CancelBookingScreen();
          case parentPaymentMethod:
            return const PaymentMethodScreen();
          case parentPaymentReceipt:
            return const PaymentReceiptScreen();
          case parentMessages:
            return const InboxScreen();
          case parentChat:
            return const parent_chat.ChatScreen();
          case parentNotifications:
            return const parent_notifications.NotificationsScreen();
          case liveTracking:
            return const LiveTrackingScreen();
          case agencyLogin:
            return const AgencyLoginScreen();
          case agencyDashboard:
            return const AgencyDashboardScreen();
          case agencyReports:
            return const ReportsScreen();
          case agencyVerificationRequests:
            return const VerificationRequestsScreen();
          case agencySitterVerification:
            final args = settings.arguments;
            if (args is VerificationRequestModel) {
              return SitterVerificationScreen(request: args);
            } else if (args is String) {
              return SitterVerificationScreen(verificationId: args);
            }
            return const SitterVerificationScreen();
          case agencyUserManagement:
            return const UserManagementScreen();
          case agencyParentManagement:
            return const ParentManagementScreen();
          case agencyBabysitterManagement:
            return const BabysitterManagementScreen();
          case agencyBookings:
            return const BookingMonitoringScreen();
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
            if (p != null) return EditSitterProfileScreen(profile: p);
            return const SitterProfileScreen();
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
