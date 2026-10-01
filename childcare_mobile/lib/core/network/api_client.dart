import 'api_exception.dart';

class ApiClient {
  Future<T> get<T>(String path) async =>
      throw const ApiException('API client not configured');
}
