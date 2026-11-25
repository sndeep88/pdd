import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, [this.statusCode = 400]);

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  static const String baseUrl = 'https://paddyusdt.com/api/mobile';
  static const _tokenKey = 'paddyusdt_auth_token';
  static const _userKey = 'paddyusdt_user_json';

  String? _token;
  Map<String, dynamic>? _cachedUser;
  VoidCallback? onUnauthorized;

  bool get isLoggedIn => _token != null && _token!.isNotEmpty;
  Map<String, dynamic>? get cachedUser => _cachedUser;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    final userRaw = prefs.getString(_userKey);
    if (userRaw != null && userRaw.isNotEmpty) {
      try {
        _cachedUser = jsonDecode(userRaw) as Map<String, dynamic>;
      } catch (_) {}
    }
  }

  Future<void> saveSession(String token, Map<String, dynamic> user) async {
    _token = token;
    _cachedUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(user));
  }

  Future<void> clearSession() async {
    _token = null;
    _cachedUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  String _platformLabel() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.android:
        return 'android';
      default:
        return 'desktop';
    }
  }

  Map<String, String> _headers() {
    final h = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-Platform': _platformLabel(),
    };
    if (_token != null && _token!.isNotEmpty) {
      h['Authorization'] = 'Bearer $_token';
      h['X-Auth-Token'] = _token!;
    }
    return h;
  }

  Future<Map<String, dynamic>> get(String endpoint) async {
    final uri = Uri.parse('$baseUrl/$endpoint');
    final resp = await http
        .get(uri, headers: _headers())
        .timeout(const Duration(seconds: 25));
    return _handleResponse(resp);
  }

  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse('$baseUrl/$endpoint');
    final resp = await http
        .post(uri, headers: _headers(), body: jsonEncode(body))
        .timeout(const Duration(seconds: 30));
    return _handleResponse(resp);
  }

  Map<String, dynamic> _handleResponse(http.Response resp) {
    Map<String, dynamic> data;
    try {
      final decoded = jsonDecode(resp.body);
      data = decoded is Map<String, dynamic>
          ? decoded
          : {'ok': false, 'error': 'Unexpected server response.'};
    } catch (_) {
      throw ApiException(
        'Server returned an invalid response (HTTP ${resp.statusCode}).',
        resp.statusCode,
      );
    }

    if (resp.statusCode == 401) {
      clearSession();
      onUnauthorized?.call();
      throw ApiException(
        (data['error'] ?? 'Session expired. Please sign in again.').toString(),
        401,
      );
    }

    if (resp.statusCode >= 400 && data['ok'] != true) {
      throw ApiException(
        (data['error'] ?? 'Request failed (${resp.statusCode}).').toString(),
        resp.statusCode,
      );
    }

    return data;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final data = await post('login', {
      'email': email.trim(),
      'password': password,
      'platform': _platformLabel(),
    });
    if (data['ok'] == true && data['needs_2fa'] != true && data['token'] != null) {
      await saveSession(
        data['token'].toString(),
        (data['user'] as Map<String, dynamic>? ?? {}),
      );
    }
    return data;
  }

  Future<Map<String, dynamic>> verify2fa(String challengeToken, String code) async {
    final data = await post('verify-2fa', {
      'challenge_token': challengeToken,
      'code': code.trim(),
      'platform': _platformLabel(),
    });
    if (data['ok'] == true && data['token'] != null) {
      await saveSession(
        data['token'].toString(),
        (data['user'] as Map<String, dynamic>? ?? {}),
      );
    }
    return data;
  }

  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String phone,
    required String city,
    required String country,
    required String password,
  }) async {
    final data = await post('register', {
      'full_name': fullName.trim(),
      'email': email.trim(),
      'phone': phone.trim(),
      'city': city.trim(),
      'country': country.trim(),
      'password': password,
      'platform': _platformLabel(),
    });
    if (data['ok'] == true && data['token'] != null) {
      await saveSession(
        data['token'].toString(),
        (data['user'] as Map<String, dynamic>? ?? {}),
      );
    }
    return data;
  }

  Future<void> logout() async {
    try {
      await post('logout', {});
    } catch (_) {}
    await clearSession();
  }
}
