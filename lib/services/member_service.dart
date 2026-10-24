import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
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
      if (points != null) body['points'] = points;

      final response = await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      ).timeout(const Duration(seconds: 10));

      final data = json.decode(response.body);
      if (response.statusCode == 200) {
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
