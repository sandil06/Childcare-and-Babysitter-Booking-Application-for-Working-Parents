import 'package:flutter/foundation.dart';

import '../models/admin_user_model.dart';
import '../models/agency_dashboard_model.dart';
import '../models/report_model.dart';
import '../models/statistics_model.dart';
import '../models/verification_request_model.dart';
import '../services/agency_service.dart';

class AgencyProvider extends ChangeNotifier {
  static final AgencyProvider _instance = AgencyProvider._internal();
  factory AgencyProvider() => _instance;
  static AgencyProvider get instance => _instance;
  AgencyProvider._internal();

  final AgencyService _service = AgencyService();

  // State Models
  AgencyDashboardModel? _dashboard;
  SystemStatisticsModel? _statistics;
  List<VerificationRequestModel> _verificationRequests = [];
  VerificationRequestModel? _selectedVerification;
  List<AdminUserModel> _users = [];
  List<ReportModel> _reports = [];
  List<Map<String, dynamic>> _bookings = [];

  // Granular Loading States (Requirement 30)
  bool _isInitialLoading = false;
  bool _isRefreshing = false;
  bool _isLoadingMore = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  // Filters & Pagination
  String _verificationFilter = 'pending';
  String _userRoleFilter = 'all';
  String _reportStatusFilter = 'open';
  int _verificationsPage = 1;
  bool _verificationsHasMore = true;

  // Getters
  AgencyDashboardModel? get dashboard => _dashboard;
  SystemStatisticsModel? get statistics => _statistics;
  List<VerificationRequestModel> get verificationRequests => _verificationRequests;
  VerificationRequestModel? get selectedVerification => _selectedVerification;
  List<AdminUserModel> get users => _users;
  List<ReportModel> get reports => _reports;
  List<Map<String, dynamic>> get bookings => _bookings;

  bool get isInitialLoading => _isInitialLoading;
  bool get isRefreshing => _isRefreshing;
  bool get isLoadingMore => _isLoadingMore;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  void setLoadingMore(bool val) {
    _isLoadingMore = val;
    notifyListeners();
  }

  String get verificationFilter => _verificationFilter;
  String get userRoleFilter => _userRoleFilter;
  String get reportStatusFilter => _reportStatusFilter;
  bool get verificationsHasMore => _verificationsHasMore;

  // ==========================================
  // DASHBOARD
  // ==========================================
  Future<void> loadDashboard({bool refresh = false}) async {
    if (refresh) {
      _isRefreshing = true;
    } else {
      _isInitialLoading = true;
    }
    _errorMessage = null;
    notifyListeners();

    try {
      _dashboard = await _service.getDashboard();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isInitialLoading = false;
      _isRefreshing = false;
      notifyListeners();
    }
  }

  // ==========================================
  // STATISTICS
  // ==========================================
  Future<void> loadStatistics({bool refresh = false}) async {
    if (refresh) {
      _isRefreshing = true;
    } else {
      _isInitialLoading = true;
    }
    notifyListeners();

    try {
      _statistics = await _service.getStatistics();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isInitialLoading = false;
      _isRefreshing = false;
      notifyListeners();
    }
  }

  // ==========================================
  // VERIFICATIONS
  // ==========================================
  Future<void> setVerificationFilter(String filter) async {
    if (_verificationFilter == filter) return;
    _verificationFilter = filter;
    _verificationsPage = 1;
    _verificationsHasMore = true;
    await loadVerificationRequests();
  }

  Future<void> loadVerificationRequests({
    bool refresh = false,
    String? search,
  }) async {
    if (refresh) {
      _isRefreshing = true;
      _verificationsPage = 1;
    } else {
      _isInitialLoading = true;
    }
    _errorMessage = null;
    notifyListeners();

    try {
      final list = await _service.getVerificationRequests(
        status: _verificationFilter,
        search: search,
        page: _verificationsPage,
      );
      _verificationRequests = list;
      _verificationsHasMore = list.length >= 20;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isInitialLoading = false;
      _isRefreshing = false;
      notifyListeners();
    }
  }

  void selectVerification(VerificationRequestModel request) {
    _selectedVerification = request;
    notifyListeners();
  }

  Future<VerificationRequestModel?> loadVerificationDetails(String id) async {
    _isInitialLoading = true;
    notifyListeners();
    try {
      final detail = await _service.getVerificationDetails(id);
      if (detail != null) {
        _selectedVerification = detail;
      }
      return detail;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isInitialLoading = false;
      notifyListeners();
    }
  }

  Future<bool> approveVerification(String id, {String? notes}) async {
    _isSubmitting = true;
    notifyListeners();
    try {
      final ok = await _service.approveVerification(id, notes: notes);
      if (ok) {
        _verificationRequests = _verificationRequests.where((v) => v.id != id).toList();
        await loadDashboard(refresh: true);
      }
      return ok;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> rejectVerification(String id, {required String reason}) async {
    _isSubmitting = true;
    notifyListeners();
    try {
      final ok = await _service.rejectVerification(id, reason: reason);
      if (ok) {
        _verificationRequests = _verificationRequests.where((v) => v.id != id).toList();
        await loadDashboard(refresh: true);
      }
      return ok;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> requestChangesVerification(String id, {required String notes}) async {
    _isSubmitting = true;
    notifyListeners();
    try {
      final ok = await _service.requestChangesVerification(id, notes: notes);
      if (ok) {
        await loadVerificationRequests(refresh: true);
      }
      return ok;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  // ==========================================
  // USERS
  // ==========================================
  Future<void> setUserRoleFilter(String role) async {
    if (_userRoleFilter == role) return;
    _userRoleFilter = role;
    await loadUsers();
  }

  Future<void> loadUsers({bool refresh = false, String? search}) async {
    if (refresh) {
      _isRefreshing = true;
    } else {
      _isInitialLoading = true;
    }
    notifyListeners();

    try {
      _users = await _service.getUsers(
        role: _userRoleFilter,
        search: search,
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isInitialLoading = false;
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<bool> suspendUser(String id, {required String reason}) async {
    _isSubmitting = true;
    notifyListeners();
    try {
      final ok = await _service.suspendUser(id, reason: reason);
      if (ok) {
        await loadUsers(refresh: true);
      }
      return ok;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> reactivateUser(String id) async {
    _isSubmitting = true;
    notifyListeners();
    try {
      final ok = await _service.reactivateUser(id);
      if (ok) {
        await loadUsers(refresh: true);
      }
      return ok;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  // ==========================================
  // BOOKINGS MONITORING
  // ==========================================
  Future<void> loadBookings({bool refresh = false, String? status, String? search}) async {
    if (refresh) {
      _isRefreshing = true;
    } else {
      _isInitialLoading = true;
    }
    notifyListeners();

    try {
      _bookings = await _service.getBookings(status: status, search: search);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isInitialLoading = false;
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<bool> cancelBooking(String id, {required String reason}) async {
    _isSubmitting = true;
    notifyListeners();
    try {
      final ok = await _service.cancelBooking(id, reason: reason);
      if (ok) {
        await loadBookings(refresh: true);
      }
      return ok;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  // ==========================================
  // REPORTS
  // ==========================================
  Future<void> setReportStatusFilter(String status) async {
    if (_reportStatusFilter == status) return;
    _reportStatusFilter = status;
    await loadReports();
  }

  Future<void> loadReports({bool refresh = false, String? priority}) async {
    if (refresh) {
      _isRefreshing = true;
    } else {
      _isInitialLoading = true;
    }
    notifyListeners();

    try {
      _reports = await _service.getReports(
        status: _reportStatusFilter,
        priority: priority,
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isInitialLoading = false;
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<bool> updateReportStatus(
    String id, {
    required String status,
    String? resolutionNotes,
  }) async {
    _isSubmitting = true;
    notifyListeners();
    try {
      final ok = await _service.updateReportStatus(
        id,
        status: status,
        resolutionNotes: resolutionNotes,
      );
      if (ok) {
        await loadReports(refresh: true);
        await loadDashboard(refresh: true);
      }
      return ok;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> resolveReport(
    String id, {
    required String resolutionNotes,
  }) async {
    _isSubmitting = true;
    notifyListeners();
    try {
      final ok = await _service.resolveReport(id, resolutionNotes: resolutionNotes);
      if (ok) {
        await loadReports(refresh: true);
        await loadDashboard(refresh: true);
      }
      return ok;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> escalateReport(
    String id, {
    String? notes,
  }) async {
    _isSubmitting = true;
    notifyListeners();
    try {
      final ok = await _service.escalateReport(id, notes: notes);
      if (ok) {
        await loadReports(refresh: true);
        await loadDashboard(refresh: true);
      }
      return ok;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> dismissReport(
    String id, {
    required String reason,
  }) async {
    _isSubmitting = true;
    notifyListeners();
    try {
      final ok = await _service.dismissReport(id, reason: reason);
      if (ok) {
        await loadReports(refresh: true);
        await loadDashboard(refresh: true);
      }
      return ok;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<ReportModel?> getReportById(String id) async {
    return _service.getReportById(id);
  }
}
