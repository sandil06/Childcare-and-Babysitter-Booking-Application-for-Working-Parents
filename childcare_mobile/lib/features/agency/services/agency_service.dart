import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/local_storage.dart';
import '../models/admin_user_model.dart';
import '../models/agency_dashboard_model.dart';
import '../models/report_model.dart';
import '../models/statistics_model.dart';
import '../models/verification_request_model.dart';
import '../models/agency_notification_model.dart';

class AgencyService {
  static final AgencyService _instance = AgencyService._internal();
  factory AgencyService() => _instance;
  AgencyService._internal();

  final ApiClient _client = ApiClient();
  String? lastError;

  bool _isSuccessResponse(dynamic res) {
    if (res == null) return false;
    if (res is bool) return res;
    if (res is Map) {
      if (res.containsKey('success')) {
        return res['success'] == true;
      }
      return res.isNotEmpty;
    }
    return true;
  }

  Future<void> _ensureAuthToken() async {
    final token = await LocalStorage.instance.read('auth_token');
    if (token != null && token.toString().isNotEmpty) {
      ApiClient.authToken = token.toString();
    }
  }

  // ==========================================
  // 1. AGENCY AUTHENTICATION
  // ==========================================
  Future<Map<String, dynamic>> loginAgency({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _client.post('auth/login', body: {
        'email': email,
        'password': password,
      });

      Map<String, dynamic>? data;
      if (res is Map) {
        if (res['data'] is Map) {
          data = Map<String, dynamic>.from(res['data'] as Map);
        } else {
          data = Map<String, dynamic>.from(res);
        }
      }

      if (data != null && (data['token'] != null || data['user'] != null)) {
        final token = data['token']?.toString() ?? '';
        final user = data['user'] is Map ? Map<String, dynamic>.from(data['user'] as Map) : {};

        final role = user['role']?.toString().toLowerCase();
        if (role != 'agency' && role != 'admin') {
          throw Exception('Access denied. Agency or Administrator account required.');
        }

        if (token.isNotEmpty) {
          await LocalStorage.instance.write('auth_token', token);
          ApiClient.authToken = token;
        }
        if (user['name'] != null) {
          await LocalStorage.instance.write('user_name', user['name'].toString());
        }
        if (user['email'] != null) {
          await LocalStorage.instance.write('user_email', user['email'].toString());
        }
        if (user['role'] != null) {
          await LocalStorage.instance.write('user_role', user['role'].toString());
        }
        return data;
      }
    } catch (e) {
      debugPrint('[AgencyService] loginAgency error: $e');
      rethrow;
    }

    throw Exception('Login failed: Invalid server response');
  }

  // ==========================================
  // 2. DASHBOARD & STATS
  // ==========================================
  Future<AgencyDashboardModel> getDashboard() async {
    await _ensureAuthToken();
    try {
      final res = await _client.get('agency/dashboard');
      final map = res is Map
          ? (res['data'] is Map ? res['data'] as Map : res)
          : null;
      if (map != null) {
        return AgencyDashboardModel.fromJson(Map<String, dynamic>.from(map));
      }
    } catch (e) {
      debugPrint('[AgencyService] getDashboard API error: $e');
    }

    // Fallback offline mock for dashboard
    return const AgencyDashboardModel(
      totalUsers: 148,
      totalParents: 92,
      totalBabysitters: 54,
      verifiedBabysitters: 38,
      pendingVerifications: 12,
      rejectedVerifications: 4,
      totalBookings: 320,
      activeBookings: 18,
      completedBookings: 284,
      cancelledBookings: 18,
      openComplaints: 5,
      resolvedComplaints: 27,
    );
  }

  Future<SystemStatisticsModel> getStatistics() async {
    await _ensureAuthToken();
    try {
      final res = await _client.get('agency/statistics');
      final map = res is Map
          ? (res['data'] is Map ? res['data'] as Map : res)
          : null;
      if (map != null) {
        return SystemStatisticsModel.fromJson(Map<String, dynamic>.from(map));
      }
    } catch (e) {
      debugPrint('[AgencyService] getStatistics API error: $e');
    }

    return const SystemStatisticsModel(
      totalUsers: 148,
      totalParents: 92,
      totalBabysitters: 54,
      verifiedBabysitters: 38,
      activeUsers: 142,
      suspendedUsers: 6,
      totalBookings: 320,
      activeBookings: 18,
      completedBookings: 284,
      cancelledBookings: 18,
      pendingVerifications: 12,
      verifiedRequests: 38,
      rejectedVerifications: 4,
      openReports: 5,
      resolvedReports: 27,
      totalTransactionVolume: 486000.0,
      totalPlatformRevenue: 48600.0,
      successfulTransactions: 304,
      failedTransactions: 6,
    );
  }

  // ==========================================
  // 3. BABYSITTER VERIFICATIONS
  // ==========================================
  Future<List<VerificationRequestModel>> getVerificationRequests({
    String? status,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    await _ensureAuthToken();
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        if (status != null && status != 'all') 'status': status,
        if (search != null && search.isNotEmpty) 'search': search,
      };

      final queryString = Uri(queryParameters: queryParams).query;
      final res = await _client.get('agency/verifications?$queryString');

      final list = res is List
          ? res
          : (res is Map && res['data'] is List ? res['data'] as List : null);
      if (list != null) {
        return list
            .map((e) => VerificationRequestModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
    } catch (e) {
      debugPrint('[AgencyService] getVerificationRequests error: $e');
    }

    // Fallback data
    return [
      VerificationRequestModel(
        id: 'ver-101',
        babysitterId: 'sitter-1',
        name: 'Amaya Fernando',
        email: 'amaya.fernando@example.com',
        phone: '+94 77 123 4567',
        avatar: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150',
        experienceYears: 4,
        hourlyRate: 1500.0,
        status: 'pending',
        skills: const ['First Aid', 'Toddler Care', 'Homework Help'],
        languages: const ['English', 'Sinhala'],
        qualifications: const ['Diploma in Early Childhood Education'],
        documents: [
          VerificationDocItem(
            type: 'id',
            name: 'National Identity Card (Front/Back)',
            url: 'https://picsum.photos/seed/nic/800/600',
            status: 'pending',
            uploadedAt: DateTime.now().subtract(const Duration(days: 2)),
          ),
          VerificationDocItem(
            type: 'police_check',
            name: 'Police Clearance Certificate 2026',
            url: 'https://picsum.photos/seed/police/800/600',
            status: 'pending',
            uploadedAt: DateTime.now().subtract(const Duration(days: 2)),
          ),
          VerificationDocItem(
            type: 'certificate',
            name: 'Red Cross First Aid & CPR',
            url: 'https://picsum.photos/seed/cert/800/600',
            status: 'pending',
            uploadedAt: DateTime.now().subtract(const Duration(days: 2)),
          ),
        ],
        submittedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      VerificationRequestModel(
        id: 'ver-102',
        babysitterId: 'sitter-2',
        name: 'Kavindi Perera',
        email: 'kavindi.perera@example.com',
        phone: '+94 71 987 6543',
        avatar: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150',
        experienceYears: 3,
        hourlyRate: 1350.0,
        status: 'under_review',
        skills: const ['Meal Prep', 'Infant Care'],
        languages: const ['English', 'Sinhala'],
        documents: [
          VerificationDocItem(
            type: 'id',
            name: 'NIC Copy',
            url: 'https://picsum.photos/seed/nic2/800/600',
            status: 'under_review',
            uploadedAt: DateTime.now().subtract(const Duration(days: 4)),
          ),
        ],
        submittedAt: DateTime.now().subtract(const Duration(days: 4)),
      ),
    ];
  }

  Future<VerificationRequestModel?> getVerificationDetails(String id) async {
    await _ensureAuthToken();
    try {
      final res = await _client.get('agency/verifications/$id');
      final map = res is Map
          ? (res['data'] is Map ? res['data'] as Map : res)
          : null;
      if (map != null) {
        return VerificationRequestModel.fromJson(Map<String, dynamic>.from(map));
      }
    } catch (e) {
      debugPrint('[AgencyService] getVerificationDetails error: $e');
    }
    return null;
  }

  Future<bool> approveVerification(String id, {String? notes}) async {
    await _ensureAuthToken();
    try {
      final res = await _client.patch('agency/verifications/$id/approve', body: {
        'notes': ?notes,
      });
      return _isSuccessResponse(res);
    } catch (e) {
      lastError = (e is ApiException) ? e.message : e.toString();
      debugPrint('[AgencyService] approveVerification error: $e');
      return false;
    }
  }

  Future<bool> rejectVerification(String id, {required String reason}) async {
    await _ensureAuthToken();
    try {
      final res = await _client.patch('agency/verifications/$id/reject', body: {
        'reason': reason,
      });
      return _isSuccessResponse(res);
    } catch (e) {
      lastError = (e is ApiException) ? e.message : e.toString();
      debugPrint('[AgencyService] rejectVerification error: $e');
      return false;
    }
  }

  Future<bool> requestChangesVerification(String id, {required String notes}) async {
    await _ensureAuthToken();
    try {
      final res = await _client.patch('agency/verifications/$id/request-changes', body: {
        'notes': notes,
      });
      return _isSuccessResponse(res);
    } catch (e) {
      lastError = (e is ApiException) ? e.message : e.toString();
      debugPrint('[AgencyService] requestChangesVerification error: $e');
      return false;
    }
  }

  // ==========================================
  // 4. USER MANAGEMENT (Parents & Sitters)
  // ==========================================
  Future<List<AdminUserModel>> getUsers({
    String? role,
    String? status,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    await _ensureAuthToken();
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        if (role != null && role != 'all') 'role': role,
        if (status != null && status != 'all') 'status': status,
        if (search != null && search.isNotEmpty) 'search': search,
      };

      final queryString = Uri(queryParameters: queryParams).query;
      final res = await _client.get('agency/users?$queryString');

      final list = res is List
          ? res
          : (res is Map && res['data'] is List ? res['data'] as List : null);
      if (list != null) {
        return list
            .map((e) => AdminUserModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
    } catch (e) {
      debugPrint('[AgencyService] getUsers error: $e');
    }

    return [
      AdminUserModel(
        id: 'u-1',
        name: 'Dulani Senanayake',
        email: 'dulani.s@gmail.com',
        phone: '+94 77 445 5667',
        role: 'parent',
        accountStatus: 'active',
        totalBookings: 14,
        createdAt: DateTime.now().subtract(const Duration(days: 45)),
      ),
      AdminUserModel(
        id: 'u-2',
        name: 'Amaya Fernando',
        email: 'amaya.fernando@example.com',
        phone: '+94 77 123 4567',
        role: 'babysitter',
        accountStatus: 'active',
        totalBookings: 28,
        averageRating: 4.9,
        createdAt: DateTime.now().subtract(const Duration(days: 90)),
      ),
    ];
  }

  Future<bool> suspendUser(String id, {required String reason}) async {
    await _ensureAuthToken();
    try {
      final res = await _client.patch('agency/users/$id/suspend', body: {
        'reason': reason,
      });
      return _isSuccessResponse(res);
    } catch (e) {
      lastError = (e is ApiException) ? e.message : e.toString();
      debugPrint('[AgencyService] suspendUser error: $e');
      return false;
    }
  }

  Future<bool> reactivateUser(String id) async {
    await _ensureAuthToken();
    try {
      final res = await _client.patch('agency/users/$id/reactivate', body: {});
      return _isSuccessResponse(res);
    } catch (e) {
      lastError = (e is ApiException) ? e.message : e.toString();
      debugPrint('[AgencyService] reactivateUser error: $e');
      return false;
    }
  }

  // ==========================================
  // 5. BOOKINGS MONITORING
  // ==========================================
  Future<List<Map<String, dynamic>>> getBookings({
    String? status,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    await _ensureAuthToken();
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        if (status != null && status != 'all') 'status': status,
        if (search != null && search.isNotEmpty) 'search': search,
      };

      final queryString = Uri(queryParameters: queryParams).query;
      final res = await _client.get('agency/bookings?$queryString');

      final list = res is List
          ? res
          : (res is Map && res['data'] is List ? res['data'] as List : null);
      if (list != null) {
        return list
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
    } catch (e) {
      debugPrint('[AgencyService] getBookings error: $e');
    }

    return [
      {
        'id': 'bk-901',
        'bookingId': '#BK-901',
        'parentName': 'Dulani Senanayake',
        'babysitterName': 'Amaya Fernando',
        'date': '2026-10-08',
        'startTime': '09:00 AM',
        'endTime': '01:00 PM',
        'status': 'confirmed',
        'paymentStatus': 'paid',
        'totalAmount': 6000.0,
      },
      {
        'id': 'bk-902',
        'bookingId': '#BK-902',
        'parentName': 'Ranil Weerasinghe',
        'babysitterName': 'Kavindi Perera',
        'date': '2026-10-09',
        'startTime': '02:00 PM',
        'endTime': '06:00 PM',
        'status': 'in_progress',
        'paymentStatus': 'paid',
        'totalAmount': 5400.0,
      },
    ];
  }

  Future<bool> cancelBooking(String id, {required String reason}) async {
    await _ensureAuthToken();
    try {
      final res = await _client.patch('agency/bookings/$id/cancel', body: {
        'reason': reason,
      });
      return _isSuccessResponse(res);
    } catch (e) {
      lastError = (e is ApiException) ? e.message : e.toString();
      debugPrint('[AgencyService] cancelBooking error: $e');
      return false;
    }
  }

  // ==========================================
  // 6. SAFETY REPORTS / COMPLAINTS
  // ==========================================
  Future<List<ReportModel>> getReports({
    String? status,
    String? priority,
    String? category,
    int page = 1,
    int limit = 20,
  }) async {
    await _ensureAuthToken();
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        if (status != null && status != 'all') 'status': status,
        if (priority != null && priority != 'all') 'priority': priority,
        if (category != null && category != 'all') 'category': category,
      };

      final queryString = Uri(queryParameters: queryParams).query;
      final res = await _client.get('agency/reports?$queryString');

      final list = res is List
          ? res
          : (res is Map && res['data'] is List ? res['data'] as List : null);
      if (list != null) {
        return list
            .map((e) => ReportModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
    } catch (e) {
      debugPrint('[AgencyService] getReports error: $e');
    }

    return [
      ReportModel(
        id: 'rep-401',
        reporterId: 'p-1',
        reporterName: 'Chamari Silva',
        reporterRole: 'parent',
        reportedUserId: 's-5',
        reportedUserName: 'Nuwanthi Dias',
        reportedUserRole: 'babysitter',
        category: 'Inappropriate Behaviour',
        priority: 'high',
        status: 'open',
        description: 'Sitter arrived 45 minutes late without prior notice and used phone continuously.',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      ReportModel(
        id: 'rep-402',
        reporterId: 's-2',
        reporterName: 'Kavindi Perera',
        reporterRole: 'babysitter',
        reportedUserId: 'p-8',
        reportedUserName: 'Kamal Bandara',
        reportedUserRole: 'parent',
        category: 'Payment Issue',
        priority: 'medium',
        status: 'under_review',
        description: 'Overtime hours were not compensated during extended shift.',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }

  Future<ReportModel?> getReportById(String id) async {
    await _ensureAuthToken();
    try {
      final res = await _client.get('agency/reports/$id');
      final map = res is Map
          ? (res['data'] is Map ? res['data'] as Map : res)
          : null;
      if (map != null) {
        return ReportModel.fromJson(Map<String, dynamic>.from(map));
      }
    } catch (e) {
      debugPrint('[AgencyService] getReportById error: $e');
    }
    return null;
  }

  Future<bool> updateReportStatus(
    String id, {
    required String status,
    String? resolutionNotes,
  }) async {
    await _ensureAuthToken();
    try {
      final res = await _client.patch('agency/reports/$id/status', body: {
        'status': status,
        'resolutionNotes': ?resolutionNotes,
      });
      return _isSuccessResponse(res);
    } catch (e) {
      lastError = (e is ApiException) ? e.message : e.toString();
      debugPrint('[AgencyService] updateReportStatus error: $e');
      return false;
    }
  }

  Future<bool> resolveReport(
    String id, {
    required String resolutionNotes,
  }) async {
    await _ensureAuthToken();
    try {
      final res = await _client.patch('agency/reports/$id/resolve', body: {
        'resolutionNotes': resolutionNotes,
      });
      return _isSuccessResponse(res);
    } catch (e) {
      lastError = (e is ApiException) ? e.message : e.toString();
      debugPrint('[AgencyService] resolveReport error: $e');
      return false;
    }
  }

  Future<bool> escalateReport(
    String id, {
    String? notes,
  }) async {
    await _ensureAuthToken();
    try {
      final res = await _client.patch('agency/reports/$id/escalate', body: {
        'notes': ?notes,
      });
      return _isSuccessResponse(res);
    } catch (e) {
      lastError = (e is ApiException) ? e.message : e.toString();
      debugPrint('[AgencyService] escalateReport error: $e');
      return false;
    }
  }

  Future<bool> dismissReport(
    String id, {
    required String reason,
  }) async {
    await _ensureAuthToken();
    try {
      final res = await _client.patch('agency/reports/$id/dismiss', body: {
        'reason': reason,
      });
      return _isSuccessResponse(res);
    } catch (e) {
      lastError = (e is ApiException) ? e.message : e.toString();
      debugPrint('[AgencyService] dismissReport error: $e');
      return false;
    }
  }

  // ==========================================
  // 6. SYSTEM NOTIFICATIONS & BROADCASTS
  // ==========================================
  Future<List<AgencyNotificationModel>> getAgencyNotifications({
    String category = 'all',
    int page = 1,
    int limit = 20,
  }) async {
    await _ensureAuthToken();
    try {
      final res = await _client.get('agency/notifications?category=$category&page=$page&limit=$limit');
      final list = res is List
          ? res
          : (res is Map && res['data'] is List ? res['data'] as List : null);
      if (list != null) {
        return list
            .map((item) => AgencyNotificationModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }
    } catch (e) {
      debugPrint('[AgencyService] getAgencyNotifications error: $e');
    }

    // Offline mock fallback
    return [
      AgencyNotificationModel(
        id: 'anotif-1',
        title: 'New Verification Request Submitted',
        message: 'Amaya Fernando uploaded police clearance and qualification certificates for review.',
        type: 'verification_submitted',
        category: 'verification',
        priority: 'high',
        createdAt: DateTime.now().subtract(const Duration(minutes: 25)),
      ),
      AgencyNotificationModel(
        id: 'anotif-2',
        title: 'Urgent Safety Report Filed',
        message: 'Parent Dulani Senanayake filed an urgent safety incident report regarding booking BK-901.',
        type: 'high_priority_complaint',
        category: 'safety',
        priority: 'urgent',
        createdAt: DateTime.now().subtract(const Duration(minutes: 90)),
      ),
      AgencyNotificationModel(
        id: 'anotif-3',
        title: 'Automated Atlas Backup Completed',
        message: 'Daily encrypted cluster snapshot and audit log backup completed without anomalies.',
        type: 'system_alert',
        category: 'system',
        priority: 'normal',
        isRead: true,
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      ),
    ];
  }

  Future<bool> broadcastNotification({
    required String title,
    required String message,
    String targetAudience = 'all',
    String priority = 'normal',
  }) async {
    await _ensureAuthToken();
    try {
      final res = await _client.post('agency/notifications/broadcast', body: {
        'title': title,
        'message': message,
        'targetAudience': targetAudience,
        'priority': priority,
      });
      return _isSuccessResponse(res);
    } catch (e) {
      lastError = (e is ApiException) ? e.message : e.toString();
      debugPrint('[AgencyService] broadcastNotification error: $e');
      return false;
    }
  }
}

