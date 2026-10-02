class DailyEarningPoint {
  const DailyEarningPoint({required this.day, required this.amount});
  final String day;
  final double amount;

  factory DailyEarningPoint.fromJson(Map<String, dynamic> json) {
    return DailyEarningPoint(
      day: json['day']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {'day': day, 'amount': amount};
}

class EarningItemModel {
  const EarningItemModel({
    required this.id,
    required this.bookingId,
    required this.parentName,
    required this.date,
    required this.durationHours,
    required this.hourlyRate,
    this.serviceFee = 0.0,
    required this.netAmount,
    this.status = 'paid',
  });

  final String id;
  final String bookingId;
  final String parentName;
  final DateTime date;
  final double durationHours;
  final double hourlyRate;
  final double serviceFee;
  final double netAmount;
  final String status; // 'paid', 'pending', 'processing'

  factory EarningItemModel.fromJson(Map<String, dynamic> json) {
    return EarningItemModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      bookingId: json['bookingId']?.toString() ?? json['booking']?.toString() ?? '',
      parentName: json['parentName']?.toString() ??
          (json['parent'] is Map ? json['parent']['name']?.toString() ?? 'Parent' : 'Parent'),
      date: json['date'] != null
          ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      durationHours: (json['durationHours'] as num?)?.toDouble() ?? 3.0,
      hourlyRate: (json['hourlyRate'] as num?)?.toDouble() ?? 25.0,
      serviceFee: (json['serviceFee'] as num?)?.toDouble() ?? 0.0,
      netAmount: (json['netAmount'] as num?)?.toDouble() ??
          (json['amount'] as num?)?.toDouble() ??
          75.0,
      status: json['status']?.toString() ?? 'paid',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'bookingId': bookingId,
        'parentName': parentName,
        'date': date.toIso8601String(),
        'durationHours': durationHours,
        'hourlyRate': hourlyRate,
        'serviceFee': serviceFee,
        'netAmount': netAmount,
        'status': status,
      };
}

class EarningSummaryModel {
  const EarningSummaryModel({
    this.totalEarnings = 1850.0,
    this.currentMonthEarnings = 620.0,
    this.weeklyEarnings = 275.0,
    this.completedBookings = 24,
    this.pendingPayout = 125.0,
    this.hourlyRateAverage = 25.0,
    this.weeklyData = const [
      DailyEarningPoint(day: 'Mon', amount: 50.0),
      DailyEarningPoint(day: 'Tue', amount: 75.0),
      DailyEarningPoint(day: 'Wed', amount: 0.0),
      DailyEarningPoint(day: 'Thu', amount: 60.0),
      DailyEarningPoint(day: 'Fri', amount: 90.0),
      DailyEarningPoint(day: 'Sat', amount: 0.0),
      DailyEarningPoint(day: 'Sun', amount: 0.0),
    ],
    this.recentEarnings = const [],
  });

  final double totalEarnings;
  final double currentMonthEarnings;
  final double weeklyEarnings;
  final int completedBookings;
  final double pendingPayout;
  final double hourlyRateAverage;
  final List<DailyEarningPoint> weeklyData;
  final List<EarningItemModel> recentEarnings;

  factory EarningSummaryModel.fromJson(Map<String, dynamic> json) {
    var rawWeekly = json['weeklyData'];
    List<DailyEarningPoint> points = [];
    if (rawWeekly is List) {
      points = rawWeekly
          .whereType<Map<String, dynamic>>()
          .map(DailyEarningPoint.fromJson)
          .toList();
    } else {
      points = const [
        DailyEarningPoint(day: 'Mon', amount: 50.0),
        DailyEarningPoint(day: 'Tue', amount: 75.0),
        DailyEarningPoint(day: 'Wed', amount: 0.0),
        DailyEarningPoint(day: 'Thu', amount: 60.0),
        DailyEarningPoint(day: 'Fri', amount: 90.0),
        DailyEarningPoint(day: 'Sat', amount: 0.0),
        DailyEarningPoint(day: 'Sun', amount: 0.0),
      ];
    }

    var rawRecent = json['recentEarnings'];
    List<EarningItemModel> recent = [];
    if (rawRecent is List) {
      recent = rawRecent
          .whereType<Map<String, dynamic>>()
          .map(EarningItemModel.fromJson)
          .toList();
    }

    return EarningSummaryModel(
      totalEarnings: (json['totalEarnings'] as num?)?.toDouble() ?? 1850.0,
      currentMonthEarnings: (json['currentMonthEarnings'] as num?)?.toDouble() ?? 620.0,
      weeklyEarnings: (json['weeklyEarnings'] as num?)?.toDouble() ?? 275.0,
      completedBookings: (json['completedBookings'] as num?)?.toInt() ?? 24,
      pendingPayout: (json['pendingPayout'] as num?)?.toDouble() ?? 125.0,
      hourlyRateAverage: (json['hourlyRateAverage'] as num?)?.toDouble() ?? 25.0,
      weeklyData: points,
      recentEarnings: recent,
    );
  }

  Map<String, dynamic> toJson() => {
        'totalEarnings': totalEarnings,
        'currentMonthEarnings': currentMonthEarnings,
        'weeklyEarnings': weeklyEarnings,
        'completedBookings': completedBookings,
        'pendingPayout': pendingPayout,
        'hourlyRateAverage': hourlyRateAverage,
        'weeklyData': weeklyData.map((e) => e.toJson()).toList(),
        'recentEarnings': recentEarnings.map((e) => e.toJson()).toList(),
      };
}
