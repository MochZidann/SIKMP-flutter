import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../core/services/api_http.dart' as http;
import '../core/config/api_config.dart';
import '../models/member.dart';

class MemberService {
  static final MemberService _instance = MemberService._internal();
  factory MemberService() => _instance;
  MemberService._internal();

  String get baseUrl => ApiConfig.membersUrl;

  /// Mengambil daftar seluruh anggota koperasi (mendukung filter pencarian nama/telepon/alamat)
  Future<List<Member>> getMembers({String? search}) async {
    try {
      final uri = Uri.parse(baseUrl).replace(queryParameters: {
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      });

      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final dynamic decoded = json.decode(response.body);
        final dynamic dataList = decoded is Map && decoded['data'] != null ? decoded['data'] : decoded;
        if (dataList is List) {
          return dataList.map((item) => Member.fromJson(item)).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('MemberService getMembers error: $e');
      return [];
    }
  }

  /// Detail anggota beserta ringkasan statistik poin dan riwayat ledger
  Future<Map<String, dynamic>?> getMemberDetail(int id) async {
    try {
      final uri = Uri.parse('$baseUrl/$id');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] is Map<String, dynamic>) {
          return data['data'] as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      debugPrint('MemberService getMemberDetail error: $e');
      return null;
    }
  }

  /// Ambil riwayat ledger poin anggota
  Future<Map<String, dynamic>> getMemberLedgers(int id, {int page = 1, int perPage = 20}) async {
    try {
      final uri = Uri.parse('$baseUrl/$id/ledgers').replace(queryParameters: {
        'page': page.toString(),
        'per_page': perPage.toString(),
      });

      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return {
            'success': true,
            'data': data['data'] as List? ?? [],
            'meta': data['meta'] as Map<String, dynamic>? ?? {},
            'summary': data['summary'] as Map<String, dynamic>? ?? {},
          };
        }
      }
      return {'success': false, 'data': [], 'meta': {}, 'summary': {}};
    } catch (e) {
      debugPrint('MemberService getMemberLedgers error: $e');
      return {'success': false, 'data': [], 'meta': {}, 'summary': {}};
    }
  }

  /// Penyesuaian manual poin anggota dengan integritas ledger & alasan
  Future<Map<String, dynamic>> adjustPoints(
    int id, {
    required int amount,
    required String reason,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/$id/adjust-points');
      final body = {
        'amount': amount,
        'reason': reason.trim(),
      };

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
        return {
          'success': true,
          'message': data['message'] ?? 'Poin berhasil disesuaikan',
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal menyesuaikan poin',
        };
      }
    } catch (e) {
      debugPrint('MemberService adjustPoints error: $e');
      return {
        'success': false,
        'message': 'Gagal terhubung ke server: $e',
      };
    }
  }

  /// Menambahkan anggota baru (tanpa input nomor anggota / status, otomatis dibuatkan sistem)
  Future<Map<String, dynamic>> createMember({
    required String name,
    String? phone,
    String? address,
    int points = 0,
  }) async {
    try {
      final uri = Uri.parse(baseUrl);
      final body = {
        'name': name.trim(),
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
        if (address != null && address.trim().isNotEmpty) 'address': address.trim(),
        'points': points,
      };

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      ).timeout(const Duration(seconds: 10));

      final data = json.decode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'] ?? 'Anggota berhasil ditambahkan',
          'member': data['data'] != null ? Member.fromJson(data['data']) : null,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal menambahkan anggota',
        };
      }
    } catch (e) {
      debugPrint('MemberService createMember error: $e');
      return {
        'success': false,
        'message': 'Gagal terhubung ke server: $e',
      };
    }
  }

  /// Memperbarui data profil dan poin anggota
  Future<Map<String, dynamic>> updateMember(
    int id, {
    required String name,
    String? phone,
    String? address,
    int? points,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/$id');
      final Map<String, dynamic> body = {
        'name': name.trim(),
      };
      if (phone != null) body['phone'] = phone.trim();
      if (address != null) body['address'] = address.trim();

      final response = await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      ).timeout(const Duration(seconds: 10));

      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        if (points != null && data['data'] != null) {
          final int currentPts = data['data']['points'] is int
              ? (data['data']['points'] as int)
              : (int.tryParse(data['data']['points']?.toString() ?? '0') ?? 0);
          final int diff = points - currentPts;
          if (diff != 0) {
            await adjustPoints(id, amount: diff, reason: 'Perubahan poin dari form edit anggota');
          }
        }

        return {
          'success': true,
          'message': data['message'] ?? 'Data anggota berhasil diperbarui',
          'member': data['data'] != null ? Member.fromJson(data['data']) : null,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal memperbarui data anggota',
        };
      }
    } catch (e) {
      debugPrint('MemberService updateMember error: $e');
      return {
        'success': false,
        'message': 'Gagal terhubung ke server: $e',
      };
    }
  }

  /// Menghapus anggota dari sistem
  Future<Map<String, dynamic>> deleteMember(int id) async {
    try {
      final uri = Uri.parse('$baseUrl/$id');
      final response = await http.delete(uri).timeout(const Duration(seconds: 10));

      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Anggota berhasil dihapus',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal menghapus anggota',
        };
      }
    } catch (e) {
      debugPrint('MemberService deleteMember error: $e');
      return {
        'success': false,
        'message': 'Gagal terhubung ke server: $e',
      };
    }
  }
}

