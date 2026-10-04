import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/local_storage.dart';
import '../models/availability_model.dart';
import '../models/babysitter_model.dart';
import '../models/booking_request_model.dart';
import '../models/earning_model.dart';
import '../services/babysitter_service.dart';

class BabysitterProvider extends ChangeNotifier {
  BabysitterProvider({BabysitterService? service})
    : _service = service ?? BabysitterService() {
    _init();
  }

  static BabysitterProvider? _instance;
  static BabysitterProvider get instance => _instance ??= BabysitterProvider();

  final BabysitterService _service;

  BabysitterModel? _profile;
  bool _isLoading = false;
  bool _isAvailable = true;
  String? _errorMessage;

  Map<String, dynamic>? _dashboardData;
  List<AvailabilityModel> _availabilities = [];
  List<BookingRequestModel> _bookings = [];
  BookingRequestModel? _selectedBooking;
  EarningSummaryModel? _earnings;
  List<Map<String, dynamic>> _notifications = [];
  Future<void>? _dashboardRequest;
  final Map<String, Future<void>> _bookingRequests = {};
  Future<void>? _notificationsRequest;
  Future<void>? _refreshRequest;

  // Getters
  BabysitterModel? get profile => _profile;
  bool get isLoading => _isLoading;
  bool get isAvailable => _isAvailable;
  String? get errorMessage => _errorMessage;

  Map<String, dynamic>? get dashboardData => _dashboardData;
  List<AvailabilityModel> get availabilities => _availabilities;
  List<BookingRequestModel> get bookings => _bookings;
  BookingRequestModel? get selectedBooking => _selectedBooking;
  EarningSummaryModel? get earnings => _earnings;
  List<Map<String, dynamic>> get notifications => _notifications;
  int get unreadNotificationCount =>
      _notifications.where((n) => n['isRead'] == false).length;

  List<BookingRequestModel> get newRequests =>
      _bookings.where((b) => b.isPending).toList();
  List<BookingRequestModel> get upcomingBookings =>
      _bookings.where((b) => b.isAccepted || b.isInProgress).toList();
  List<BookingRequestModel> get pastBookings =>
      _bookings.where((b) => b.isCompleted || b.isCancelled).toList();

  Future<void> _init() async {
    final token = await LocalStorage.instance.read('auth_token');
    if (token != null && token.toString().isNotEmpty) {
      ApiClient.authToken = token.toString();
    }
    await fetchProfile();
  }

  Future<void> fetchProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await _service.getProfile();
      _isAvailable = _profile?.isAvailable ?? true;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await _service.updateProfile(data);
      _isAvailable = _profile?.isAvailable ?? true;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> registerSitter(Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await _service.register(data);
      _isAvailable = _profile?.isAvailable ?? true;
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleAvailability(bool value) async {
    _isAvailable = value;
    notifyListeners();
    try {
      await _service.toggleAvailability(value);
      if (_profile != null) {
        _profile = _profile!.copyWith(isAvailable: value);
      }
    } catch (e) {
      _isAvailable = !value;
      _errorMessage = e.toString();
    } finally {
      notifyListeners();
    }
  }

  Future<void> fetchDashboard() {
    final inFlight = _dashboardRequest;
    if (inFlight != null) return inFlight;

    final request = _fetchDashboard();
    _dashboardRequest = request;
    return request.whenComplete(() {
      if (identical(_dashboardRequest, request)) {
        _dashboardRequest = null;
      }
    });
  }

  Future<void> _fetchDashboard() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait<dynamic>([
        _service.getDashboardData(),
        fetchBookings(),
      ]);
      _dashboardData = results[0] as Map<String, dynamic>;
      if (_dashboardData != null && _dashboardData!['profile'] != null) {
        _profile = BabysitterModel.fromJson(_dashboardData!['profile']);
        _isAvailable = _profile?.isAvailable ?? true;
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAvailabilities({DateTime? month}) async {
    try {
      _availabilities = await _service.getAvailabilities(month: month);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      notifyListeners();
    }
  }

  Future<bool> addAvailabilitySlot(AvailabilityModel slot) async {
    try {
      final created = await _service.addAvailability(slot);
      _availabilities.add(created);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateAvailabilitySlot(AvailabilityModel slot) async {
    try {
      final updated = await _service.updateAvailability(slot.id, slot);
      final idx = _availabilities.indexWhere((a) => a.id == slot.id);
      if (idx != -1) {
        _availabilities[idx] = updated;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAvailabilitySlot(String id) async {
    try {
      await _service.deleteAvailability(id);
      _availabilities.removeWhere((a) => a.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchBookings({String? status}) {
    final key = status ?? 'all';
    final inFlight = _bookingRequests[key];
    if (inFlight != null) return inFlight;

    final request = _fetchBookings(status: status);
    _bookingRequests[key] = request;
    return request.whenComplete(() {
      if (identical(_bookingRequests[key], request)) {
        _bookingRequests.remove(key);
      }
    });
  }

  Future<void> _fetchBookings({String? status}) async {
    try {
      _bookings = await _service.getBookings(status: status);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      notifyListeners();
    }
  }

  void selectBooking(BookingRequestModel booking) {
    _selectedBooking = booking;
    notifyListeners();
  }

  Future<bool> acceptBooking(String id) async {
    _isLoading = true;
    notifyListeners();
    try {
      final updated = await _service.acceptBooking(id);
      final idx = _bookings.indexWhere((b) => b.id == id);
      if (idx != -1) {
        _bookings[idx] = updated;
      }
      if (_selectedBooking?.id == id) {
        _selectedBooking = updated;
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> rejectBooking(String id, {String? reason}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final updated = await _service.rejectBooking(id, reason: reason);
      final idx = _bookings.indexWhere((b) => b.id == id);
      if (idx != -1) {
        _bookings[idx] = updated;
      }
      if (_selectedBooking?.id == id) {
        _selectedBooking = updated;
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateJobStatus(String id, String status) async {
    _isLoading = true;
    notifyListeners();
    try {
      final updated = await _service.updateJobStatus(id, status);
      final idx = _bookings.indexWhere((b) => b.id == id);
      if (idx != -1) {
        _bookings[idx] = updated;
      }
      if (_selectedBooking?.id == id) {
        _selectedBooking = updated;
      }
      if (status == 'completed' && _profile != null) {
        _profile = _profile!.copyWith(
          totalCompletedBookings: _profile!.totalCompletedBookings + 1,
        );
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshDashboard() {
    final inFlight = _refreshRequest;
    if (inFlight != null) return inFlight;

    final request = _refreshDashboard();
    _refreshRequest = request;
    return request.whenComplete(() {
      if (identical(_refreshRequest, request)) {
        _refreshRequest = null;
      }
    });
  }

  Future<void> _refreshDashboard() async {
    final results = await Future.wait<dynamic>([
      _service.getDashboardData(),
      _service.getBookings(),
      _service.getNotifications(),
    ]);

    _dashboardData = results[0] as Map<String, dynamic>;
    _bookings = results[1] as List<BookingRequestModel>;
    _notifications = results[2] as List<Map<String, dynamic>>;

    if (_dashboardData?['profile'] is Map<String, dynamic>) {
      _profile = BabysitterModel.fromJson(_dashboardData!['profile']);
      _isAvailable = _profile?.isAvailable ?? true;
    }
    notifyListeners();
  }

  Future<void> refreshDashboardSilently() async {
    try {
      await refreshDashboard();
    } catch (_) {
      // Individual service methods preserve cached values on failure.
    }
  }

  Future<void> fetchEarnings({String range = 'weekly'}) async {
    _isLoading = true;
    notifyListeners();
    try {
      _earnings = await _service.getEarnings(range: range);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchNotifications() {
    final inFlight = _notificationsRequest;
    if (inFlight != null) return inFlight;

    final request = _fetchNotifications();
    _notificationsRequest = request;
    return request.whenComplete(() {
      if (identical(_notificationsRequest, request)) {
        _notificationsRequest = null;
      }
    });
  }

  Future<void> _fetchNotifications() async {
    try {
      _notifications = await _service.getNotifications();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      notifyListeners();
    }
  }

  Future<void> markNotificationRead(String id) async {
    await _service.markNotificationRead(id);
    final idx = _notifications.indexWhere((n) => n['id'] == id);
    if (idx != -1) {
      _notifications[idx]['isRead'] = true;
    }
    notifyListeners();
  }

  Future<void> markAllNotificationsRead() async {
    await _service.markAllNotificationsRead();
    for (var n in _notifications) {
      n['isRead'] = true;
    }
    notifyListeners();
  }
}
