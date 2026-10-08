import '../../../core/network/api_client.dart';
import '../../../core/storage/local_storage.dart';
import '../../babysitter/models/babysitter_model.dart';
import '../models/parent_model.dart';

class ParentService {
  ParentService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<void> _restoreToken() async {
    final token = await LocalStorage.instance.read('auth_token');
    if (token != null && token.toString().isNotEmpty) {
      ApiClient.authToken = token.toString();
    }
  }

  Future<ParentModel> getProfile() async {
    await _restoreToken();
    final response = await _client.get('parents/profile');
    return ParentModel.fromJson(Map<String, dynamic>.from(response as Map));
  }

  Future<ParentModel> updateProfile(Map<String, dynamic> data) async {
    await _restoreToken();
    final response = await _client.patch('parents/profile', body: data);
    return ParentModel.fromJson(Map<String, dynamic>.from(response as Map));
  }

  Future<List<BabysitterModel>> searchBabysitters({
    String search = '',
    double? minHourlyRate,
    double? maxHourlyRate,
    int? minExperience,
    double? minRating,
    bool? isAvailable,
    String? skill,
    String? language,
  }) async {
    final query = <String, dynamic>{'limit': 50};
    if (search.trim().isNotEmpty) query['search'] = search.trim();
    if (minHourlyRate != null) query['minHourlyRate'] = minHourlyRate;
    if (maxHourlyRate != null) query['maxHourlyRate'] = maxHourlyRate;
    if (minExperience != null) query['minExperience'] = minExperience;
    if (minRating != null) query['minRating'] = minRating;
    if (isAvailable != null) query['isAvailable'] = isAvailable;
    if (skill != null && skill.isNotEmpty) query['skill'] = skill;
    if (language != null && language.isNotEmpty) query['language'] = language;

    final response = await _client.get('babysitters', queryParams: query);
    if (response is! List) return [];
    return response
        .whereType<Map>()
        .map(
          (item) => BabysitterModel.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  Future<BabysitterModel> getBabysitter(String id) async {
    final response = await _client.get('babysitters/$id');
    return BabysitterModel.fromJson(Map<String, dynamic>.from(response as Map));
  }

  Future<Map<String, dynamic>?> submitSafetyReport({
    required String reportedUserId,
    required String category,
    required String description,
    String? bookingId,
    String priority = 'medium',
    List<String> evidence = const [],
  }) async {
    await _restoreToken();
    try {
      final payload = <String, dynamic>{
        'reportedUserId': reportedUserId,
        'category': category,
        'description': description,
        'priority': priority,
        'evidence': evidence,
      };
      if (bookingId != null && bookingId.isNotEmpty) {
        payload['bookingId'] = bookingId;
      }
      final response = await _client.post('reports', body: payload);
      if (response is Map && response['data'] != null) {
        return Map<String, dynamic>.from(response['data'] as Map);
      }
    } catch (_) {}
    return null;
  }
}

