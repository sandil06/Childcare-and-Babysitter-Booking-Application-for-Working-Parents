import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'api_exception.dart';
import '../storage/local_storage.dart';

class ApiClient {
  ApiClient({String? baseUrl}) : baseUrl = baseUrl ?? defaultBaseUrl;

  static String get defaultBaseUrl {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:4000/api/v1';
    }
    return 'http://localhost:4000/api/v1';
  }

  final String baseUrl;
  static String? authToken;

  final http.Client _httpClient = http.Client();
  static const _responseTimeout = Duration(seconds: 15);

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

  Future<void> _restoreAuthToken() async {
    if (authToken?.isNotEmpty == true) return;
    final storedToken = await LocalStorage.instance.read('auth_token');
    if (storedToken != null && storedToken.toString().isNotEmpty) {
      authToken = storedToken.toString();
    }
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? queryParams}) async {
    try {
      await _restoreAuthToken();
      final uri = _resolveUri(path, queryParams);
      final response = await _httpClient
          .get(uri, headers: _headers)
          .timeout(_responseTimeout);
      return await _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      if (e is TimeoutException) {
        throw const ApiException('Connection timed out. Please check your internet connection.');
      }
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  Future<dynamic> post(String path, {dynamic body}) async {
    try {
      await _restoreAuthToken();
      final uri = _resolveUri(path);
      final response = await _httpClient
          .post(
            uri,
            headers: _headers,
            body: body == null ? null : jsonEncode(body),
          )
          .timeout(_responseTimeout);
      return await _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      if (e is TimeoutException) {
        throw const ApiException('Connection timed out. Please check your internet connection.');
      }
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  Future<dynamic> patch(String path, {dynamic body}) async {
    try {
      await _restoreAuthToken();
      final uri = _resolveUri(path);
      final response = await _httpClient
          .patch(
            uri,
            headers: _headers,
            body: body == null ? null : jsonEncode(body),
          )
          .timeout(_responseTimeout);
      return await _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      if (e is TimeoutException) {
        throw const ApiException('Connection timed out. Please check your internet connection.');
      }
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  Future<dynamic> delete(String path) async {
    try {
      await _restoreAuthToken();
      final uri = _resolveUri(path);
      final response = await _httpClient
          .delete(uri, headers: _headers)
          .timeout(_responseTimeout);
      return await _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      if (e is TimeoutException) {
        throw const ApiException('Connection timed out. Please check your internet connection.');
      }
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  Future<dynamic> _handleResponse(http.Response response) async {
    final bodyString = response.body;
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

    final serverMsg =
        (decoded is Map<String, dynamic> && decoded['message'] != null)
        ? decoded['message'].toString()
        : null;
    final message =
        serverMsg ??
        switch (response.statusCode) {
          401 => 'Session expired. Please log in again.',
          403 => 'You do not have permission to perform this action.',
          404 => 'The requested resource was not found.',
          409 => 'This request conflicts with existing data.',
          422 => 'Please check the entered information.',
          500 => 'Something went wrong on the server.',
          _ => 'Request failed with status: ${response.statusCode}',
        };
    if (response.statusCode == 401) {
      authToken = null;
      await LocalStorage.instance.remove('auth_token');
    }
    throw ApiException(message, statusCode: response.statusCode);
  }
}
