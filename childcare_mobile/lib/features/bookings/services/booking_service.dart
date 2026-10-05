import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/local_storage.dart';
import '../models/booking_model.dart';
import '../models/booking_price_model.dart';

class BookingService {
  static final BookingService _instance = BookingService._internal();
  factory BookingService() => _instance;
  BookingService._internal();

  final ApiClient _client = ApiClient();
  final List<BookingModel> _localBookings = [];

  // ==========================================
  // PRICE CALCULATION
  // ==========================================
  Future<BookingPriceModel> calculatePrice({
    required String babysitterId,
    required String date,
    required String startTime,
    required String endTime,
  }) async {
    try {
      final token = await LocalStorage.instance.read('auth_token');
      if (token != null && token.toString().isNotEmpty) {
        ApiClient.authToken = token.toString();
      }

      final res = await _client.post('bookings/calculate-price', body: {
        'babysitterId': babysitterId,
        'date': date,
        'startTime': startTime,
        'endTime': endTime,
      });

      if (res is Map && res['data'] != null) {
        return BookingPriceModel.fromJson(Map<String, dynamic>.from(res['data']));
      } else if (res is Map) {
        return BookingPriceModel.fromJson(Map<String, dynamic>.from(res));
      }
    } catch (e) {
      debugPrint('calculatePrice API error: $e');
    }

    // Client-side fallback calculation if offline or backend is unreachable
    int startM = _parseTimeToMinutes(startTime);
    int endM = _parseTimeToMinutes(endTime);
    double duration = (endM > startM) ? (endM - startM) / 60.0 : 4.0;
    if (duration <= 0) duration = 4.0;
    const hourlyRate = 1500.0;
    final subtotal = duration * hourlyRate;
    return BookingPriceModel(
      duration: duration,
      hourlyRate: hourlyRate,
      subtotal: subtotal,
      serviceFee: 0.0,
      totalAmount: subtotal,
    );
  }

  // ==========================================
  // CREATE BOOKING
  // ==========================================
  Future<BookingModel> createBooking(Map<String, dynamic> bookingData) async {
    try {
      final token = await LocalStorage.instance.read('auth_token');
      if (token != null && token.toString().isNotEmpty) {
        ApiClient.authToken = token.toString();
      }

      final res = await _client.post('bookings', body: bookingData);
      Map<String, dynamic>? dataMap;
      if (res is Map && res['data'] != null) {
        dataMap = Map<String, dynamic>.from(res['data']);
      } else if (res is Map) {
        dataMap = Map<String, dynamic>.from(res);
      }

      if (dataMap != null) {
        final booking = BookingModel.fromJson(dataMap);
        _localBookings.insert(0, booking);
        await _saveLocalBookings();
        return booking;
      }
    } catch (e) {
      debugPrint('createBooking API error: $e');
    }

    // Local fallback
    final id = 'bk-${DateTime.now().millisecondsSinceEpoch}';
    final fallback = BookingModel(
      id: id,
      bookingId: '#BK-${id.substring(id.length - 4)}',
      parentId: bookingData['parent']?.toString() ?? bookingData['parentId']?.toString() ?? 'me',
      babysitterId: bookingData['babysitter']?.toString() ?? bookingData['babysitterId']?.toString() ?? '',
      date: bookingData['date'] != null ? DateTime.tryParse(bookingData['date'].toString()) ?? DateTime.now() : DateTime.now(),
      startTime: bookingData['startTime']?.toString() ?? '09:00',
      endTime: bookingData['endTime']?.toString() ?? '13:00',
      durationHours: double.tryParse(bookingData['durationHours']?.toString() ?? '4.0') ?? 4.0,
      hourlyRate: double.tryParse(bookingData['hourlyRate']?.toString() ?? '1500.0') ?? 1500.0,
      subtotal: double.tryParse(bookingData['subtotal']?.toString() ?? '6000.0') ?? 6000.0,
      serviceFee: 0.0,
      total: double.tryParse(bookingData['total']?.toString() ?? '6000.0') ?? 6000.0,
      totalAmount: double.tryParse(bookingData['totalAmount']?.toString() ?? '6000.0') ?? 6000.0,
      location: bookingData['location']?.toString() ?? bookingData['address']?.toString() ?? 'Colombo, Sri Lanka',
      specialNotes: bookingData['specialNotes']?.toString() ?? bookingData['notes']?.toString() ?? '',
      status: 'pending',
      paymentStatus: 'pending',
    );
    _localBookings.insert(0, fallback);
    await _saveLocalBookings();
    return fallback;
  }

  // ==========================================
  // LIST BOOKINGS
  // ==========================================
  Future<List<BookingModel>> getBookings({String? status, int page = 1, int limit = 10}) async {
    try {
      final token = await LocalStorage.instance.read('auth_token');
      if (token != null && token.toString().isNotEmpty) {
        ApiClient.authToken = token.toString();
      }

      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        if (status != null && status.isNotEmpty && status != 'all') 'status': status,
      };

      final res = await _client.get('bookings', queryParams: queryParams);
      List? list;
      if (res is Map && res['data'] is List) {
        list = res['data'] as List;
      } else if (res is List) {
        list = res;
      }

      if (list != null) {
        final results = list
            .whereType<Map>()
            .map((item) => BookingModel.fromJson(Map<String, dynamic>.from(item)))
            .toList();
        if (page == 1) {
          _localBookings.clear();
          _localBookings.addAll(results);
          await _saveLocalBookings();
        }
        return results;
      }
    } catch (e) {
      debugPrint('getBookings API error: $e');
    }

    // Load from local storage cache
    await _loadLocalBookings();
    if (status != null && status.isNotEmpty && status != 'all') {
      if (status == 'upcoming') {
        return _localBookings
            .where((b) => ['accepted', 'confirmed', 'travelling', 'arrived', 'in_progress', 'pending'].contains(b.status))
            .toList();
      } else if (status == 'completed') {
        return _localBookings.where((b) => b.status == 'completed').toList();
      } else if (status == 'cancelled') {
        return _localBookings.where((b) => ['cancelled', 'rejected'].contains(b.status)).toList();
      }
      return _localBookings.where((b) => b.status == status).toList();
    }
    return _localBookings;
  }

  // ==========================================
  // GET BOOKING BY ID
  // ==========================================
  Future<BookingModel?> getBookingById(String id) async {
    try {
      final token = await LocalStorage.instance.read('auth_token');
      if (token != null && token.toString().isNotEmpty) {
        ApiClient.authToken = token.toString();
      }

      final res = await _client.get('bookings/$id');
      if (res is Map && res['data'] != null) {
        return BookingModel.fromJson(Map<String, dynamic>.from(res['data']));
      } else if (res is Map) {
        return BookingModel.fromJson(Map<String, dynamic>.from(res));
      }
    } catch (e) {
      debugPrint('getBookingById API error: $e');
    }

    await _loadLocalBookings();
    try {
      return _localBookings.firstWhere((b) => b.id == id || b.bookingId == id);
    } catch (_) {
      return null;
    }
  }

  // ==========================================
  // CANCEL BOOKING
  // ==========================================
  Future<BookingModel?> cancelBooking(String id, {String? reason}) async {
    try {
      final res = await _client.patch('bookings/$id/cancel', body: {
        'reason': reason ?? 'Cancelled by parent',
      });
      if (res is Map && res['data'] != null) {
        final updated = BookingModel.fromJson(Map<String, dynamic>.from(res['data']));
        _updateLocalBooking(updated);
        return updated;
      }
    } catch (e) {
      debugPrint('cancelBooking API error: $e');
    }

    // Local update
    await _loadLocalBookings();
    final index = _localBookings.indexWhere((b) => b.id == id);
    if (index != -1) {
      final updated = _localBookings[index].copyWith(
        status: 'cancelled',
        cancellationReason: reason ?? 'Cancelled by parent',
      );
      _localBookings[index] = updated;
      await _saveLocalBookings();
      return updated;
    }
    return null;
  }

  // ==========================================
  // RESCHEDULE BOOKING
  // ==========================================
  Future<BookingModel?> rescheduleBooking(
    String id, {
    required String date,
    required String startTime,
    required String endTime,
  }) async {
    try {
      final res = await _client.patch('bookings/$id/reschedule', body: {
        'date': date,
        'startTime': startTime,
        'endTime': endTime,
      });
      if (res is Map && res['data'] != null) {
        final updated = BookingModel.fromJson(Map<String, dynamic>.from(res['data']));
        _updateLocalBooking(updated);
        return updated;
      }
    } catch (e) {
      debugPrint('rescheduleBooking API error: $e');
    }

    // Local update
    await _loadLocalBookings();
    final index = _localBookings.indexWhere((b) => b.id == id);
    if (index != -1) {
      final current = _localBookings[index];
      final newDate = DateTime.tryParse(date) ?? current.date;
      final updated = current.copyWith(
        date: newDate,
        startTime: startTime,
        endTime: endTime,
        rescheduleHistory: [
          ...current.rescheduleHistory,
          BookingRescheduleModel(
            oldDate: current.date,
            oldStartTime: current.startTime,
            oldEndTime: current.endTime,
            newDate: newDate,
            newStartTime: startTime,
            newEndTime: endTime,
            requestedAt: DateTime.now(),
          ),
        ],
      );
      _localBookings[index] = updated;
      await _saveLocalBookings();
      return updated;
    }
    return null;
  }

  // ==========================================
  // STATUS TRANSITIONS (ACCEPT, REJECT, UPDATE)
  // ==========================================
  Future<BookingModel?> acceptBooking(String id) async {
    try {
      final res = await _client.patch('bookings/$id/accept');
      if (res is Map && res['data'] != null) {
        final updated = BookingModel.fromJson(Map<String, dynamic>.from(res['data']));
        _updateLocalBooking(updated);
        return updated;
      }
    } catch (e) {
      debugPrint('acceptBooking API error: $e');
    }
    return null;
  }

  Future<BookingModel?> rejectBooking(String id, {String? reason}) async {
    try {
      final res = await _client.patch('bookings/$id/reject', body: {
        'reason': reason ?? 'Declined by babysitter',
      });
      if (res is Map && res['data'] != null) {
        final updated = BookingModel.fromJson(Map<String, dynamic>.from(res['data']));
        _updateLocalBooking(updated);
        return updated;
      }
    } catch (e) {
      debugPrint('rejectBooking API error: $e');
    }
    return null;
  }

  Future<BookingModel?> updateStatus(String id, String status) async {
    try {
      final res = await _client.patch('bookings/$id/status', body: {
        'status': status,
      });
      if (res is Map && res['data'] != null) {
        final updated = BookingModel.fromJson(Map<String, dynamic>.from(res['data']));
        _updateLocalBooking(updated);
        return updated;
      }
    } catch (e) {
      debugPrint('updateStatus API error: $e');
    }
    return null;
  }

  // ==========================================
  // LOCAL CACHE HELPERS
  // ==========================================
  void _updateLocalBooking(BookingModel updated) {
    final index = _localBookings.indexWhere((b) => b.id == updated.id);
    if (index != -1) {
      _localBookings[index] = updated;
    } else {
      _localBookings.insert(0, updated);
    }
    _saveLocalBookings();
  }

  Future<void> _saveLocalBookings() async {
    try {
      final list = _localBookings.map((b) => b.toJson()).toList();
      await LocalStorage.instance.write('cached_bookings', jsonEncode(list));
    } catch (_) {}
  }

  Future<void> _loadLocalBookings() async {
    try {
      final str = await LocalStorage.instance.read('cached_bookings');
      if (str != null && str.toString().isNotEmpty) {
        final decoded = jsonDecode(str.toString());
        if (decoded is List) {
          _localBookings.clear();
          for (final item in decoded) {
            if (item is Map) {
              _localBookings.add(BookingModel.fromJson(Map<String, dynamic>.from(item)));
            }
          }
        }
      }
    } catch (_) {}
  }

  int _parseTimeToMinutes(String timeStr) {
    if (timeStr.isEmpty) return 0;
    final clean = timeStr.trim();
    final parts = clean.split(':');
    final h = int.tryParse(parts[0]) ?? 0;
    int m = 0;
    if (parts.length > 1) {
      m = int.tryParse(parts[1].split(' ')[0]) ?? 0;
    }
    return h * 60 + m;
  }
}
