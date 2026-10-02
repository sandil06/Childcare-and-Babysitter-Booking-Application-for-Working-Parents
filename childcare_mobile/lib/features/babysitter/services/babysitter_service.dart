import '../../../../core/network/api_client.dart';
import '../models/availability_model.dart';
import '../models/babysitter_model.dart';
import '../models/booking_request_model.dart';
import '../models/earning_model.dart';

class BabysitterService {
  BabysitterService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  // In-memory fallback mock database for testing and offline resilience
  static BabysitterModel _currentProfile = const BabysitterModel(
    id: 'sitter-1',
    userId: 'user-sitter-1',
    name: 'Maya Johnson',
    email: 'maya.johnson@example.com',
    phone: '+1 (555) 019-2834',
    address: '24 Elm Street, Brooklyn, NY',
    bio:
        'Certified early childhood educator with over 4 years of experience specializing in infant care and toddler development. Passionate about fun, creative learning and child safety.',
    hourlyRate: 28.0,
    experienceYears: 4,
    skills: [
      'Infant Care',
      'Toddler Care',
      'First Aid & CPR',
      'Meal Preparation',
      'Homework Help',
      'Bedtime Routines',
    ],
    languages: ['English', 'Spanish'],
    qualifications: [
      'CPR & Pediatric First Aid Certified (Red Cross)',
      'Early Childhood Education Associate Degree',
      'Water Safety Certified',
    ],
    documents: [
      VerificationDocumentModel(
        type: 'id',
        name: 'National ID / Passport',
        status: 'verified',
      ),
      VerificationDocumentModel(
        type: 'police_check',
        name: 'Police Background Clearance',
        status: 'verified',
      ),
      VerificationDocumentModel(
        type: 'qualification',
        name: 'CPR & First Aid Certificate',
        status: 'verified',
      ),
      VerificationDocumentModel(
        type: 'photo',
        name: 'Profile Photograph',
        status: 'verified',
      ),
    ],
    verificationStatus: 'verified',
    averageRating: 4.95,
    totalReviews: 32,
    totalCompletedBookings: 48,
    isAvailable: true,
  );

  static final List<AvailabilityModel> _mockAvailabilities = [
    AvailabilityModel(
      id: 'av-1',
      babysitterId: 'sitter-1',
      date: DateTime.now(),
      startTime: '08:00',
      endTime: '12:00',
      available: true,
    ),
    AvailabilityModel(
      id: 'av-2',
      babysitterId: 'sitter-1',
      date: DateTime.now(),
      startTime: '13:00',
      endTime: '18:00',
      available: true,
    ),
    AvailabilityModel(
      id: 'av-3',
      babysitterId: 'sitter-1',
      date: DateTime.now().add(const Duration(days: 1)),
      startTime: '09:00',
      endTime: '17:00',
      available: true,
    ),
    AvailabilityModel(
      id: 'av-4',
      babysitterId: 'sitter-1',
      date: DateTime.now().add(const Duration(days: 2)),
      startTime: '10:00',
      endTime: '16:00',
      available: true,
    ),
  ];

  static final List<BookingRequestModel> _mockBookings = [
    BookingRequestModel(
      id: 'req-1',
      bookingId: '#BK-8841',
      parentId: 'p-1',
      parentName: 'Sarah Jenkins',
      parentPhone: '+1 (555) 432-8891',
      date: DateTime.now(),
      startTime: '15:00',
      endTime: '19:00',
      durationHours: 4.0,
      location: '142 West End Ave, Apt 4B',
      childCount: 2,
      childrenDetails: const [
        ChildInfo(name: 'Leo', age: 4, notes: 'Loves building blocks and drawing'),
        ChildInfo(name: 'Mia', age: 2, notes: 'Naps around 4:30 PM'),
      ],
      specialNotes: 'Please ensure kids wash hands before snack time. First aid kit is in the pantry.',
      totalAmount: 112.0,
      hourlyRate: 28.0,
      status: 'pending',
    ),
    BookingRequestModel(
      id: 'req-2',
      bookingId: '#BK-8839',
      parentId: 'p-2',
      parentName: 'Michael Chang',
      parentPhone: '+1 (555) 890-1234',
      date: DateTime.now().add(const Duration(days: 1)),
      startTime: '10:00',
      endTime: '14:00',
      durationHours: 4.0,
      location: '58 Lincoln Rd, Brooklyn',
      childCount: 1,
      childrenDetails: const [
        ChildInfo(name: 'Lucas', age: 3, notes: 'Peanut allergy - please be mindful'),
      ],
      specialNotes: 'Snacks are prepared in the fridge container.',
      totalAmount: 112.0,
      hourlyRate: 28.0,
      status: 'accepted',
    ),
    BookingRequestModel(
      id: 'req-3',
      bookingId: '#BK-8820',
      parentId: 'p-3',
      parentName: 'Emily Watson',
      parentPhone: '+1 (555) 765-4321',
      date: DateTime.now().subtract(const Duration(days: 2)),
      startTime: '13:00',
      endTime: '17:00',
      durationHours: 4.0,
      location: '900 Grand Concourse',
      childCount: 1,
      childrenDetails: const [
        ChildInfo(name: 'Chloe', age: 5, notes: 'Enjoys outdoor games'),
      ],
      specialNotes: 'Thank you for your fantastic care!',
      totalAmount: 112.0,
      hourlyRate: 28.0,
      status: 'completed',
    ),
    BookingRequestModel(
      id: 'req-4',
      bookingId: '#BK-8815',
      parentId: 'p-4',
      parentName: 'David Miller',
      parentPhone: '+1 (555) 654-3210',
      date: DateTime.now().subtract(const Duration(days: 5)),
      startTime: '09:00',
      endTime: '13:00',
      durationHours: 4.0,
      location: '210 Columbus Ave',
      childCount: 2,
      childrenDetails: const [
        ChildInfo(name: 'Oliver', age: 4),
        ChildInfo(name: 'Sophia', age: 6),
      ],
      specialNotes: 'Trip rescheduled by parent.',
      totalAmount: 112.0,
      hourlyRate: 28.0,
      status: 'cancelled',
    ),
  ];

  static final List<Map<String, dynamic>> _mockNotifications = [
    {
      'id': 'notif-1',
      'title': 'New Booking Request',
      'message': 'Sarah Jenkins requested a 4-hour booking for today at 3:00 PM.',
      'type': 'new_booking_request',
      'isRead': false,
      'createdAt': DateTime.now().subtract(const Duration(minutes: 25)).toIso8601String(),
    },
    {
      'id': 'notif-2',
      'title': 'Payment Received',
      'message': 'You received \$112.00 for your booking with Emily Watson.',
      'type': 'payment_received',
      'isRead': false,
      'createdAt': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
    },
    {
      'id': 'notif-3',
      'title': 'Verification Approved',
      'message': 'Congratulations! Your CPR and Police Clearance have been verified.',
      'type': 'verification_approved',
      'isRead': true,
      'createdAt': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
    },
    {
      'id': 'notif-4',
      'title': 'Upcoming Booking Reminder',
      'message': 'You have an upcoming booking tomorrow at 10:00 AM with Michael Chang.',
      'type': 'upcoming_booking_reminder',
      'isRead': true,
      'createdAt': DateTime.now().subtract(const Duration(days: 1, hours: 2)).toIso8601String(),
    },
  ];

  Future<BabysitterModel> getProfile() async {
    try {
      final res = await _client.get('babysitters/me');
      if (res is Map<String, dynamic>) {
        _currentProfile = BabysitterModel.fromJson(res);
        return _currentProfile;
      }
    } catch (_) {
      // Fallback
    }
    return _currentProfile;
  }

  Future<BabysitterModel> updateProfile(Map<String, dynamic> data) async {
    try {
      final res = await _client.patch('babysitters/me', body: data);
      if (res is Map<String, dynamic>) {
        _currentProfile = BabysitterModel.fromJson(res);
        return _currentProfile;
      }
    } catch (_) {
      // Fallback
    }
    _currentProfile = _currentProfile.copyWith(
      bio: data['bio']?.toString() ?? _currentProfile.bio,
      hourlyRate: (data['hourlyRate'] as num?)?.toDouble() ?? _currentProfile.hourlyRate,
      experienceYears: (data['experienceYears'] as num?)?.toInt() ?? _currentProfile.experienceYears,
      skills: (data['skills'] as List?)?.map((e) => e.toString()).toList() ?? _currentProfile.skills,
      languages: (data['languages'] as List?)?.map((e) => e.toString()).toList() ?? _currentProfile.languages,
      qualifications: (data['qualifications'] as List?)?.map((e) => e.toString()).toList() ?? _currentProfile.qualifications,
      address: data['address']?.toString() ?? _currentProfile.address,
      phone: data['phone']?.toString() ?? _currentProfile.phone,
      isAvailable: data['isAvailable'] as bool? ?? _currentProfile.isAvailable,
    );
    return _currentProfile;
  }

  Future<BabysitterModel> register(Map<String, dynamic> data) async {
    try {
      final res = await _client.post('babysitters/register', body: data);
      if (res is Map<String, dynamic>) {
        _currentProfile = BabysitterModel.fromJson(res);
        return _currentProfile;
      }
    } catch (_) {
      // Fallback
    }
    _currentProfile = BabysitterModel(
      id: 'sitter-new',
      userId: 'user-new',
      name: '${data['firstName'] ?? 'Maya'} ${data['lastName'] ?? 'Johnson'}',
      email: data['email']?.toString() ?? 'new.sitter@example.com',
      phone: data['phone']?.toString() ?? '',
      address: data['address']?.toString() ?? '',
      bio: data['bio']?.toString() ?? '',
      hourlyRate: (data['hourlyRate'] as num?)?.toDouble() ?? 25.0,
      experienceYears: (data['experienceYears'] as num?)?.toInt() ?? 2,
      skills: (data['skills'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      languages: (data['languages'] as List?)?.map((e) => e.toString()).toList() ?? const ['English'],
      qualifications: (data['qualifications'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      verificationStatus: 'pending',
    );
    return _currentProfile;
  }

  Future<bool> toggleAvailability(bool isAvailable) async {
    try {
      await _client.patch('babysitters/me', body: {'isAvailable': isAvailable});
    } catch (_) {
      // Fallback
    }
    _currentProfile = _currentProfile.copyWith(isAvailable: isAvailable);
    return isAvailable;
  }

  Future<Map<String, dynamic>> getDashboardData() async {
    try {
      final res = await _client.get('babysitters/me/dashboard');
      if (res is Map<String, dynamic>) {
        return res;
      }
    } catch (_) {
      // Fallback
    }

    final newRequests = _mockBookings.where((b) => b.isPending).toList();
    final upcoming = _mockBookings.where((b) => b.isAccepted || b.isInProgress).toList();

    return {
      'profile': _currentProfile.toJson(),
      'isAvailable': _currentProfile.isAvailable,
      'stats': {
        'totalEarnings': 1850.0,
        'rating': _currentProfile.averageRating,
        'completedBookings': _currentProfile.totalCompletedBookings,
      },
      'upcomingBooking': upcoming.isNotEmpty ? upcoming.first.toJson() : null,
      'newRequests': newRequests.map((b) => b.toJson()).toList(),
      'unreadNotificationsCount': _mockNotifications.where((n) => n['isRead'] == false).length,
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
    } catch (_) {
      // Fallback
    }
    return List.from(_mockAvailabilities);
  }

  Future<AvailabilityModel> addAvailability(AvailabilityModel slot) async {
    try {
      final res = await _client.post('babysitters/me/availability', body: slot.toJson());
      if (res is Map<String, dynamic>) {
        return AvailabilityModel.fromJson(res);
      }
    } catch (_) {
      // Fallback
    }
    final newSlot = slot.copyWith(id: 'av-${DateTime.now().millisecondsSinceEpoch}');
    _mockAvailabilities.add(newSlot);
    return newSlot;
  }

  Future<AvailabilityModel> updateAvailability(String id, AvailabilityModel slot) async {
    try {
      final res = await _client.patch('availability/$id', body: slot.toJson());
      if (res is Map<String, dynamic>) {
        return AvailabilityModel.fromJson(res);
      }
    } catch (_) {
      // Fallback
    }
    final index = _mockAvailabilities.indexWhere((a) => a.id == id);
    if (index != -1) {
      _mockAvailabilities[index] = slot;
    }
    return slot;
  }

  Future<bool> deleteAvailability(String id) async {
    try {
      await _client.delete('availability/$id');
    } catch (_) {
      // Fallback
    }
    _mockAvailabilities.removeWhere((a) => a.id == id);
    return true;
  }

  Future<List<BookingRequestModel>> getBookings({String? status}) async {
    try {
      final res = await _client.get(
        'babysitters/me/bookings',
        queryParams: status != null ? {'status': status} : null,
      );
      if (res is List) {
        return res
            .whereType<Map<String, dynamic>>()
            .map(BookingRequestModel.fromJson)
            .toList();
      }
    } catch (_) {
      // Fallback
    }
    if (status == null || status == 'all') {
      return List.from(_mockBookings);
    }
    return _mockBookings.where((b) => b.status == status).toList();
  }

  Future<BookingRequestModel> getBookingDetails(String id) async {
    try {
      final res = await _client.get('bookings/$id');
      if (res is Map<String, dynamic>) {
        return BookingRequestModel.fromJson(res);
      }
    } catch (_) {
      // Fallback
    }
    return _mockBookings.firstWhere(
      (b) => b.id == id,
      orElse: () => _mockBookings.first,
    );
  }

  Future<BookingRequestModel> acceptBooking(String id) async {
    try {
      final res = await _client.patch('bookings/$id/accept');
      if (res is Map<String, dynamic>) {
        return BookingRequestModel.fromJson(res);
      }
    } catch (_) {
      // Fallback
    }
    final index = _mockBookings.indexWhere((b) => b.id == id);
    if (index != -1) {
      final updated = _mockBookings[index].copyWith(status: 'accepted');
      _mockBookings[index] = updated;
      return updated;
    }
    throw Exception('Booking not found');
  }

  Future<BookingRequestModel> rejectBooking(String id, {String? reason}) async {
    try {
      final res = await _client.patch('bookings/$id/reject', body: {'reason': reason});
      if (res is Map<String, dynamic>) {
        return BookingRequestModel.fromJson(res);
      }
    } catch (_) {
      // Fallback
    }
    final index = _mockBookings.indexWhere((b) => b.id == id);
    if (index != -1) {
      final updated = _mockBookings[index].copyWith(status: 'rejected');
      _mockBookings[index] = updated;
      return updated;
    }
    throw Exception('Booking not found');
  }

  Future<BookingRequestModel> updateJobStatus(String id, String newStatus) async {
    try {
      final res = await _client.patch('bookings/$id/status', body: {'status': newStatus});
      if (res is Map<String, dynamic>) {
        return BookingRequestModel.fromJson(res);
      }
    } catch (_) {
      // Fallback
    }
    final index = _mockBookings.indexWhere((b) => b.id == id);
    if (index != -1) {
      final updated = _mockBookings[index].copyWith(status: newStatus);
      _mockBookings[index] = updated;
      return updated;
    }
    throw Exception('Booking not found');
  }

  Future<EarningSummaryModel> getEarnings({String range = 'weekly'}) async {
    try {
      final res = await _client.get('babysitters/me/earnings', queryParams: {'range': range});
      if (res is Map<String, dynamic>) {
        return EarningSummaryModel.fromJson(res);
      }
    } catch (_) {
      // Fallback
    }
    final recent = _mockBookings
        .where((b) => b.status == 'completed')
        .map((b) => EarningItemModel(
              id: 'earn-${b.id}',
              bookingId: b.bookingId,
              parentName: b.parentName,
              date: b.date,
              durationHours: b.durationHours,
              hourlyRate: b.hourlyRate,
              netAmount: b.totalAmount,
              status: 'paid',
            ))
        .toList();
    return EarningSummaryModel(recentEarnings: recent);
  }

  Future<List<Map<String, dynamic>>> getNotifications() async {
    try {
      final res = await _client.get('notifications');
      if (res is List) {
        return res.whereType<Map<String, dynamic>>().toList();
      }
    } catch (_) {
      // Fallback
    }
    return List.from(_mockNotifications);
  }

  Future<bool> markNotificationRead(String id) async {
    try {
      await _client.patch('notifications/$id/read');
    } catch (_) {
      // Fallback
    }
    final index = _mockNotifications.indexWhere((n) => n['id'] == id);
    if (index != -1) {
      _mockNotifications[index]['isRead'] = true;
    }
    return true;
  }

  Future<bool> markAllNotificationsRead() async {
    try {
      await _client.patch('notifications/read-all');
    } catch (_) {
      // Fallback
    }
    for (var n in _mockNotifications) {
      n['isRead'] = true;
    }
    return true;
  }
}
