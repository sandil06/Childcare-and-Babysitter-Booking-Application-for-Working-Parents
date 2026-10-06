class SystemStatisticsModel {
  // Users
  final int totalUsers;
  final int totalParents;
  final int totalBabysitters;
  final int verifiedBabysitters;
  final int activeUsers;
  final int suspendedUsers;

  // Bookings
  final int totalBookings;
  final int pendingBookings;
  final int activeBookings;
  final int completedBookings;
  final int cancelledBookings;
  final int rejectedBookings;

  // Verifications
  final int pendingVerifications;
  final int underReviewVerifications;
  final int verifiedRequests;
  final int rejectedVerifications;

  // Reports
  final int totalReports;
  final int openReports;
  final int underReviewReports;
  final int resolvedReports;
  final int urgentReports;

  // Payments
  final double totalTransactionVolume;
  final double totalPlatformRevenue;
  final int successfulTransactions;
  final int failedTransactions;

  const SystemStatisticsModel({
    this.totalUsers = 0,
    this.totalParents = 0,
    this.totalBabysitters = 0,
    this.verifiedBabysitters = 0,
    this.activeUsers = 0,
    this.suspendedUsers = 0,
    this.totalBookings = 0,
    this.pendingBookings = 0,
    this.activeBookings = 0,
    this.completedBookings = 0,
    this.cancelledBookings = 0,
    this.rejectedBookings = 0,
    this.pendingVerifications = 0,
    this.underReviewVerifications = 0,
    this.verifiedRequests = 0,
    this.rejectedVerifications = 0,
    this.totalReports = 0,
    this.openReports = 0,
    this.underReviewReports = 0,
    this.resolvedReports = 0,
    this.urgentReports = 0,
    this.totalTransactionVolume = 0.0,
    this.totalPlatformRevenue = 0.0,
    this.successfulTransactions = 0,
    this.failedTransactions = 0,
  });

  factory SystemStatisticsModel.fromJson(Map<String, dynamic> json) {
    final u = json['users'] is Map ? json['users'] as Map : {};
    final b = json['bookings'] is Map ? json['bookings'] as Map : {};
    final v = json['verifications'] is Map ? json['verifications'] as Map : {};
    final r = json['reports'] is Map ? json['reports'] as Map : {};
    final p = json['payments'] is Map ? json['payments'] as Map : {};

    return SystemStatisticsModel(
      totalUsers: _toInt(u['total'] ?? json['totalUsers']),
      totalParents: _toInt(u['parents'] ?? json['totalParents']),
      totalBabysitters: _toInt(u['babysitters'] ?? json['totalBabysitters']),
      verifiedBabysitters: _toInt(u['verified'] ?? json['verifiedBabysitters']),
      activeUsers: _toInt(u['active'] ?? json['activeUsers']),
      suspendedUsers: _toInt(u['suspended'] ?? json['suspendedUsers']),
      totalBookings: _toInt(b['total'] ?? json['totalBookings']),
      pendingBookings: _toInt(b['pending'] ?? json['pendingBookings']),
      activeBookings: _toInt(b['active'] ?? json['activeBookings']),
      completedBookings: _toInt(b['completed'] ?? json['completedBookings']),
      cancelledBookings: _toInt(b['cancelled'] ?? json['cancelledBookings']),
      rejectedBookings: _toInt(b['rejected'] ?? json['rejectedBookings']),
      pendingVerifications: _toInt(v['pending'] ?? json['pendingVerifications']),
      underReviewVerifications: _toInt(v['under_review'] ?? json['underReviewVerifications']),
      verifiedRequests: _toInt(v['verified'] ?? json['verifiedRequests']),
      rejectedVerifications: _toInt(v['rejected'] ?? json['rejectedVerifications']),
      totalReports: _toInt(r['total'] ?? json['totalReports']),
      openReports: _toInt(r['open'] ?? json['openReports']),
      underReviewReports: _toInt(r['under_review'] ?? json['underReviewReports']),
      resolvedReports: _toInt(r['resolved'] ?? json['resolvedReports']),
      urgentReports: _toInt(r['urgent'] ?? json['urgentReports']),
      totalTransactionVolume: _toDouble(p['totalVolume'] ?? json['totalTransactionVolume']),
      totalPlatformRevenue: _toDouble(p['platformRevenue'] ?? json['totalPlatformRevenue']),
      successfulTransactions: _toInt(p['successful'] ?? json['successfulTransactions']),
      failedTransactions: _toInt(p['failed'] ?? json['failedTransactions']),
    );
  }

  static int _toInt(dynamic val) {
    if (val == null) return 0;
    if (val is int) return val;
    return int.tryParse(val.toString()) ?? 0;
  }

  static double _toDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }
}
