import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/utils/password_helper.dart';
import '../models/audit_log.dart';
import '../models/auth_user.dart';
import '../models/member.dart';
import 'pos_service.dart';

class AdminService {
  static final AdminService _instance = AdminService._internal();
  factory AdminService() => _instance;
  AdminService._internal();

  String get syncBaseUrl {
    final base = PosService.baseUrl;
    if (base.endsWith('/pos')) {
      return '${base.substring(0, base.length - 4)}/sync';
    }
    return '$base/sync';
  }

  /// Mengambil daftar semua user dari server
  Future<List<AuthUser>> getUsers() async {
    try {
      final uri = Uri.parse('$syncBaseUrl/users');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        if (data is List) {
          return data.map((item) => AuthUser.fromJson(item)).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('AdminService getUsers error: $e');
      return [];
    }
  }

  /// Menambahkan akun pengguna baru
  Future<bool> createUser({
    required String name,
    required String username,
    required String password,
    required String role,
  }) async {
    try {
      final salt = PasswordHelper.generateSalt();
      final hash = PasswordHelper.hashPassword(password, salt);

      final uri = Uri.parse('$syncBaseUrl/users');
      final payload = [
        {
          'name': name.trim(),
          'username': username.trim(),
          'passwordHash': hash,
          'salt': salt,
          'role': role,
          'isActive': 1,
          'needsPasswordReset': 0,
          'createdAtEpochMs': DateTime.now().millisecondsSinceEpoch,
        }
      ];

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('AdminService createUser error: $e');
      return false;
    }
  }

  /// Mengubah status aktif/non-aktif user
  Future<bool> toggleUserStatus(AuthUser user, bool isActive) async {
    try {
      final uri = Uri.parse('$syncBaseUrl/users');
      final payload = [
        {
          'id': user.id,
          'username': user.username,
          'name': user.name,
          'role': user.role,
          'isActive': isActive ? 1 : 0,
        }
      ];

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('AdminService toggleUserStatus error: $e');
      return false;
    }
  }

  /// Menghapus user berdasarkan username
  Future<bool> deleteUser(String username) async {
    try {
      final uri = Uri.parse('$syncBaseUrl/users/$username');
      final response = await http.delete(uri).timeout(const Duration(seconds: 8));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('AdminService deleteUser error: $e');
      return false;
    }
  }

  /// Mengambil daftar anggota koperasi
  Future<List<Member>> getMembers() async {
    try {
      final uri = Uri.parse('$syncBaseUrl/members');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        if (data is List) {
          return data.map((item) => Member.fromJson(item)).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('AdminService getMembers error: $e');
      return [];
    }
  }

  /// Mengambil riwayat catatan aktivitas audit log
  Future<List<AuditLog>> getAuditLogs() async {
    try {
      final uri = Uri.parse('$syncBaseUrl/audit-logs');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        if (data is List) {
          final logs = data.map((item) => AuditLog.fromJson(item)).toList();
          // Urutkan dari yang paling baru
          logs.sort((a, b) => (b.createdAtEpochMs ?? 0).compareTo(a.createdAtEpochMs ?? 0));
          return logs;
        }
      }
      return [];
    } catch (e) {
      debugPrint('AdminService getAuditLogs error: $e');
      return [];
    }
  }

  /// Mengambil ringkasan statistik sistem secara efisien
  Future<Map<String, dynamic>> getSystemStats() async {
    try {
      final usersFuture = getUsers();
      final membersFuture = getMembers();
      final logsFuture = getAuditLogs();

      final results = await Future.wait([usersFuture, membersFuture, logsFuture]);
      final users = results[0] as List<AuthUser>;
      final members = results[1] as List<Member>;
      final logs = results[2] as List<AuditLog>;

      final activeUsersCount = users.length;
      final membersCount = members.length;
      final logsCount = logs.length;

      return {
        'totalUsers': users.length,
        'activeUsers': activeUsersCount,
        'totalMembers': membersCount,
        'totalLogs': logsCount,
        'recentLogs': logs.take(5).toList(),
        'serverStatus': 'ONLINE',
      };
    } catch (e) {
      debugPrint('AdminService getSystemStats error: $e');
      return {
        'totalUsers': 0,
        'activeUsers': 0,
        'totalMembers': 0,
        'totalLogs': 0,
        'recentLogs': <AuditLog>[],
        'serverStatus': 'OFFLINE',
      };
    }
  }
}
