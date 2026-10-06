import 'verification_request_model.dart';
import 'report_model.dart';

class AgencyDashboardModel {
  final int totalUsers;
  final int totalParents;
  final int totalBabysitters;
  final int verifiedBabysitters;
  final int pendingVerifications;
  final int rejectedVerifications;
  final int totalBookings;
  final int activeBookings;
  final int completedBookings;
  final int cancelledBookings;
  final int openComplaints;
  final int resolvedComplaints;

  final List<VerificationRequestModel> recentVerifications;
  final List<ReportModel> recentComplaints;
  final List<Map<String, dynamic>> recentBookings;
  final List<Map<String, dynamic>> systemActivities;

  const AgencyDashboardModel({
    this.totalUsers = 0,
    this.totalParents = 0,
    this.totalBabysitters = 0,
    this.verifiedBabysitters = 0,
    this.pendingVerifications = 0,
    this.rejectedVerifications = 0,
    this.totalBookings = 0,
    this.activeBookings = 0,
    this.completedBookings = 0,
    this.cancelledBookings = 0,
    this.openComplaints = 0,
    this.resolvedComplaints = 0,
    this.recentVerifications = const [],
    this.recentComplaints = const [],
    this.recentBookings = const [],
    this.systemActivities = const [],
  });

  factory AgencyDashboardModel.fromJson(Map<String, dynamic> json) {
    final stats = json['stats'] is Map ? json['stats'] as Map : json;

    final verificationsList = (json['recentVerifications'] as List?)
            ?.map((e) => VerificationRequestModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList() ??
        const [];

    final complaintsList = (json['recentComplaints'] as List?)
            ?.map((e) => ReportModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList() ??
        const [];

    final bookingsList = (json['recentBookings'] as List?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        const [];

    final activitiesList = (json['systemActivities'] as List?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        const [];

    return AgencyDashboardModel(
      totalUsers: _toInt(stats['totalUsers']),
      totalParents: _toInt(stats['totalParents']),
      totalBabysitters: _toInt(stats['totalBabysitters']),
      verifiedBabysitters: _toInt(stats['verifiedBabysitters']),
      pendingVerifications: _toInt(stats['pendingVerifications']),
      rejectedVerifications: _toInt(stats['rejectedVerifications']),
      totalBookings: _toInt(stats['totalBookings']),
      activeBookings: _toInt(stats['activeBookings']),
      completedBookings: _toInt(stats['completedBookings']),
      cancelledBookings: _toInt(stats['cancelledBookings']),
      openComplaints: _toInt(stats['openComplaints']),
      resolvedComplaints: _toInt(stats['resolvedComplaints']),
      recentVerifications: verificationsList,
      recentComplaints: complaintsList,
      recentBookings: bookingsList,
      systemActivities: activitiesList,
    );
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }
}
