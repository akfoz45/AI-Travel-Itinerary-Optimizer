import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../storage/token_storage.dart';

class ApiClient {
  final TokenStorage _tokenStorage = TokenStorage();

  Uri _buildUri(String endpoint){
    return Uri.parse('${ApiConstants.baseUrl}$endpoint');
  }

  Future<Map<String, String>> _headers({
    bool requiresAuth = false,
  }) async {
    final headers = <String, String>{
      'Content-Type': "application/json",
    };

    if (requiresAuth){
      final accessToken = await _tokenStorage.getAccessToken();

      if (accessToken != null){
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

  dynamic _handleResponse(http.Response response) {
    final decodedBody = response.body.isNotEmpty
        ? jsonDecode(response.body)
        : null;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decodedBody;
    }

    throw Exception(
      'API Error ${response.statusCode}: ${response.body}',
    );
  }
}