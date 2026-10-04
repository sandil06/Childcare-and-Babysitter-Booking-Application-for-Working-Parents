class ChildInfo {
  const ChildInfo({
    required this.name,
    required this.age,
    this.gender,
    this.notes,
  });

  final String name;
  final int age;
  final String? gender;
  final String? notes;

  factory ChildInfo.fromJson(Map<String, dynamic> json) {
    return ChildInfo(
      name: json['name']?.toString() ?? 'Child',
      age: (json['age'] as num?)?.toInt() ?? 3,
      gender: json['gender']?.toString(),
      notes: json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'age': age,
        'gender': gender,
        'notes': notes,
      };
}

class BookingRequestModel {
  const BookingRequestModel({
    required this.id,
    required this.bookingId,
    required this.parentId,
    required this.parentName,
    this.parentImage,
    this.parentPhone = '+94 77 234 5678',
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.durationHours,
    required this.location,
    this.childCount = 1,
    this.childrenDetails = const [],
    this.specialNotes,
    required this.totalAmount,
    this.hourlyRate = 1500.0,
    this.status = 'pending',
    this.paymentStatus = 'paid',
    this.createdAt,
  });

  final String id;
  final String bookingId;
  final String parentId;
  final String parentName;
  final String? parentImage;
  final String parentPhone;
  final DateTime date;
  final String startTime;
  final String endTime;
  final double durationHours;
  final String location;
  final int childCount;
  final List<ChildInfo> childrenDetails;
  final String? specialNotes;
  final double totalAmount;
  final double hourlyRate;
  final String status;
  final String paymentStatus;
  final DateTime? createdAt;

  String get timeFormatted => '$startTime - $endTime';

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted' || status == 'confirmed';
  bool get isInProgress =>
      status == 'travelling' || status == 'arrived' || status == 'in_progress';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled' || status == 'rejected';

  String get nextStatusActionLabel {
    switch (status) {
      case 'accepted':
      case 'confirmed':
        return 'Start Travelling';
      case 'travelling':
        return 'Mark as Arrived';
      case 'arrived':
        return 'Start Service';
      case 'in_progress':
        return 'Complete Service';
      default:
        return '';
    }
  }

  String? get nextStatusTarget {
    switch (status) {
      case 'accepted':
      case 'confirmed':
        return 'travelling';
      case 'travelling':
        return 'arrived';
      case 'arrived':
        return 'in_progress';
      case 'in_progress':
        return 'completed';
      default:
        return null;
    }
  }

  factory BookingRequestModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    if (json['date'] != null) {
      parsedDate = DateTime.tryParse(json['date'].toString()) ?? DateTime.now();
    } else if (json['startAt'] != null) {
      parsedDate = DateTime.tryParse(json['startAt'].toString()) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    String start = json['startTime']?.toString() ?? '14:00';
    String end = json['endTime']?.toString() ?? '18:00';

    if (json['startAt'] != null && json['startTime'] == null) {
      final s = DateTime.tryParse(json['startAt'].toString());
      if (s != null) {
        start = '${s.hour.toString().padLeft(2, '0')}:${s.minute.toString().padLeft(2, '0')}';
      }
    }
    if (json['endAt'] != null && json['endTime'] == null) {
      final e = DateTime.tryParse(json['endAt'].toString());
      if (e != null) {
        end = '${e.hour.toString().padLeft(2, '0')}:${e.minute.toString().padLeft(2, '0')}';
      }
    }

    var rawChildren = json['children'] ?? json['childrenDetails'];
    List<ChildInfo> children = [];
    if (rawChildren is List) {
      children = rawChildren
          .whereType<Map<String, dynamic>>()
          .map(ChildInfo.fromJson)
          .toList();
    }

    final total = (json['total'] as num?)?.toDouble() ??
        (json['totalAmount'] as num?)?.toDouble() ??
        100.0;
    final rate = (json['hourlyRate'] as num?)?.toDouble() ?? 25.0;
    final duration = (json['durationHours'] as num?)?.toDouble() ??
        (json['duration'] as num?)?.toDouble() ??
        (total / (rate > 0 ? rate : 25.0));

    return BookingRequestModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      bookingId: json['bookingId']?.toString() ??
          (json['_id'] != null ? '#${json['_id'].toString().substring(0, 6).toUpperCase()}' : '#BK-1082'),
      parentId: json['parent'] is Map
          ? (json['parent']['_id']?.toString() ?? '')
          : (json['parent']?.toString() ?? json['parentId']?.toString() ?? ''),
      parentName: json['parent'] is Map && json['parent']['name'] != null
          ? json['parent']['name'].toString()
          : (json['parentName']?.toString() ?? 'Anusha Jayasinghe'),
      parentImage: json['parent'] is Map ? json['parent']['avatar']?.toString() : json['parentImage']?.toString(),
      parentPhone: json['parentPhone']?.toString() ?? '+94 77 234 5678',
      date: DateTime(parsedDate.year, parsedDate.month, parsedDate.day),
      startTime: start,
      endTime: end,
      durationHours: duration,
      location: json['location']?.toString() ?? json['address']?.toString() ?? 'No. 24, Havelock Road, Colombo 05',
      childCount: (json['childCount'] as num?)?.toInt() ?? (children.isNotEmpty ? children.length : 1),
      childrenDetails: children,
      specialNotes: json['specialNotes']?.toString() ?? json['notes']?.toString(),
      totalAmount: total,
      hourlyRate: rate,
      status: json['status']?.toString() ?? 'pending',
      paymentStatus: json['paymentStatus']?.toString() ?? 'paid',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'bookingId': bookingId,
        'parentId': parentId,
        'parentName': parentName,
        'parentImage': parentImage,
        'parentPhone': parentPhone,
        'date': date.toIso8601String().split('T').first,
        'startTime': startTime,
        'endTime': endTime,
        'durationHours': durationHours,
        'location': location,
        'childCount': childCount,
        'childrenDetails': childrenDetails.map((e) => e.toJson()).toList(),
        'specialNotes': specialNotes,
        'totalAmount': totalAmount,
        'hourlyRate': hourlyRate,
        'status': status,
        'paymentStatus': paymentStatus,
      };

  BookingRequestModel copyWith({
    String? id,
    String? bookingId,
    String? parentId,
    String? parentName,
    String? parentImage,
    String? parentPhone,
    DateTime? date,
    String? startTime,
    String? endTime,
    double? durationHours,
    String? location,
    int? childCount,
    List<ChildInfo>? childrenDetails,
    String? specialNotes,
    double? totalAmount,
    double? hourlyRate,
    String? status,
    String? paymentStatus,
    DateTime? createdAt,
  }) {
    return BookingRequestModel(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      parentId: parentId ?? this.parentId,
      parentName: parentName ?? this.parentName,
      parentImage: parentImage ?? this.parentImage,
      parentPhone: parentPhone ?? this.parentPhone,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationHours: durationHours ?? this.durationHours,
      location: location ?? this.location,
      childCount: childCount ?? this.childCount,
      childrenDetails: childrenDetails ?? this.childrenDetails,
      specialNotes: specialNotes ?? this.specialNotes,
      totalAmount: totalAmount ?? this.totalAmount,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
