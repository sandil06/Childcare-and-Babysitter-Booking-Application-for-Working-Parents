import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/services/socket_service.dart';
import '../../../core/storage/local_storage.dart';

class TrackingService {
  static final TrackingService _instance = TrackingService._internal();
  factory TrackingService() => _instance;
  TrackingService._internal();

  final ApiClient _client = ApiClient();
  final SocketService _socket = SocketService();
  String? _joinedBookingId;

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

  // ==========================================
  // REAL-TIME SOCKET.IO TRACKING
  // ==========================================

  /// Connects and joins live tracking room for a booking
  void startTrackingSubscription({
    required String bookingId,
    required void Function(Map<String, dynamic>) onLocationUpdate,
    void Function(String)? onStatusUpdate,
  }) {
    _joinedBookingId = bookingId;

    _socket.connect().then((_) {
      _socket.emit('tracking:join', bookingId);

      _socket.on('sitter_location_update', (data) {
        if (data is Map && data['bookingId'] == bookingId) {
          onLocationUpdate(Map<String, dynamic>.from(data));
        }
      });

      _socket.on('tracking:update', (data) {
        if (data is Map && data['bookingId'] == bookingId) {
          onLocationUpdate(Map<String, dynamic>.from(data));
        }
      });

      _socket.on('sitter_status_update', (data) {
        if (data is Map && data['bookingId'] == bookingId) {
          final s = data['status']?.toString();
          if (s != null) onStatusUpdate?.call(s);
        }
      });
    });
  }

  /// Broadcasts caregiver GPS position to parent via Socket.IO
  void broadcastLocation({
    required String bookingId,
    required double latitude,
    required double longitude,
    double heading = 0.0,
    double speed = 0.0,
    String status = 'travelling',
    int etaMinutes = 10,
  }) {
    _socket.emit('tracking:update', {
      'bookingId': bookingId,
      'latitude': latitude,
      'longitude': longitude,
      'heading': heading,
      'speed': speed,
      'status': status,
      'etaMinutes': etaMinutes,
    });
  }

  /// Broadcasts sitter status change (travelling -> arrived -> in_progress -> completed)
  void broadcastStatusChange({
    required String bookingId,
    required String status,
  }) {
    _socket.emit('tracking:status_change', {
      'bookingId': bookingId,
      'status': status,
    });
  }

  /// Cleans up tracking subscriptions
  void stopTrackingSubscription() {
    if (_joinedBookingId != null) {
      _socket.emit('tracking:leave', _joinedBookingId);
      _socket.off('sitter_location_update');
      _socket.off('tracking:update');
      _socket.off('sitter_status_update');
      _joinedBookingId = null;
    }
  }
}
