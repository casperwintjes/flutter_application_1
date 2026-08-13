import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_service.dart';

class HaApiService {
  HaApiService({http.Client? client, AuthService? authService})
      : _client = client ?? http.Client(),
        _authService = authService ?? AuthService();

  final http.Client _client;
  final AuthService _authService;

  Future<Map<String, dynamic>> loadDocument() async {
    final uri = Uri.parse(_buildUrl('/api/shopping_storage'));
    final response = await _client.get(
      uri,
      headers: _headers(),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return {};
      }
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    return {};
  }

  Future<void> saveDocument(Map<String, dynamic> document) async {
    final uri = Uri.parse(_buildUrl('/api/shopping_storage'));
    await _client.post(
      uri,
      headers: _headers(),
      body: jsonEncode(document),
    );
  }

  Map<String, String> _headers() {
    final headers = <String, String>{'Content-Type': 'application/json'};
    final authHeader = _authService.getAuthHeader();
    if (authHeader != null && authHeader.isNotEmpty) {
      headers['Authorization'] = authHeader;
    }
    return headers;
  }

  String _buildUrl(String path) {
    final configuredBaseUrl = _authService.getBaseUrl();
    if (configuredBaseUrl != null && configuredBaseUrl.isNotEmpty) {
      return configuredBaseUrl.replaceAll(RegExp(r'/+$'), '') + path;
    }
    return path;
  }
}
