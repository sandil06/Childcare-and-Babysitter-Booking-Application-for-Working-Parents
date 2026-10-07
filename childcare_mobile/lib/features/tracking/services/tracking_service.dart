import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/local_storage.dart';

class TrackingService {
  static final TrackingService _instance = TrackingService._internal();
  factory TrackingService() => _instance;
  TrackingService._internal();

  final ApiClient _client = ApiClient();

  Future<void> _ensureAuthToken() async {
    final token = await LocalStorage.instance.read('auth_token');
    if (token != null && token.toString().isNotEmpty) {
      ApiClient.authToken = token.toString();
    }
  }

  /// Sends caregiver GPS position update to backend
  Future<bool> updateLocation({
    required String bookingId,
    required double latitude,
    required double longitude,
    double heading = 0.0,
    double speed = 0.0,
    String status = 'travelling',
  }) async {
    await _ensureAuthToken();

    try {
      final res = await _client.post('tracking/booking/$bookingId/location', body: {
        'latitude': latitude,
        'longitude': longitude,
        'heading': heading,
        'speed': speed,
        'status': status,
      });
      return res != null;
    } catch (e) {
      debugPrint('[TrackingService] updateLocation error: $e');
      return false;
    }
  }

  /// Gets latest caregiver position for booking
  Future<Map<String, dynamic>?> getBookingLocation(String bookingId) async {
    await _ensureAuthToken();

    try {
      final res = await _client.get('tracking/booking/$bookingId/location');
      if (res is Map && res['data'] != null) {
        return Map<String, dynamic>.from(res['data'] as Map);
      }
    } catch (e) {
      debugPrint('[TrackingService] getBookingLocation error: $e');
    }
    return null;
  }
}
