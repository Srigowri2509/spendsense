import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ApiClient {
  ApiClient({http.Client? client, String? baseUrl, this.getAuthToken})
      : _client = client ?? http.Client(),
        _baseUrl = _normalizeBaseForPlatform(
          baseUrl ?? const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:3000'),
        );

  final http.Client _client;
  final String _baseUrl;
  final Future<String?> Function()? getAuthToken;

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final p = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$_baseUrl$p').replace(queryParameters: query?.map((k, v) => MapEntry(k, '$v')));
  }

  Future<Map<String, String>> _headers([Map<String, String>? extra]) async {
    final token = getAuthToken == null ? null : await getAuthToken!.call();
    final base = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
    if (extra == null || extra.isEmpty) return base;
    final merged = Map<String, String>.from(base);
    merged.addAll(extra);
    return merged;
  }

  Future<dynamic> getJson(String path, {Map<String, dynamic>? query, Map<String, String>? headers}) async {
    final resp = await _client.get(_uri(path, query), headers: await _headers(headers));
    _ensureSuccess(resp);
    return _decode(resp);
  }

  Future<dynamic> postJson(String path, {Object? body, Map<String, String>? headers}) async {
    final resp = await _client.post(_uri(path), headers: await _headers(headers), body: body == null ? null : jsonEncode(body));
    _ensureSuccess(resp);
    return _decode(resp);
  }

  Future<dynamic> putJson(String path, {Object? body, Map<String, String>? headers}) async {
    final resp = await _client.put(_uri(path), headers: await _headers(headers), body: body == null ? null : jsonEncode(body));
    _ensureSuccess(resp);
    return _decode(resp);
  }

  Future<void> delete(String path, {Map<String, String>? headers}) async {
    final resp = await _client.delete(_uri(path), headers: await _headers(headers));
    _ensureSuccess(resp);
  }

  dynamic _decode(http.Response resp) {
    if (resp.body.isEmpty) return null;
    return jsonDecode(resp.body);
  }

  void _ensureSuccess(http.Response resp) {
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw ApiException('HTTP ${resp.statusCode}', body: resp.body);
    }
  }
}

class ApiException implements Exception {
  final String message;
  final String? body;
  ApiException(this.message, {this.body});
  @override
  String toString() => 'ApiException: $message${body == null ? '' : ' => $body'}';
}

String _stripTrailingSlash(String url) {
  return url.replaceAll(RegExp(r"/+\$"), '');
}

String _normalizeBaseForPlatform(String raw) {
  final stripped = _stripTrailingSlash(raw);
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    try {
      final u = Uri.parse(stripped);
      if (u.host == 'localhost' || u.host == '127.0.0.1') {
        final port = u.hasPort ? ':${u.port}' : '';
        final scheme = u.scheme.isEmpty ? 'http' : u.scheme;
        return _stripTrailingSlash('$scheme://10.0.2.2$port');
      }
    } catch (_) {
      // ignore
    }
  }
  return stripped;
}


