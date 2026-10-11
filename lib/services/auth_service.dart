import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/config/api_config.dart';
import '../models/auth_user.dart';
import 'fcm_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  AuthUser? currentUser;

  bool get isLoggedIn => currentUser != null;

  String get authBaseUrl => ApiConfig.authUrl;

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
        try {
          await FcmService().subscribeToRole(currentUser!.role);
        } catch (_) {}
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
    try {
      await FcmService().unsubscribeAllRoleTopics();
    } catch (_) {}
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
