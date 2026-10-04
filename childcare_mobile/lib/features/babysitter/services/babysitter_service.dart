import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/local_storage.dart';
import '../models/availability_model.dart';
import '../models/babysitter_model.dart';
import '../models/booking_request_model.dart';
import '../models/earning_model.dart';

class BabysitterService {
  BabysitterService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  static BabysitterModel? _currentProfile;

  static void clearCurrentProfile() {
    _currentProfile = null;
  }

  BabysitterModel? get currentProfile => _currentProfile;

  Future<BabysitterModel?> getProfile() async {
    try {
      final res = await _client.get('babysitters/me');
      if (res is Map<String, dynamic>) {
        _currentProfile = BabysitterModel.fromJson(res);
        return _currentProfile;
      }
    } catch (e) {
      debugPrint('getProfile API error: $e');
    }
    if (_currentProfile == null) {
      final savedName = await LocalStorage.instance.read('user_name');
      final savedEmail = await LocalStorage.instance.read('user_email');
      final savedId = await LocalStorage.instance.read('user_id');
      if (savedName != null && savedName.toString().isNotEmpty) {
        _currentProfile = BabysitterModel(
          id: savedId?.toString() ?? 'me',
          userId: savedId?.toString() ?? 'me',
          name: savedName.toString(),
          email: savedEmail?.toString() ?? '',
          averageRating: 0.0,
          totalReviews: 0,
          totalCompletedBookings: 0,
        );
      }
    }
    return _currentProfile;
  }

  Future<BabysitterModel?> updateProfile(Map<String, dynamic> data) async {
    try {
      final res = await _client.patch('babysitters/me', body: data);
      if (res is Map<String, dynamic>) {
        _currentProfile = BabysitterModel.fromJson(res);
        return _currentProfile;
      }
    } catch (e) {
      debugPrint('updateProfile API error: $e');
    }
    return _currentProfile;
  }

  Future<BabysitterModel> register(Map<String, dynamic> data) async {
    final res = await _client.post('babysitters/register', body: data);
    if (res is Map<String, dynamic>) {
      if (res['token'] != null) {
        final token = res['token'].toString();
        ApiClient.authToken = token;
        await LocalStorage.instance.write('auth_token', token);
      }
      final profileData = res['profile'] is Map<String, dynamic>
          ? res['profile'] as Map<String, dynamic>
          : res;
      _currentProfile = BabysitterModel.fromJson(profileData);
      if (_currentProfile != null) {
        await LocalStorage.instance.write('user_name', _currentProfile!.name);
        await LocalStorage.instance.write('user_email', _currentProfile!.email);
        if (_currentProfile!.phone.isNotEmpty) {
          await LocalStorage.instance.write('user_phone', _currentProfile!.phone);
        }
        await LocalStorage.instance.write('user_id', _currentProfile!.userId);
        await LocalStorage.instance.write('user_role', 'babysitter');
      }
      return _currentProfile!;
    }
    throw Exception('Registration response invalid');
  }

  Future<bool> toggleAvailability(bool isAvailable) async {
    try {
      await _client.patch('babysitters/me', body: {'isAvailable': isAvailable});
    } catch (e) {
      debugPrint('toggleAvailability API error: $e');
    }
    if (_currentProfile != null) {
      _currentProfile = _currentProfile!.copyWith(isAvailable: isAvailable);
    }
    return isAvailable;
  }

  Future<Map<String, dynamic>> getDashboardData() async {
    try {
      final res = await _client.get('babysitters/me/dashboard');
      if (res is Map<String, dynamic>) {
        return res;
      }
    } catch (e) {
      debugPrint('getDashboardData API error: $e');
    }

    BabysitterModel? profile = _currentProfile;
    if (profile == null) {
      final savedName = await LocalStorage.instance.read('user_name');
      final savedEmail = await LocalStorage.instance.read('user_email');
      final savedId = await LocalStorage.instance.read('user_id');
      if (savedName != null && savedName.toString().isNotEmpty) {
        profile = BabysitterModel(
          id: savedId?.toString() ?? 'me',
          userId: savedId?.toString() ?? 'me',
          name: savedName.toString(),
          email: savedEmail?.toString() ?? '',
          averageRating: 0.0,
          totalReviews: 0,
          totalCompletedBookings: 0,
        );
      }
    }

    return {
      'profile': profile?.toJson(),
      'isAvailable': profile?.isAvailable ?? true,
      'stats': {
        'totalEarnings': 0.0,
        'rating': profile?.averageRating ?? 0.0,
        'completedBookings': profile?.totalCompletedBookings ?? 0,
      },
      'upcomingBooking': null,
      'newRequests': [],
      'unreadNotificationsCount': 0,
    };
  }

  Future<List<AvailabilityModel>> getAvailabilities({DateTime? month}) async {
    try {
      final res = await _client.get('babysitters/me/availability');
      if (res is List) {
        return res
            .whereType<Map<String, dynamic>>()
            .map(AvailabilityModel.fromJson)
            .toList();
      }
    } catch (e) {
      debugPrint('getAvailabilities API error: $e');
    }
    return [];
  }

  Future<AvailabilityModel> addAvailability(AvailabilityModel slot) async {
    final res = await _client.post('babysitters/me/availability', body: slot.toJson());
    if (res is Map<String, dynamic>) {
      return AvailabilityModel.fromJson(res);
    }
    throw Exception('Failed to add availability slot to database');
  }

  Future<AvailabilityModel> updateAvailability(String id, AvailabilityModel slot) async {
    final res = await _client.patch('availability/$id', body: slot.toJson());
    if (res is Map<String, dynamic>) {
      return AvailabilityModel.fromJson(res);
    }
    throw Exception('Failed to update availability slot in database');
  }

  Future<bool> deleteAvailability(String id) async {
    await _client.delete('availability/$id');
    return true;
  }

  Future<List<BookingRequestModel>> getBookings({String? status}) async {
    try {
      final res = await _client.get(
        'babysitters/me/bookings',
        queryParams: (status != null && status != 'all') ? {'status': status} : null,
      );
      if (res is List) {
        return res
            .whereType<Map<String, dynamic>>()
            .map(BookingRequestModel.fromJson)
            .toList();
      }
    } catch (e) {
      debugPrint('getBookings API error: $e');
    }
    return [];
  }

  Future<BookingRequestModel> getBookingDetails(String id) async {
    final res = await _client.get('bookings/$id');
    if (res is Map<String, dynamic>) {
      return BookingRequestModel.fromJson(res);
    }
    throw Exception('Booking not found');
  }

  Future<BookingRequestModel> acceptBooking(String id) async {
    final res = await _client.patch('bookings/$id/accept');
    if (res is Map<String, dynamic>) {
      return BookingRequestModel.fromJson(res);
    }
    throw Exception('Failed to accept booking');
  }

  Future<BookingRequestModel> rejectBooking(String id, {String? reason}) async {
    final res = await _client.patch('bookings/$id/reject', body: {'reason': reason});
    if (res is Map<String, dynamic>) {
      return BookingRequestModel.fromJson(res);
    }
    throw Exception('Failed to decline booking');
  }

  Future<BookingRequestModel> updateJobStatus(String id, String newStatus) async {
    final res = await _client.patch('bookings/$id/status', body: {'status': newStatus});
    if (res is Map<String, dynamic>) {
      return BookingRequestModel.fromJson(res);
    }
    throw Exception('Failed to update job status');
  }

  Future<EarningSummaryModel> getEarnings({String range = 'weekly'}) async {
    try {
      final res = await _client.get('babysitters/me/earnings', queryParams: {'range': range});
      if (res is Map<String, dynamic>) {
        return EarningSummaryModel.fromJson(res);
      }
    } catch (e) {
      debugPrint('getEarnings API error: $e');
    }
    return const EarningSummaryModel(
      totalEarnings: 0.0,
      currentMonthEarnings: 0.0,
      weeklyEarnings: 0.0,
      completedBookings: 0,
      recentEarnings: [],
    );
  }

  Future<Map<String, dynamic>> requestPayout() async {
    try {
      final res = await _client.post('babysitters/me/earnings/payout');
      if (res is Map<String, dynamic>) {
        return res;
      }
    } catch (e) {
      debugPrint('requestPayout API error: $e');
    }
    return {
      'payoutId': 'po-${DateTime.now().millisecondsSinceEpoch}',
      'status': 'processing',
    };
  }

  Future<List<Map<String, dynamic>>> getNotifications() async {
    try {
      final res = await _client.get('notifications');
      if (res is List) {
        return res.whereType<Map<String, dynamic>>().toList();
      }
    } catch (e) {
      debugPrint('getNotifications API error: $e');
    }
    return [];
  }

  Future<bool> markNotificationRead(String id) async {
    try {
      await _client.patch('notifications/$id/read');
    } catch (e) {
      debugPrint('markNotificationRead error: $e');
    }
    return true;
  }

  Future<bool> markAllNotificationsRead() async {
    try {
      await _client.patch('notifications/read-all');
    } catch (e) {
      debugPrint('markAllNotificationsRead error: $e');
    }
    return true;
  }

  Future<List<Map<String, dynamic>>> getConversations() async {
    try {
      final res = await _client.get('messages/conversations');
      if (res is List) {
        return res.whereType<Map<String, dynamic>>().toList();
      }
    } catch (e) {
      debugPrint('getConversations error: $e');
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> getMessages(String conversationId) async {
    try {
      final res = await _client.get('messages/$conversationId');
      if (res is List) {
        return res.whereType<Map<String, dynamic>>().toList();
      }
    } catch (e) {
      debugPrint('getMessages error: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>?> sendMessage({
    required String text,
    String? conversationId,
    String? recipientId,
  }) async {
    try {
      final payload = <String, dynamic>{'text': text};
      if (conversationId != null) payload['conversationId'] = conversationId;
      if (recipientId != null) payload['recipientId'] = recipientId;
      final res = await _client.post('messages', body: payload);
      if (res is Map<String, dynamic>) return res;
    } catch (e) {
      debugPrint('sendMessage error: $e');
    }
    return null;
  }
}
