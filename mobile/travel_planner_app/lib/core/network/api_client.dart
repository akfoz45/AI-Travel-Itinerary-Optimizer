import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../storage/token_storage.dart';

class ApiClient {
  final TokenStorage _tokenStorage = TokenStorage();

  Uri _buildUri(String endpoint) {
    return Uri.parse('${ApiConstants.baseUrl}$endpoint');
  }

  Future<Map<String, String>> _headers({
    bool requiresAuth = false,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requiresAuth) {
      final accessToken = await _tokenStorage.getAccessToken();

      if (accessToken != null && accessToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $accessToken';
      }
    }

    return headers;
  }

  Future<dynamic> get(
    String endpoint, {
    bool requiresAuth = false,
  }) async {
    final response = await http.get(
      _buildUri(endpoint),
      headers: await _headers(requiresAuth: requiresAuth),
    );

    return _handleResponse(response);
  }

  Future<dynamic> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = false,
  }) async {
    final response = await http.post(
      _buildUri(endpoint),
      headers: await _headers(requiresAuth: requiresAuth),
      body: jsonEncode(body ?? {}),
    );

    return _handleResponse(response);
  }

  Future<dynamic> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = false,
  }) async {
    final response = await http.put(
      _buildUri(endpoint),
      headers: await _headers(requiresAuth: requiresAuth),
      body: jsonEncode(body ?? {}),
    );

    return _handleResponse(response);
  }

  Future<dynamic> delete(
    String endpoint, {
    bool requiresAuth = false,
  }) async {
    final response = await http.delete(
      _buildUri(endpoint),
      headers: await _headers(requiresAuth: requiresAuth),
    );

    return _handleResponse(response);
  }

  dynamic _handleResponse(http.Response response) {
    final contentType = response.headers['content-type'] ?? '';

    if (response.body.isEmpty) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return null;
      }

      throw Exception('Request failed. Status code: ${response.statusCode}');
    }

    if (!contentType.contains('application/json')) {
      throw Exception(
        'Server returned an unexpected response. Please try again.',
      );
    }

    final decodedBody = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decodedBody;
    }

    final errorMessage = _extractErrorMessage(
      decodedBody,
      response.statusCode,
    );

    throw Exception(errorMessage);
  }

  String _extractErrorMessage(dynamic decodedBody, int statusCode) {
    if (decodedBody is Map<String, dynamic>) {
      if (decodedBody['error'] != null) {
        return decodedBody['error'].toString();
      }

      if (decodedBody['detail'] != null) {
        return decodedBody['detail'].toString();
      }

      if (decodedBody['message'] != null) {
        return decodedBody['message'].toString();
      }

      final fieldErrors = decodedBody.entries.map((entry) {
        return '${entry.key}: ${entry.value}';
      }).join('\n');

      if (fieldErrors.isNotEmpty) {
        return fieldErrors;
      }
    }

    return 'Request failed. Status code: $statusCode';
  }
}