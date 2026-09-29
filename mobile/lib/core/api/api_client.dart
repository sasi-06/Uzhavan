import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_exception.dart';

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  String? _token;

  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:3000/api/v1';
    if (Platform.isAndroid) return 'http://10.0.2.2:3000/api/v1';
    return 'http://localhost:3000/api/v1';
  }

  String? get token => _token;
  void setToken(String? token) => _token = token;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<dynamic> get(String path, {Map<String, String>? query}) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    final response = await _client.get(uri, headers: _headers);
    return _handle(response);
  }

  Future<dynamic> post(String path, {Object? body}) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await _client.post(
      uri,
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handle(response);
  }

  Future<dynamic> patch(String path, {Object? body}) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await _client.patch(
      uri,
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handle(response);
  }

  dynamic _handle(http.Response response) {
    dynamic body;
    if (response.body.isNotEmpty) {
      body = jsonDecode(response.body);
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }
    final message = body is Map ? (body['message'] ?? body['error']) : null;
    throw ApiException(
      response.statusCode,
      message is List ? message.join(', ') : message?.toString() ?? 'Request failed',
    );
  }
}
