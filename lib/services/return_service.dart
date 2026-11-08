import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/config/api_config.dart';
import '../models/sale_return.dart';
import 'auth_service.dart';

class ReturnService {
  static final ReturnService _instance = ReturnService._internal();
  factory ReturnService() => _instance;
  ReturnService._internal();

  String get _baseUrl => '${ApiConfig.posUrl}/returns';

  /// Mengambil daftar riwayat retur penjualan kasir & KPI metrik
  Future<Map<String, dynamic>> getReturns({
    String? search,
    String? reason,
    String? range,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }
      if (reason != null && reason != 'all' && reason.isNotEmpty) {
        queryParams['reason'] = reason;
      }
      if (range != null && range != 'all' && range.isNotEmpty) {
        queryParams['range'] = range;
      }

      final uri = Uri.parse(_baseUrl).replace(queryParameters: queryParams.isEmpty ? null : queryParams);
      final response = await http.get(uri).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded['success'] == true) {
          final rawData = decoded['data'] as List? ?? [];
          final returns = rawData.map((item) => SaleReturnModel.fromJson(item as Map<String, dynamic>)).toList();
          final kpis = decoded['kpis'] as Map<String, dynamic>? ?? {};

          return {
            'success': true,
            'returns': returns,
            'kpis': kpis,
          };
        }
      }
      return {
        'success': false,
        'returns': <SaleReturnModel>[],
        'kpis': <String, dynamic>{},
        'message': 'Gagal memuat riwayat retur',
      };
    } catch (e) {
      debugPrint('ReturnService getReturns error: $e');
      return {
        'success': false,
        'returns': <SaleReturnModel>[],
        'kpis': <String, dynamic>{},
        'message': 'Koneksi gagal: $e',
      };
    }
  }

  /// Mencari transaksi nota penjualan untuk retur berdasarkan No. Transaksi atau scan barcode nota
  Future<Map<String, dynamic>> searchSale(String query) async {
    try {
      final uri = Uri.parse('$_baseUrl/search-sale').replace(
        queryParameters: {'query': query.trim()},
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      final decoded = json.decode(response.body);

      if (response.statusCode == 200 && decoded['success'] == true) {
        return {
          'success': true,
          'sale': decoded['sale'],
          'policy_info': decoded['policy_info'],
          'items': decoded['items'],
          'has_returnable': decoded['has_returnable'],
        };
      } else {
        return {
          'success': false,
          'message': decoded['message'] ?? 'Nota transaksi tidak ditemukan.',
        };
      }
    } catch (e) {
      debugPrint('ReturnService searchSale error: $e');
      return {
        'success': false,
        'message': 'Gagal mencari transaksi: $e',
      };
    }
  }

  /// Memproses penyimpanan data retur kasir
  Future<Map<String, dynamic>> createReturn({
    required int saleId,
    required String reason,
    required String actionType,
    String? note,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final uri = Uri.parse(_baseUrl);
      final cashierId = AuthService().currentUser?.id ?? 1;

      final body = {
        'sale_id': saleId,
        'cashier_id': cashierId,
        'reason': reason,
        'action_type': actionType,
        'note': note,
        'items': items,
      };

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(body),
      ).timeout(const Duration(seconds: 15));

      final decoded = json.decode(response.body);

      if (response.statusCode == 200 && decoded['success'] == true) {
        return {
          'success': true,
          'message': decoded['message'] ?? 'Retur berhasil diproses.',
          'data': decoded['data'],
          'points_deducted': decoded['points_deducted'] ?? 0,
        };
      } else {
        return {
          'success': false,
          'message': decoded['message'] ?? 'Gagal memproses retur transaksi.',
        };
      }
    } catch (e) {
      debugPrint('ReturnService createReturn error: $e');
      return {
        'success': false,
        'message': 'Gagal terhubung ke server: $e',
      };
    }
  }

  /// Mengambil detail retur berdasarkan ID
  Future<SaleReturnModel?> getReturnDetail(int id) async {
    try {
      final uri = Uri.parse('$_baseUrl/$id');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded['success'] == true && decoded['data'] != null) {
          return SaleReturnModel.fromJson(decoded['data'] as Map<String, dynamic>);
        }
      }
      return null;
    } catch (e) {
      debugPrint('ReturnService getReturnDetail error: $e');
      return null;
    }
  }
}

