class AvailabilityModel {
  const AvailabilityModel({
    required this.id,
    required this.babysitterId,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.available = true,
    this.isRecurring = false,
    this.repeatDays = const [],
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String babysitterId;
  final DateTime date;
  final String startTime; // e.g. "08:30"
  final String endTime;   // e.g. "16:30"
  final bool available;
  final bool isRecurring;
  final List<int> repeatDays; // 1 = Monday, 7 = Sunday
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get timeRangeLabel => '$startTime - $endTime';

  factory AvailabilityModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    if (json['date'] != null) {
      parsedDate = DateTime.tryParse(json['date'].toString()) ?? DateTime.now();
    } else if (json['startAt'] != null) {
      parsedDate = DateTime.tryParse(json['startAt'].toString()) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    String start = json['startTime']?.toString() ?? '09:00';
    String end = json['endTime']?.toString() ?? '17:00';

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

    return AvailabilityModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      babysitterId: json['babysitter'] is Map
          ? (json['babysitter']['_id']?.toString() ?? '')
          : (json['babysitter']?.toString() ?? json['babysitterId']?.toString() ?? ''),
      date: DateTime(parsedDate.year, parsedDate.month, parsedDate.day),
      startTime: start,
      endTime: end,
      available: json['available'] as bool? ?? json['isAvailable'] as bool? ?? true,
      isRecurring: json['isRecurring'] as bool? ?? false,
      repeatDays: (json['repeatDays'] as List?)?.map((e) => (e as num).toInt()).toList() ?? const [],
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'babysitterId': babysitterId,
        'date': date.toIso8601String().split('T').first,
        'startTime': startTime,
        'endTime': endTime,
        'available': available,
        'isRecurring': isRecurring,
        'repeatDays': repeatDays,
      };

  AvailabilityModel copyWith({
    String? id,
    String? babysitterId,
    DateTime? date,
    String? startTime,
    String? endTime,
    bool? available,
    bool? isRecurring,
    List<int>? repeatDays,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AvailabilityModel(
      id: id ?? this.id,
      babysitterId: babysitterId ?? this.babysitterId,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      available: available ?? this.available,
      isRecurring: isRecurring ?? this.isRecurring,
      repeatDays: repeatDays ?? this.repeatDays,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
