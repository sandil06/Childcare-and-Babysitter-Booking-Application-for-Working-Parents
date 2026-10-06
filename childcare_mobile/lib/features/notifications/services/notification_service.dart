import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/local_storage.dart';
import '../models/notification_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final ApiClient _client = ApiClient();

  Future<void> _ensureAuthToken() async {
    final token = await LocalStorage.instance.read('auth_token');
    if (token != null && token.toString().isNotEmpty) {
      ApiClient.authToken = token.toString();
    }
  }

  /// Retrieves notifications with optional category filtering
  Future<List<AppNotificationModel>> getNotifications({String? category}) async {
    await _ensureAuthToken();

    try {
      final queryParams = <String, dynamic>{};
      if (category != null && category != 'all') {
        queryParams['category'] = category;
      }

      final res = await _client.get('notifications', queryParams: queryParams);

      if (res is Map && res['data'] is List) {
        return (res['data'] as List)
            .map((item) => AppNotificationModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      } else if (res is List) {
        return res
            .map((item) => AppNotificationModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }
    } catch (e) {
      debugPrint('[NotificationService] getNotifications error: $e');
    }

    return [];
  }

  /// Marks a single notification as read
  Future<void> markNotificationRead(String id) async {
    await _ensureAuthToken();

    try {
      await _client.patch('notifications/$id/read');
    } catch (e) {
      debugPrint('[NotificationService] markNotificationRead error: $e');
    }
  }

  /// Marks all notifications as read
  Future<void> markAllRead() async {
    await _ensureAuthToken();

    try {
      await _client.patch('notifications/read-all');
    } catch (e) {
      debugPrint('[NotificationService] markAllRead error: $e');
    }
  }
}
