import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class BookingChildModel {
  final String name;
  final int age;
  final String? gender;
  final String? notes;

  const BookingChildModel({
    required this.name,
    required this.age,
    this.gender,
    this.notes,
  });

  factory BookingChildModel.fromJson(Map<String, dynamic> json) {
    return BookingChildModel(
      name: json['name']?.toString() ?? '',
      age: int.tryParse(json['age']?.toString() ?? '0') ?? 0,
      gender: json['gender']?.toString(),
      notes: json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'age': age,
    if (gender != null) 'gender': gender,
    if (notes != null) 'notes': notes,
  };
}

class BookingRescheduleModel {
  final DateTime? oldDate;
  final String oldStartTime;
  final String oldEndTime;
  final DateTime? newDate;
  final String newStartTime;
  final String newEndTime;
  final DateTime? requestedAt;

  const BookingRescheduleModel({
    this.oldDate,
    required this.oldStartTime,
    required this.oldEndTime,
    this.newDate,
    required this.newStartTime,
    required this.newEndTime,
    this.requestedAt,
  });

  factory BookingRescheduleModel.fromJson(Map<String, dynamic> json) {
    return BookingRescheduleModel(
      oldDate: json['oldDate'] != null ? DateTime.tryParse(json['oldDate'].toString()) : null,
      oldStartTime: json['oldStartTime']?.toString() ?? '',
      oldEndTime: json['oldEndTime']?.toString() ?? '',
      newDate: json['newDate'] != null ? DateTime.tryParse(json['newDate'].toString()) : null,
      newStartTime: json['newStartTime']?.toString() ?? '',
      newEndTime: json['newEndTime']?.toString() ?? '',
      requestedAt: json['requestedAt'] != null ? DateTime.tryParse(json['requestedAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    if (oldDate != null) 'oldDate': oldDate!.toIso8601String(),
    'oldStartTime': oldStartTime,
    'oldEndTime': oldEndTime,
    if (newDate != null) 'newDate': newDate!.toIso8601String(),
    'newStartTime': newStartTime,
    'newEndTime': newEndTime,
    if (requestedAt != null) 'requestedAt': requestedAt!.toIso8601String(),
  };
}

class BookingModel {
  final String id;
  final String bookingId;
  final String parentId;
  final String parentName;
  final String parentEmail;
  final String parentPhone;
  final String parentAvatar;
  final String babysitterId;
  final String babysitterName;
  final String babysitterEmail;
  final String babysitterPhone;
  final String babysitterAvatar;
  final double babysitterRating;
  final DateTime date;
  final String startTime;
  final String endTime;
  final double durationHours;
  final double hourlyRate;
  final double subtotal;
  final double serviceFee;
  final double total;
  final double totalAmount;
  final String location;
  final double latitude;
  final double longitude;
  final List<BookingChildModel> children;
  final String specialNotes;
  final String status;
  final String paymentStatus;
  final String? paymentIntentId;
  final String? cancellationReason;
  final String? cancelledBy;
  final DateTime? cancelledAt;
  final String? rejectionReason;
  final List<BookingRescheduleModel> rescheduleHistory;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const BookingModel({
    required this.id,
    required this.bookingId,
    required this.parentId,
    this.parentName = 'Parent',
    this.parentEmail = '',
    this.parentPhone = '',
    this.parentAvatar = '',
    required this.babysitterId,
    this.babysitterName = 'Caregiver',
    this.babysitterEmail = '',
    this.babysitterPhone = '',
    this.babysitterAvatar = '',
    this.babysitterRating = 5.0,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.durationHours = 4.0,
    this.hourlyRate = 1500.0,
    this.subtotal = 6000.0,
    this.serviceFee = 0.0,
    this.total = 6000.0,
    this.totalAmount = 6000.0,
    this.location = 'Colombo, Sri Lanka',
    this.latitude = 6.9271,
    this.longitude = 79.8612,
    this.children = const [],
    this.specialNotes = '',
    this.status = 'pending',
    this.paymentStatus = 'pending',
    this.paymentIntentId,
    this.cancellationReason,
    this.cancelledBy,
    this.cancelledAt,
    this.rejectionReason,
    this.rescheduleHistory = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    // Parent parsing
    String pId = '';
    String pName = 'Parent';
    String pEmail = '';
    String pPhone = '';
    String pAvatar = '';
    if (json['parent'] is Map) {
      final p = json['parent'] as Map;
      pId = p['_id']?.toString() ?? p['id']?.toString() ?? '';
      pName = p['name']?.toString() ?? 'Parent';
      pEmail = p['email']?.toString() ?? '';
      pPhone = p['phone']?.toString() ?? '';
      pAvatar = p['avatar']?.toString() ?? '';
    } else {
      pId = json['parent']?.toString() ?? json['parentId']?.toString() ?? '';
      pName = json['parentName']?.toString() ?? 'Parent';
    }

    // Babysitter parsing
    String bId = '';
    String bName = 'Caregiver';
    String bEmail = '';
    String bPhone = '';
    String bAvatar = '';
    double bRating = 5.0;
    if (json['babysitter'] is Map) {
      final b = json['babysitter'] as Map;
      bId = b['_id']?.toString() ?? b['id']?.toString() ?? '';
      bName = b['name']?.toString() ?? 'Caregiver';
      bEmail = b['email']?.toString() ?? '';
      bPhone = b['phone']?.toString() ?? '';
      bAvatar = b['avatar']?.toString() ?? '';
      bRating = double.tryParse(b['rating']?.toString() ?? '5.0') ?? 5.0;
    } else {
      bId = json['babysitter']?.toString() ?? json['babysitterId']?.toString() ?? '';
      bName = json['babysitterName']?.toString() ?? 'Caregiver';
    }

    // Children parsing
    final childrenList = <BookingChildModel>[];
    if (json['children'] is List) {
      for (final item in json['children'] as List) {
        if (item is Map) {
          childrenList.add(BookingChildModel.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    // Reschedule history
    final reschedules = <BookingRescheduleModel>[];
    if (json['rescheduleHistory'] is List) {
      for (final item in json['rescheduleHistory'] as List) {
        if (item is Map) {
          reschedules.add(BookingRescheduleModel.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    DateTime parsedDate = DateTime.now();
    if (json['date'] != null) {
      parsedDate = DateTime.tryParse(json['date'].toString()) ?? DateTime.now();
    } else if (json['startAt'] != null) {
      parsedDate = DateTime.tryParse(json['startAt'].toString()) ?? DateTime.now();
    }

    final sTime = json['startTime']?.toString() ?? '09:00';
    final eTime = json['endTime']?.toString() ?? '13:00';
    double duration = double.tryParse(json['durationHours']?.toString() ?? json['duration']?.toString() ?? '') ?? 0.0;
    if (duration <= 0) {
      duration = calculateDuration(sTime, eTime);
    }
    final rate = double.tryParse(json['hourlyRate']?.toString() ?? '1500.0') ?? 1500.0;
    double sub = double.tryParse(json['subtotal']?.toString() ?? '') ?? 0.0;
    if (sub <= 0) {
      sub = duration * rate;
    }
    final fee = double.tryParse(json['serviceFee']?.toString() ?? '0.0') ?? 0.0;
    double tot = double.tryParse(json['totalAmount']?.toString() ?? json['total']?.toString() ?? '') ?? 0.0;
    if (tot <= 0) {
      tot = sub + fee;
    }

    return BookingModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      bookingId: json['bookingId']?.toString() ?? '#BK-${json['_id']?.toString().substring(0, 4) ?? '1001'}',
      parentId: pId,
      parentName: pName,
      parentEmail: pEmail,
      parentPhone: pPhone,
      parentAvatar: pAvatar,
      babysitterId: bId,
      babysitterName: bName,
      babysitterEmail: bEmail,
      babysitterPhone: bPhone,
      babysitterAvatar: bAvatar,
      babysitterRating: bRating,
      date: parsedDate,
      startTime: json['startTime']?.toString() ?? '09:00',
      endTime: json['endTime']?.toString() ?? '13:00',
      durationHours: duration,
      hourlyRate: rate,
      subtotal: sub,
      serviceFee: fee,
      total: tot,
      totalAmount: tot,
      location: json['location']?.toString() ?? json['address']?.toString() ?? 'Colombo, Sri Lanka',
      latitude: double.tryParse(json['latitude']?.toString() ?? '6.9271') ?? 6.9271,
      longitude: double.tryParse(json['longitude']?.toString() ?? '79.8612') ?? 79.8612,
      children: childrenList,
      specialNotes: json['specialNotes']?.toString() ?? json['notes']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      paymentStatus: json['paymentStatus']?.toString() ?? 'pending',
      paymentIntentId: json['paymentIntentId']?.toString(),
      cancellationReason: json['cancellationReason']?.toString(),
      cancelledBy: json['cancelledBy']?.toString(),
      cancelledAt: json['cancelledAt'] != null ? DateTime.tryParse(json['cancelledAt'].toString()) : null,
      rejectionReason: json['rejectionReason']?.toString(),
      rescheduleHistory: reschedules,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'bookingId': bookingId,
    'parent': parentId,
    'babysitter': babysitterId,
    'date': date.toIso8601String(),
    'startTime': startTime,
    'endTime': endTime,
    'durationHours': durationHours,
    'hourlyRate': hourlyRate,
    'subtotal': subtotal,
    'serviceFee': serviceFee,
    'total': total,
    'totalAmount': totalAmount,
    'location': location,
    'latitude': latitude,
    'longitude': longitude,
    'children': children.map((c) => c.toJson()).toList(),
    'specialNotes': specialNotes,
    'status': status,
    'paymentStatus': paymentStatus,
    if (paymentIntentId != null) 'paymentIntentId': paymentIntentId,
    if (cancellationReason != null) 'cancellationReason': cancellationReason,
    if (rejectionReason != null) 'rejectionReason': rejectionReason,
  };

  BookingModel copyWith({
    String? id,
    String? bookingId,
    String? parentId,
    String? parentName,
    String? babysitterId,
    String? babysitterName,
    DateTime? date,
    String? startTime,
    String? endTime,
    double? durationHours,
    double? hourlyRate,
    double? subtotal,
    double? serviceFee,
    double? total,
    double? totalAmount,
    String? location,
    double? latitude,
    double? longitude,
    List<BookingChildModel>? children,
    String? specialNotes,
    String? status,
    String? paymentStatus,
    String? paymentIntentId,
    String? cancellationReason,
    List<BookingRescheduleModel>? rescheduleHistory,
  }) {
    return BookingModel(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      parentId: parentId ?? this.parentId,
      parentName: parentName ?? this.parentName,
      parentEmail: parentEmail,
      parentPhone: parentPhone,
      parentAvatar: parentAvatar,
      babysitterId: babysitterId ?? this.babysitterId,
      babysitterName: babysitterName ?? this.babysitterName,
      babysitterEmail: babysitterEmail,
      babysitterPhone: babysitterPhone,
      babysitterAvatar: babysitterAvatar,
      babysitterRating: babysitterRating,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationHours: durationHours ?? this.durationHours,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      subtotal: subtotal ?? this.subtotal,
      serviceFee: serviceFee ?? this.serviceFee,
      total: total ?? this.total,
      totalAmount: totalAmount ?? this.totalAmount,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      children: children ?? this.children,
      specialNotes: specialNotes ?? this.specialNotes,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentIntentId: paymentIntentId ?? this.paymentIntentId,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      cancelledBy: cancelledBy,
      cancelledAt: cancelledAt,
      rejectionReason: rejectionReason,
      rescheduleHistory: rescheduleHistory ?? this.rescheduleHistory,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // UI Helpers
  String get displayBookingId =>
      bookingId.isNotEmpty ? bookingId : (id.isNotEmpty ? id : 'BK-849204');

  String get formattedDate {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String get timeRange => '$startTime – $endTime';

  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'accepted':
      case 'confirmed':
        return AppColors.teal;
      case 'travelling':
      case 'arrived':
      case 'in_progress':
        return const Color(0xFF0284C7);
      case 'completed':
        return const Color(0xFF059669);
      case 'cancelled':
      case 'rejected':
        return AppColors.coral;
      case 'pending':
      default:
        return const Color(0xFFD97706);
    }
  }

  String get formattedStatus {
    switch (status.toLowerCase()) {
      case 'in_progress':
        return 'In Progress';
      default:
        if (status.isEmpty) return 'Pending';
        return status[0].toUpperCase() + status.substring(1);
    }
  }

  bool get canBeCancelled =>
      ['pending', 'accepted', 'confirmed', 'travelling', 'arrived'].contains(status.toLowerCase());

  bool get canBeRescheduled =>
      ['pending', 'accepted', 'confirmed'].contains(status.toLowerCase());

  bool get isLiveTrackingAvailable =>
      ['accepted', 'confirmed', 'travelling', 'arrived', 'in_progress'].contains(status.toLowerCase());

  static int parseTimeToMinutes(String timeStr) {
    if (timeStr.isEmpty) return 0;
    final clean = timeStr.trim().toUpperCase();
    final isPm = clean.contains('PM');
    final isAm = clean.contains('AM');
    final timeOnly = clean.replaceAll('AM', '').replaceAll('PM', '').trim();
    final parts = timeOnly.split(':');
    if (parts.isEmpty) return 0;
    int h = int.tryParse(parts[0].trim()) ?? 0;
    int m = 0;
    if (parts.length > 1) {
      m = int.tryParse(parts[1].trim()) ?? 0;
    }
    if (isPm && h < 12) {
      h += 12;
    } else if (isAm && h == 12) {
      h = 0;
    }
    return h * 60 + m;
  }

  static double calculateDuration(String startTime, String endTime) {
    final startM = parseTimeToMinutes(startTime);
    final endM = parseTimeToMinutes(endTime);
    if (endM > startM) {
      final diffM = endM - startM;
      return (diffM / 60.0 * 10).round() / 10.0;
    }
    return 4.0;
  }
}
