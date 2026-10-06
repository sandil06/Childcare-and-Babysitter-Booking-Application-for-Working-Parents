import 'package:flutter/material.dart';

class ReportModel {
  final String id;
  final String reporterId;
  final String reporterName;
  final String reporterEmail;
  final String reporterRole;
  final String reportedUserId;
  final String reportedUserName;
  final String reportedUserEmail;
  final String reportedUserRole;
  final String? bookingId;
  final String category;
  final String description;
  final List<String> evidence;
  final String status;
  final String priority;
  final String? assignedTo;
  final String resolutionNotes;
  final String? resolvedBy;
  final DateTime? resolvedAt;
  final DateTime? createdAt;

  const ReportModel({
    required this.id,
    required this.reporterId,
    required this.reporterName,
    this.reporterEmail = '',
    this.reporterRole = 'parent',
    required this.reportedUserId,
    required this.reportedUserName,
    this.reportedUserEmail = '',
    this.reportedUserRole = 'babysitter',
    this.bookingId,
    required this.category,
    required this.description,
    this.evidence = const [],
    this.status = 'open',
    this.priority = 'medium',
    this.assignedTo,
    this.resolutionNotes = '',
    this.resolvedBy,
    this.resolvedAt,
    this.createdAt,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    final reporter = json['reporter'] is Map ? json['reporter'] as Map : null;
    final reported = json['reportedUser'] is Map
        ? json['reportedUser'] as Map
        : (json['subject'] is Map ? json['subject'] as Map : null);
    final booking = json['booking'] is Map ? json['booking'] as Map : null;

    final repId = reporter?['_id']?.toString() ??
        reporter?['id']?.toString() ??
        json['reporterId']?.toString() ??
        json['reporter']?.toString() ??
        '';

    final repName = reporter?['name']?.toString() ??
        json['reporterName']?.toString() ??
        'Reporter';

    final targetId = reported?['_id']?.toString() ??
        reported?['id']?.toString() ??
        json['reportedUserId']?.toString() ??
        json['reportedUser']?.toString() ??
        json['subject']?.toString() ??
        '';

    final targetName = reported?['name']?.toString() ??
        json['reportedUserName']?.toString() ??
        'Reported User';

    return ReportModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      reporterId: repId,
      reporterName: repName,
      reporterEmail: reporter?['email']?.toString() ?? json['reporterEmail']?.toString() ?? '',
      reporterRole: reporter?['role']?.toString() ?? json['reporterRole']?.toString() ?? 'parent',
      reportedUserId: targetId,
      reportedUserName: targetName,
      reportedUserEmail: reported?['email']?.toString() ?? json['reportedUserEmail']?.toString() ?? '',
      reportedUserRole: reported?['role']?.toString() ?? json['reportedUserRole']?.toString() ?? 'babysitter',
      bookingId: booking?['_id']?.toString() ?? booking?['id']?.toString() ?? json['bookingId']?.toString() ?? json['booking']?.toString(),
      category: json['category']?.toString() ?? 'Safety',
      description: json['description']?.toString() ?? json['reason']?.toString() ?? '',
      evidence: (json['evidence'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      status: json['status']?.toString() ?? 'open',
      priority: json['priority']?.toString() ?? 'medium',
      assignedTo: json['assignedTo']?.toString(),
      resolutionNotes: json['resolutionNotes']?.toString() ?? '',
      resolvedBy: json['resolvedBy']?.toString(),
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.tryParse(json['resolvedAt'].toString())
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  bool get isOpen => status.toLowerCase() == 'open';
  bool get isUnderReview => status.toLowerCase() == 'under_review';
  bool get isResolved => status.toLowerCase() == 'resolved';
  bool get isDismissed => status.toLowerCase() == 'dismissed';

  Color get priorityColor {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return const Color(0xFFDC2626); // Red 600
      case 'high':
        return const Color(0xFFEA580C); // Orange 600
      case 'medium':
        return const Color(0xFFD97706); // Amber 600
      case 'low':
      default:
        return const Color(0xFF0284C7); // Sky 600
    }
  }

  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'open':
        return const Color(0xFFEF4444);
      case 'under_review':
        return const Color(0xFFF59E0B);
      case 'resolved':
        return const Color(0xFF10B981);
      case 'dismissed':
      default:
        return const Color(0xFF6B7280);
    }
  }
}
