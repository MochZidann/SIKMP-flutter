import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/config/api_config.dart';
import '../models/cashier_shift_model.dart';
import 'auth_service.dart';

class OwnerShiftService {
  static final OwnerShiftService _instance = OwnerShiftService._internal();
  factory OwnerShiftService() => _instance;
  OwnerShiftService._internal();

  String get _baseUrl => '${ApiConfig.ownerUrl}/shifts';

  /// Mengambil daftar riwayat shift kasir & ringkasan rekonsiliasi
  Future<Map<String, dynamic>> getShifts({
    String? status,
    String? search,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (status != null && status != 'all' && status.isNotEmpty) {
        queryParams['status'] = status;
      }
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }

      final uri = Uri.parse(_baseUrl).replace(queryParameters: queryParams.isEmpty ? null : queryParams);
      final response = await http.get(uri).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded['success'] == true) {
          final rawData = decoded['data'] as List? ?? [];
          final shifts = rawData.map((item) => CashierShiftModel.fromJson(item as Map<String, dynamic>)).toList();
          final kpis = decoded['kpis'] as Map<String, dynamic>? ?? {};

          return {
            'success': true,
            'shifts': shifts,
            'kpis': kpis,
          };
        }
      }

      return {
        'success': false,
        'shifts': <CashierShiftModel>[],
        'kpis': <String, dynamic>{},
        'message': 'Gagal memuat riwayat shift kasir',
      };
    } catch (e) {
      debugPrint('OwnerShiftService getShifts error: $e');
      return {
        'success': false,
        'shifts': <CashierShiftModel>[],
        'kpis': <String, dynamic>{},
        'message': 'Koneksi gagal: $e',
      };
    }
  }

  /// Mengambil detail lengkap shift kasir (termasuk mutasi kas masuk/keluar dan log audit)
  Future<Map<String, dynamic>> getShiftDetail(int id) async {
    try {
      final uri = Uri.parse('$_baseUrl/$id');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded['success'] == true) {
          return {
            'success': true,
            'data': decoded['data'],
          };
        }
      }
      return {
        'success': false,
        'message': 'Gagal mengambil detail shift kasir',
      };
    } catch (e) {
      debugPrint('OwnerShiftService getShiftDetail error: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  /// Review & Verifikasi Shift Kasir oleh Owner (Setujui atau Minta Hitung Ulang)
  Future<Map<String, dynamic>> reviewShift(
    int id, {
    required String decision, // 'approve' | 'recount'
    String? reviewNote,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/$id/review');
      final userId = AuthService().currentUser?.id ?? 1;

      final body = {
        'decision': decision,
        'review_note': reviewNote,
        'user_id': userId,
      };

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(body),
      ).timeout(const Duration(seconds: 10));

      final decoded = json.decode(response.body);

      if (response.statusCode == 200 && decoded['success'] == true) {
        return {
          'success': true,
          'message': decoded['message'] ?? 'Status shift kasir berhasil diperbarui.',
          'status': decoded['status'],
        };
      } else {
        return {
          'success': false,
          'message': decoded['message'] ?? 'Gagal memverifikasi shift.',
        };
      }
    } catch (e) {
      debugPrint('OwnerShiftService reviewShift error: $e');
      return {
        'success': false,
        'message': 'Koneksi ke server gagal: $e',
      };
    }
  }
}

