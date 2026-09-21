import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/utils/password_helper.dart';
import '../models/audit_log.dart';
import '../models/auth_user.dart';
import '../models/member.dart';
import '../models/store_setting.dart';
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

  String get adminBaseUrl {
    final base = PosService.baseUrl;
    if (base.endsWith('/pos')) {
      return '${base.substring(0, base.length - 4)}/admin';
    }
    return '$base/admin';
  }

  // ── PENGGUNA (USERS) ──────────────────────────────────────────

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

  /// Mengubah status aktif/non-aktif user dengan audit trail & proteksi self-lockout
  Future<Map<String, dynamic>> toggleUserStatus(int userId, {int? adminId}) async {
    try {
      final uri = Uri.parse('$adminBaseUrl/users/$userId/toggle-status');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'admin_id': adminId}),
      ).timeout(const Duration(seconds: 8));

      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Status berhasil diubah',
          'isActive': data['isActive'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal mengubah status pengguna',
        };
      }
    } catch (e) {
      debugPrint('AdminService toggleUserStatus error: $e');
      return {
        'success': false,
        'message': 'Koneksi ke server bermasalah: $e',
      };
    }
  }

  /// Reset kata sandi pengguna ke default (atau password baru)
  Future<Map<String, dynamic>> resetUserPassword(
    int userId, {
    String password = 'password123',
    int? adminId,
  }) async {
    try {
      final uri = Uri.parse('$adminBaseUrl/users/$userId/reset-password');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'password': password,
          'admin_id': adminId,
        }),
      ).timeout(const Duration(seconds: 8));

      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Password berhasil di-reset',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal me-reset password',
        };
      }
    } catch (e) {
      debugPrint('AdminService resetUserPassword error: $e');
      return {
        'success': false,
        'message': 'Gagal terhubung ke server: $e',
      };
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

  // ── ANGGOTA & AUDIT LOGS ─────────────────────────────────────

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

  // ── DASHBOARD AGREGAT TINGGI (PERFORMANCE-OPTIMIZED) ──────────

  /// Mengambil ringkasan dashboard sistem secara instan via 1 round-trip SQL aggregate
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final uri = Uri.parse('$adminBaseUrl/dashboard');
      final response = await http.get(uri).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final jsonResp = json.decode(response.body);
        if (jsonResp['success'] == true && jsonResp['data'] != null) {
          final data = jsonResp['data'];
          final recentLogsRaw = data['recentLogs'] as List? ?? [];
          return {
            'totalUsers': data['totalUsers'] ?? 0,
            'activeUsers': data['activeUsers'] ?? 0,
            'totalMembers': data['totalMembers'] ?? 0,
            'totalProducts': data['totalProducts'] ?? 0,
            'totalLogs': data['totalLogs'] ?? 0,
            'totalDatabaseRows': data['totalDatabaseRows'] ?? 0,
            'serverStatus': data['serverStatus'] ?? 'ONLINE',
            'recentLogs': recentLogsRaw.map((e) => AuditLog.fromJson(e)).toList(),
          };
        }
      }
      // Fallback jika endpoint belum sinkron
      return await getSystemStats();
    } catch (e) {
      debugPrint('AdminService getDashboardStats error (falling back): $e');
      return await getSystemStats();
    }
  }

  /// Fallback statistik manual jika endpoint agregat tidak tersedia
  Future<Map<String, dynamic>> getSystemStats() async {
    try {
      final usersFuture = getUsers();
      final membersFuture = getMembers();
      final logsFuture = getAuditLogs();

      final results = await Future.wait([usersFuture, membersFuture, logsFuture]);
      final users = results[0] as List<AuthUser>;
      final members = results[1] as List<Member>;
      final logs = results[2] as List<AuditLog>;

      final activeUsersCount = users.where((u) => u.isActive).length;
      final membersCount = members.length;
      final logsCount = logs.length;

      return {
        'totalUsers': users.length,
        'activeUsers': activeUsersCount,
        'totalMembers': membersCount,
        'totalProducts': 0,
        'totalLogs': logsCount,
        'totalDatabaseRows': users.length + membersCount + logsCount,
        'recentLogs': logs.take(6).toList(),
        'serverStatus': 'ONLINE',
      };
    } catch (e) {
      debugPrint('AdminService getSystemStats error: $e');
      return {
        'totalUsers': 0,
        'activeUsers': 0,
        'totalMembers': 0,
        'totalProducts': 0,
        'totalLogs': 0,
        'totalDatabaseRows': 0,
        'recentLogs': <AuditLog>[],
        'serverStatus': 'OFFLINE',
      };
    }
  }

  // ── PENGATURAN TOKO / STRUK ───────────────────────────────────

  /// Mengambil profil dan pengaturan identitas koperasi / struk
  Future<StoreSetting?> getStoreSettings() async {
    try {
      final uri = Uri.parse('$adminBaseUrl/settings');
      final response = await http.get(uri).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return StoreSetting.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      debugPrint('AdminService getStoreSettings error: $e');
      return null;
    }
  }

  /// Memperbarui informasi profil koperasi & footer struk
  Future<Map<String, dynamic>> updateStoreSettings(StoreSetting setting, {int? adminId}) async {
    try {
      final uri = Uri.parse('$adminBaseUrl/settings');
      final payload = {
        'koperasiName': setting.koperasiName,
        'koperasiAddress': setting.koperasiAddress,
        'koperasiPhone': setting.koperasiPhone,
        'taxPercent': setting.taxPercent,
        'discountPercent': setting.discountPercent,
        'admin_id': adminId,
      };

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      ).timeout(const Duration(seconds: 8));

      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Pengaturan berhasil disimpan',
          'data': data['data'] != null ? StoreSetting.fromJson(data['data']) : null,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal menyimpan pengaturan',
        };
      }
    } catch (e) {
      debugPrint('AdminService updateStoreSettings error: $e');
      return {
        'success': false,
        'message': 'Koneksi ke server bermasalah: $e',
      };
    }
  }

  // ── KESEHATAN DATABASE & CACHE SERVER ─────────────────────────

  /// Mengambil data status dan rincian volume tabel database
  Future<Map<String, dynamic>?> getDatabaseHealth() async {
    try {
      final uri = Uri.parse('$adminBaseUrl/database-health');
      final response = await http.get(uri).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return data['data'] as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      debugPrint('AdminService getDatabaseHealth error: $e');
      return null;
    }
  }

  /// Membersihkan cache server Laravel
  Future<Map<String, dynamic>> clearServerCache({int? adminId}) async {
    try {
      final uri = Uri.parse('$adminBaseUrl/clear-cache');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'admin_id': adminId}),
      ).timeout(const Duration(seconds: 10));

      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Cache server berhasil dibersihkan',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal membersihkan cache server',
        };
      }
    } catch (e) {
      debugPrint('AdminService clearServerCache error: $e');
      return {
        'success': false,
        'message': 'Koneksi ke server bermasalah: $e',
      };
    }
  }
}
