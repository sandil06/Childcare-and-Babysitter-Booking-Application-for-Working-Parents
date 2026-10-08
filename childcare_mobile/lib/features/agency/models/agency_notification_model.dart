class AgencyNotificationModel {
  final String id;
  final String title;
  final String message;
  final String type;
  final String category;
  final String targetAudience;
  final String priority;
  final bool isRead;
  final DateTime? createdAt;
  final Map<String, dynamic> data;

  const AgencyNotificationModel({
    required this.id,
    required this.title,
    required this.message,
    this.type = 'system',
    this.category = 'system',
    this.targetAudience = 'all',
    this.priority = 'normal',
    this.isRead = false,
    this.createdAt,
    this.data = const {},
  });

  factory AgencyNotificationModel.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type']?.toString() ?? 'system';
    String computedCategory = json['category']?.toString() ?? 'system';

    if (json['category'] == null || json['category'].toString().isEmpty) {
      if (typeStr.startsWith('verification_')) {
        computedCategory = 'verification';
      } else if (typeStr == 'safety_report' ||
          typeStr == 'high_priority_complaint' ||
          typeStr == 'report_escalated') {
        computedCategory = 'safety';
      } else {
        computedCategory = 'system';
      }
    }

    final rawData = json['data'];
    final dataMap = rawData is Map
        ? Map<String, dynamic>.from(rawData)
        : <String, dynamic>{};

    return AgencyNotificationModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'System Alert',
      message: json['message']?.toString() ?? '',
      type: typeStr,
      category: computedCategory,
      targetAudience: json['targetAudience']?.toString() ??
          dataMap['targetAudience']?.toString() ??
          'all',
      priority: json['priority']?.toString() ??
          dataMap['priority']?.toString() ??
          'normal',
      isRead: json['isRead'] == true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      data: dataMap,
    );
  }

  bool get isUrgent => priority == 'urgent' || priority == 'high';
  bool get isVerification => category == 'verification';
  bool get isSafety => category == 'safety';
}
