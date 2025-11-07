import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ApiClient {
  ApiClient({http.Client? client, String? baseUrl, this.getAuthToken})
      : _client = client ?? http.Client(),
        _baseUrl = _normalizeBaseForPlatform(
          baseUrl ?? const String.fromEnvironment(
            'API_BASE_URL',
            defaultValue: 'http://localhost:5000',
          ),
        );

  final http.Client _client;
  final String _baseUrl;
  final Future<String?> Function()? getAuthToken;

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final p = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$_baseUrl$p').replace(
      queryParameters: query?.map((k, v) => MapEntry(k, '$v')),
    );
  }

  Future<Map<String, String>> _headers([Map<String, String>? extra]) async {
    final token = getAuthToken == null ? null : await getAuthToken!.call();
    final base = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
    if (extra != null && extra.isNotEmpty) base.addAll(extra);
    return base;
  }

  Future<dynamic> getJson(String path,
      {Map<String, dynamic>? query, Map<String, String>? headers}) async {
    final resp = await _client
        .get(_uri(path, query), headers: await _headers(headers))
        .timeout(const Duration(seconds: 10));
    _logResponse(resp);
    _ensureSuccess(resp);
    return _decode(resp);
  }

  Future<dynamic> postJson(String path,
      {Object? body, Map<String, String>? headers}) async {
    final resp = await _client
        .post(_uri(path),
            headers: await _headers(headers),
            body: body == null ? null : jsonEncode(body))
        .timeout(const Duration(seconds: 10));
    _logResponse(resp);
    _ensureSuccess(resp);
    return _decode(resp);
  }

  Future<dynamic> putJson(String path,
      {Object? body, Map<String, String>? headers}) async {
    final resp = await _client
        .put(_uri(path),
            headers: await _headers(headers),
            body: body == null ? null : jsonEncode(body))
        .timeout(const Duration(seconds: 10));
    _logResponse(resp);
    _ensureSuccess(resp);
    return _decode(resp);
  }

  Future<void> delete(String path, {Map<String, String>? headers}) async {
    final resp = await _client
        .delete(_uri(path), headers: await _headers(headers))
        .timeout(const Duration(seconds: 10));
    _logResponse(resp);
    _ensureSuccess(resp);
  }

  dynamic _decode(http.Response resp) {
    if (resp.body.isEmpty) return null;
    try {
      final decoded = jsonDecode(resp.body);
      // Check for API-level errors (success: false)
      if (decoded is Map && decoded['success'] == false) {
        throw ApiException(
          decoded['message'] ?? 'API request failed',
          body: resp.body,
        );
      }
      return decoded;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Invalid JSON response', body: resp.body);
    }
  }

  void _ensureSuccess(http.Response resp) {
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      // Try to extract error message from response body
      String errorMsg = 'HTTP ${resp.statusCode}';
      try {
        final json = jsonDecode(resp.body);
        if (json is Map && json.containsKey('message')) {
          errorMsg = json['message'];
        }
      } catch (_) {
        // If JSON parsing fails, use default error message
      }
      throw ApiException(errorMsg, body: resp.body);
    }
  }

  void _logResponse(http.Response resp) {
    debugPrint('➡️ ${resp.request?.method} ${resp.request?.url}');
    debugPrint('⬅️ ${resp.statusCode} ${resp.body}');
  }
}

class ApiException implements Exception {
  final String message;
  final String? body;
  ApiException(this.message, {this.body});
  @override
  String toString() => 'ApiException: $message${body == null ? '' : ' => $body'}';
}

String _normalizeBaseForPlatform(String raw) {
  final stripped = raw.replaceAll(RegExp(r"/+$"), '');
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    try {
      final u = Uri.parse(stripped);
      if (u.host == 'localhost' || u.host == '127.0.0.1') {
        final port = u.hasPort ? ':${u.port}' : '';
        final scheme = u.scheme.isEmpty ? 'http' : u.scheme;
        return '$scheme://10.0.2.2$port';
      }
    } catch (_) {}
  }
  return stripped;
}
