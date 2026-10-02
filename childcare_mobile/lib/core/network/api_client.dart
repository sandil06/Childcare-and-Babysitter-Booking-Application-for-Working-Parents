import 'dart:convert';
import 'dart:io';

import 'api_exception.dart';

class ApiClient {
  ApiClient({String? baseUrl}) : baseUrl = baseUrl ?? defaultBaseUrl;

  static const String defaultBaseUrl = 'http://localhost:4000/api/v1';
  final String baseUrl;
  static String? authToken;

  final HttpClient _httpClient = HttpClient()
    ..connectionTimeout = const Duration(seconds: 10);

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (authToken != null && authToken!.isNotEmpty)
          'Authorization': 'Bearer $authToken',
      };

  Uri _resolveUri(String path, [Map<String, dynamic>? queryParams]) {
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    final fullUrl = '$baseUrl/$cleanPath';
    final uri = Uri.parse(fullUrl);
    if (queryParams != null && queryParams.isNotEmpty) {
      final stringParams = queryParams.map(
        (key, value) => MapEntry(key, value.toString()),
      );
      return uri.replace(queryParameters: stringParams);
    }
    return uri;
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? queryParams}) async {
    try {
      final uri = _resolveUri(path, queryParams);
      final request = await _httpClient.getUrl(uri);
      _headers.forEach((k, v) => request.headers.set(k, v));
      final response = await request.close();
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  Future<dynamic> post(String path, {dynamic body}) async {
    try {
      final uri = _resolveUri(path);
      final request = await _httpClient.postUrl(uri);
      _headers.forEach((k, v) => request.headers.set(k, v));
      if (body != null) {
        request.write(jsonEncode(body));
      }
      final response = await request.close();
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  Future<dynamic> patch(String path, {dynamic body}) async {
    try {
      final uri = _resolveUri(path);
      final request = await _httpClient.patchUrl(uri);
      _headers.forEach((k, v) => request.headers.set(k, v));
      if (body != null) {
        request.write(jsonEncode(body));
      }
      final response = await request.close();
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  Future<dynamic> delete(String path) async {
    try {
      final uri = _resolveUri(path);
      final request = await _httpClient.deleteUrl(uri);
      _headers.forEach((k, v) => request.headers.set(k, v));
      final response = await request.close();
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  Future<dynamic> _handleResponse(HttpClientResponse response) async {
    final bodyString = await response.transform(utf8.decoder).join();
    dynamic decoded;
    if (bodyString.isNotEmpty) {
      try {
        decoded = jsonDecode(bodyString);
      } catch (_) {
        decoded = bodyString;
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
        return decoded['data'];
      }
      return decoded;
    }

    final message = (decoded is Map<String, dynamic> && decoded['message'] != null)
        ? decoded['message'].toString()
        : 'Request failed with status: ${response.statusCode}';
    throw ApiException(message);
  }
}
