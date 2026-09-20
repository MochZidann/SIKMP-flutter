import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/auth_user.dart';
import 'pos_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  AuthUser? currentUser;

  bool get isLoggedIn => currentUser != null;

  String get authBaseUrl {
    // Derive auth base URL from PosService.baseUrl
    // e.g. http://10.0.2.2:8000/api/pos -> http://10.0.2.2:8000/api/auth
    final base = PosService.baseUrl;
    if (base.endsWith('/pos')) {
      return '${base.substring(0, base.length - 4)}/auth';
    }
    return '$base/auth';
  }

  Future<AuthUser> login({
    required String username,
    required String password,
    String? role,
  }) async {
    try {
      final uri = Uri.parse('$authBaseUrl/login');
      final body = {
        'username': username.trim(),
        'password': password,
      };
      if (role != null && role.isNotEmpty) {
        body['role'] = role;
      }

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(body),
      ).timeout(const Duration(seconds: 10));

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final userData = data['data']['user'];
        currentUser = AuthUser.fromJson(userData);
        return currentUser!;
      } else {
        throw Exception(data['message'] ?? 'Login gagal.');
      }
    } catch (e) {
      debugPrint('AuthService login error: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    if (currentUser != null) {
      try {
        final uri = Uri.parse('$authBaseUrl/logout');
        await http.post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: json.encode({'userId': currentUser!.id}),
        ).timeout(const Duration(seconds: 5));
      } catch (e) {
        debugPrint('Logout error: $e');
      }
    }
    currentUser = null;
  }
}
